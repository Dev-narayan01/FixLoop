package com.fixloop.notification.dto;

import java.time.Instant;
import java.util.UUID;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * One notification as the client sees it.
 *
 * <p>The payload is a JSON object rather than a string so the Flutter client can
 * read a field without parsing JSON inside JSON. {@code readAt} is null while the
 * notification is unread, which is what the badge counts.
 */
public record NotificationResponse(
    UUID id,
    String type,
    JsonNode payload,
    String status,
    Instant createdAt,
    Instant readAt) {
}
