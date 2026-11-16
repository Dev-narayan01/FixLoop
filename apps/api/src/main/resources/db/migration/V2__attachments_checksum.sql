-- The upload endpoint computes a SHA-256 checksum for every photograph, but the
-- original schema had nowhere to keep it. The checksum is what lets a later
-- integrity check notice a file that was replaced or truncated on disk, and it
-- is how the storage key is sharded, so it belongs in the row.
--
-- Forward-only: V1 is applied on the hosted database and is never edited.
-- Nullable on purpose. Existing rows (if any) predate the column, and a NOT NULL
-- constraint would have to guess a value for them. The complaint endpoint, when
-- it is written, inserts the checksum it received from the upload endpoint.

ALTER TABLE attachments ADD COLUMN checksum_sha256 text;

COMMENT ON COLUMN attachments.checksum_sha256 IS
  'Lowercase hex SHA-256 of the stored bytes, as returned by POST /api/v1/attachments.';
