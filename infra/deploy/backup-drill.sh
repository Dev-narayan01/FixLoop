#!/usr/bin/env bash
#
# Backup and restore drill.
#
# Dumps the hosted database, restores the dump into a throwaway PostgreSQL
# container, and compares row counts table by table. If the counts match, the
# backup is real and restorable; if they do not, the backup is a hope.
#
#   bash infra/deploy/backup-drill.sh
#
# It reads .env for DATABASE_URL, DATABASE_USER, DATABASE_PASSWORD and
# SUPABASE_CA_CERT_PATH. It writes only to ./backups and to a container that is
# removed afterwards. Nothing is written to the hosted database.
#
# Record the result in infra/deploy/RUNBOOK.md (section "Backups and monitoring"):
# date, dump size, table count, whether the counts matched.

set -euo pipefail

cd "$(dirname "$0")/../.."

POSTGRES_IMAGE="${POSTGRES_IMAGE:-postgres:16}"
CONTAINER="fixloop-restore-drill"
BACKUP_DIR="backups"

info() { printf '\n== %s\n' "$1"; }
pass() { printf '  ok      %s\n' "$1"; }
step() { printf '  ...     %s\n' "$1"; }
warn() { printf '  warn    %s\n' "$1"; }
die() { printf '  FAILED  %s\n' "$1"; exit 1; }

cleanup() {
    docker rm -f "$CONTAINER" > /dev/null 2>&1 || true
}
trap cleanup EXIT

info "Configuration"

if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
    pass "Read .env"
else
    warn "No .env in this directory; using environment variables as they are"
fi

for name in DATABASE_URL DATABASE_USER DATABASE_PASSWORD SUPABASE_CA_CERT_PATH; do
    if [ -z "$(eval "printf '%s' \"\${$name:-}\"")" ]; then
        die "$name is not set in .env"
    fi
done
[ -f "$SUPABASE_CA_CERT_PATH" ] || die "CA certificate not found: $SUPABASE_CA_CERT_PATH"
command -v docker > /dev/null 2>&1 || die "docker is not available"
pass "Credentials and CA certificate present"
pass "docker is available"

rest="${DATABASE_URL#jdbc:postgresql://}"
host_port="${rest%%/*}"
database_name="${rest#*/}"
database_host="${host_port%%:*}"
database_port="${host_port##*:}"
[ "$database_port" = "$database_host" ] && database_port=5432
cert_path="$(realpath "$SUPABASE_CA_CERT_PATH")"

conninfo="host=$database_host port=$database_port user=$DATABASE_USER dbname=$database_name"
conninfo="$conninfo sslmode=verify-full sslrootcert=/certs/ca.crt"

mkdir -p "$BACKUP_DIR"
dump_file="$BACKUP_DIR/fixloop-$(date +%Y%m%d-%H%M%S).dump"

info "Dump the hosted database"

step "pg_dump → $dump_file"
if ! docker run --rm \
        -v "$cert_path:/certs/ca.crt:ro" \
        -e PGPASSWORD="$DATABASE_PASSWORD" \
        "$POSTGRES_IMAGE" pg_dump "$conninfo" --format=custom --no-owner --no-privileges \
        > "$dump_file"; then
    die "pg_dump failed; the reason is above and no backup was written"
fi

dump_bytes=$(wc -c < "$dump_file")
[ "$dump_bytes" -gt 1000 ] || die "The dump is only $dump_bytes bytes; treat it as failed"
pass "Dump written: $(du -h "$dump_file" | cut -f1) ($dump_bytes bytes)"

info "Restore into a throwaway PostgreSQL"

step "starting $CONTAINER"
docker rm -f "$CONTAINER" > /dev/null 2>&1 || true
docker run -d --name "$CONTAINER" \
    -e POSTGRES_PASSWORD=drill-password \
    -e POSTGRES_DB=drill \
    "$POSTGRES_IMAGE" > /dev/null

ready=0
for _ in $(seq 1 60); do
    if docker exec "$CONTAINER" pg_isready -U postgres -d drill > /dev/null 2>&1; then
        ready=1
        break
    fi
    sleep 1
done
[ "$ready" -eq 1 ] || die "The restore target did not become ready in 60 seconds"
pass "Restore target is accepting connections"

step "pg_restore"
if ! docker exec -i "$CONTAINER" pg_restore -U postgres -d drill --no-owner --no-privileges \
        < "$dump_file" > /dev/null; then
    die "pg_restore reported an error; the dump is not restorable as it stands"
fi
pass "Restore finished without errors"

info "Compare the two databases"

target_psql() {
    docker exec -i "$CONTAINER" psql -U postgres -d drill -X -tA -F'|' -v ON_ERROR_STOP=1 "$@"
}

hosted_psql() {
    docker run --rm -i \
        -v "$cert_path:/certs/ca.crt:ro" \
        -e PGPASSWORD="$DATABASE_PASSWORD" \
        "$POSTGRES_IMAGE" psql "$conninfo" -X -tA -F'|' -v ON_ERROR_STOP=1 "$@"
}

tables=$(target_psql -c "select relname from pg_class
    where relkind = 'r' and relnamespace = 'public'::regnamespace order by 1")
[ -n "$tables" ] || die "No tables were restored; the dump is not usable"

count_sql=""
while IFS= read -r table; do
    [ -z "$table" ] && continue
    [ -n "$count_sql" ] && count_sql="$count_sql union all "
    count_sql="$count_sql select '$table' as t, count(*) as n from public.\"$table\""
done <<< "$tables"
count_sql="$count_sql order by 1"

hosted_counts="$(hosted_psql -c "$count_sql")" || die "Could not read row counts from the hosted database"
restored_counts="$(target_psql -c "$count_sql")" || die "Could not read row counts from the restored copy"

if [ "$hosted_counts" = "$restored_counts" ]; then
    table_count=$(printf '%s\n' "$tables" | grep -c . || true)
    total_rows=$(printf '%s\n' "$restored_counts" | awk -F'|' '{s+=$2} END {print s+0}')
    pass "Row counts match in all $table_count tables ($total_rows rows)"
    printf '\n%s\n' "$restored_counts" | sed 's/^/          /'
    printf '\nRestore drill passed. Record it in infra/deploy/RUNBOOK.md:\n'
    printf '  date, dump %s, %s tables, %s rows, counts matched\n' \
        "$(basename "$dump_file")" "$table_count" "$total_rows"
    exit 0
fi

printf '  FAILED  Row counts differ\n'
printf '          hosted        restored\n'
diff <(printf '%s\n' "$hosted_counts") <(printf '%s\n' "$restored_counts") \
    | sed 's/^/          /' || true
printf '\nThe dump does not reproduce the database. Keep the file for inspection and\n'
printf 'report this before relying on any backup.\n'
exit 1
