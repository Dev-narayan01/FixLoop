package com.fixloop.notification;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fixloop.common.ApiException;
import com.fixloop.notification.dto.NotificationInbox;
import com.fixloop.notification.dto.NotificationResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Raises notifications and serves one account's inbox.
 *
 * <p>Writing a notification is deliberately not a separate transaction. The
 * complaint and workflow code will call {@link #notifyInApp} inside its own
 * transaction, so that a complaint cannot be saved without its notification, and
 * a notification cannot survive a complaint that rolled back.
 *
 * <p>Only {@code IN_APP} is delivered today. There is no mail transport and no
 * push credentials, so email and push rows are written as PENDING and nothing
 * drains them yet; the schema already carries {@code attempts} and
 * {@code next_attempt_at} for the worker that will.
 */
@Service
public class NotificationService {
    public static final String CHANNEL_IN_APP = "IN_APP";
    public static final String CHANNEL_EMAIL = "EMAIL";
    public static final String CHANNEL_PUSH = "PUSH";
    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_SENT = "SENT";

    private static final Set<String> CHANNELS = Set.of(CHANNEL_IN_APP, CHANNEL_EMAIL, CHANNEL_PUSH);
    private static final int MAX_TYPE_LENGTH = 60;
    private static final int MAX_PAYLOAD_BYTES = 4096;
    private static final int DEFAULT_LIMIT = 50;
    private static final int MAX_LIMIT = 100;

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notifications;
    private final ObjectMapper objectMapper;

    public NotificationService(NotificationRepository notifications, ObjectMapper objectMapper) {
        this.notifications = notifications;
        this.objectMapper = objectMapper;
    }

    /** The call the complaint and workflow code is expected to make. */
    @Transactional
    public UUID notifyInApp(UUID userId, String type, Map<String, Object> payload) {
        return enqueue(userId, CHANNEL_IN_APP, type, payload);
    }

    @Transactional
    public UUID enqueue(UUID userId, String channel, String type, Map<String, Object> payload) {
        if (userId == null) {
            throw ApiException.badRequest("VALIDATION_FAILED", "A notification needs a recipient.");
        }
        if (channel == null || !CHANNELS.contains(channel)) {
            throw ApiException.badRequest("VALIDATION_FAILED", "Unknown notification channel.");
        }
        if (type == null || type.isBlank() || type.length() > MAX_TYPE_LENGTH) {
            throw ApiException.badRequest("VALIDATION_FAILED",
                "A notification type is required and must be at most " + MAX_TYPE_LENGTH + " characters.");
        }
        String json = serialise(payload);
        if (json.getBytes(StandardCharsets.UTF_8).length > MAX_PAYLOAD_BYTES) {
            // The payload is rendered to a user, not stored as a document. A body
            // that large is a mistake, and refusing it keeps a row small enough to
            // list a hundred of them without thinking about memory.
            throw ApiException.badRequest("VALIDATION_FAILED", "The notification payload is too large.");
        }
        return notifications.insert(userId, channel, type, json);
    }

    @Transactional(readOnly = true)
    public NotificationInbox inbox(UUID userId, boolean unreadOnly, int limit) {
        int bounded = limit < 1 ? DEFAULT_LIMIT : Math.min(limit, MAX_LIMIT);
        List<NotificationResponse> items = notifications.findInApp(userId, unreadOnly, bounded).stream()
            .map(this::toResponse)
            .toList();
        return new NotificationInbox(items, notifications.countUnread(userId));
    }

    /**
     * Marking read is idempotent: reading the same notification twice is not an
     * error, because a client that retried after a dropped response should not see
     * a failure. Someone else's id is a 404 rather than a 403, so the endpoint does
     * not confirm that a notification exists under another account.
     */
    @Transactional
    public void markRead(UUID userId, UUID notificationId) {
        if (notifications.markRead(notificationId, userId) > 0) {
            return;
        }
        if (notifications.existsForUser(notificationId, userId)) {
            return;
        }
        throw new ApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", "No such notification.");
    }

    @Transactional
    public int markAllRead(UUID userId) {
        return notifications.markAllRead(userId);
    }

    private NotificationResponse toResponse(Notification notification) {
        return new NotificationResponse(
            notification.id(),
            notification.type(),
            parse(notification.payload()),
            notification.status(),
            notification.createdAt(),
            notification.readAt());
    }

    private String serialise(Map<String, Object> payload) {
        if (payload == null || payload.isEmpty()) {
            return "{}";
        }
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException exception) {
            throw ApiException.badRequest("VALIDATION_FAILED",
                "The notification payload is not valid JSON.");
        }
    }

    private JsonNode parse(String payload) {
        try {
            return objectMapper.readTree(payload);
        } catch (JsonProcessingException exception) {
            // A row written by hand or by an older version should not break the
            // whole inbox, so one unreadable payload becomes an empty object.
            log.warn("Notification payload is not valid JSON; rendering it as empty");
            return objectMapper.createObjectNode();
        }
    }
}
