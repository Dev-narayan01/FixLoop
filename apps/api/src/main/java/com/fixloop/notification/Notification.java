package com.fixloop.notification;

import java.time.Instant;
import java.util.UUID;

/**
 * One row of the notification outbox.
 *
 * <p>{@code payload} stays raw JSON text here: it is written by whichever module
 * raises the notification, our side of the boundary does not interpret it, and
 * parsing it in the repository would only add a failure mode. The service turns
 * it into a JSON tree for the API response.
 *
 * <p>{@code channel} and {@code status} are strings rather than enums so that a
 * value added in the database does not stop the application from starting. The
 * allowed values are still enforced, by a check constraint in the schema and by
 * validation in {@link NotificationService}.
 */
public record Notification(
    UUID id,
    UUID userId,
    String channel,
    String type,
    String payload,
    String status,
    Instant createdAt,
    Instant sentAt,
    Instant readAt) {
}
