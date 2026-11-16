package com.fixloop.notification;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

/**
 * SQL for the notification outbox. Every statement is scoped by {@code user_id}:
 * a notification belongs to exactly one account, and no caller may read or write
 * another account's rows, so the scoping lives in the SQL rather than in a check
 * someone could forget.
 */
@Repository
public class NotificationRepository {
    private static final String COLUMNS =
        "id, user_id, channel, type, payload::text, status, created_at, sent_at, read_at";

    private static final RowMapper<Notification> MAPPER = NotificationRepository::map;

    private final JdbcTemplate jdbc;

    public NotificationRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Inserts one notification. An in-app notification is delivered the moment it
     * is written — the user can read it straight away — so it is stored as SENT.
     * Email and push have no transport yet; they stay PENDING for a future worker,
     * which is what {@code attempts} and {@code next_attempt_at} exist for.
     */
    public UUID insert(UUID userId, String channel, String type, String payload) {
        String status = NotificationService.CHANNEL_IN_APP.equals(channel)
            ? NotificationService.STATUS_SENT
            : NotificationService.STATUS_PENDING;
        String sql = "INSERT INTO notifications_outbox (user_id, channel, type, payload, status, sent_at)"
            + " VALUES (?, ?, ?, ?::jsonb, ?, CASE WHEN ? = 'SENT' THEN now() ELSE NULL END)"
            + " RETURNING id";
        return jdbc.queryForObject(sql, UUID.class, userId, channel, type, payload, status, status);
    }

    public List<Notification> findInApp(UUID userId, boolean unreadOnly, int limit) {
        String sql = "SELECT " + COLUMNS + " FROM notifications_outbox"
            + " WHERE user_id = ? AND channel = 'IN_APP'"
            + (unreadOnly ? " AND read_at IS NULL" : "")
            + " ORDER BY created_at DESC LIMIT ?";
        return jdbc.query(sql, MAPPER, userId, limit);
    }

    public int countUnread(UUID userId) {
        Integer count = jdbc.queryForObject(
            "SELECT count(*) FROM notifications_outbox"
                + " WHERE user_id = ? AND channel = 'IN_APP' AND read_at IS NULL",
            Integer.class, userId);
        return count == null ? 0 : count;
    }

    /** Returns the number of rows changed: 0 means it was already read, or not theirs. */
    public int markRead(UUID notificationId, UUID userId) {
        return jdbc.update(
            "UPDATE notifications_outbox SET read_at = now()"
                + " WHERE id = ? AND user_id = ? AND channel = 'IN_APP' AND read_at IS NULL",
            notificationId, userId);
    }

    public int markAllRead(UUID userId) {
        return jdbc.update(
            "UPDATE notifications_outbox SET read_at = now()"
                + " WHERE user_id = ? AND channel = 'IN_APP' AND read_at IS NULL",
            userId);
    }

    public boolean existsForUser(UUID notificationId, UUID userId) {
        Integer count = jdbc.queryForObject(
            "SELECT count(*) FROM notifications_outbox WHERE id = ? AND user_id = ?",
            Integer.class, notificationId, userId);
        return count != null && count > 0;
    }

    private static Notification map(ResultSet row, int index) throws SQLException {
        return new Notification(
            row.getObject("id", UUID.class),
            row.getObject("user_id", UUID.class),
            row.getString("channel"),
            row.getString("type"),
            row.getString("payload"),
            row.getString("status"),
            toInstant(row.getTimestamp("created_at")),
            toInstant(row.getTimestamp("sent_at")),
            toInstant(row.getTimestamp("read_at")));
    }

    private static Instant toInstant(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant();
    }
}
