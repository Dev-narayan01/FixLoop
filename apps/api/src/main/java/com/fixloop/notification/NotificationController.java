package com.fixloop.notification;

import java.time.Duration;
import java.util.UUID;

import com.fixloop.common.ApiException;
import com.fixloop.common.RequestRateLimiter;
import com.fixloop.config.AuthProperties;
import com.fixloop.notification.dto.MarkAllReadResponse;
import com.fixloop.notification.dto.NotificationInbox;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * The caller's own in-app notifications.
 *
 * <p>Every endpoint is scoped to the signed-in account: there is no way to ask for
 * another user's notification, and no staff view of someone else's inbox. The
 * notification is a private message to one person, so the API treats it that way.
 */
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {
    /** A client polls this on foreground; the limit allows that without allowing abuse. */
    private static final int READ_LIMIT = 120;
    private static final Duration READ_WINDOW = Duration.ofMinutes(5);

    private final NotificationService notifications;
    private final RequestRateLimiter rateLimiter;
    private final AuthProperties properties;

    public NotificationController(NotificationService notifications, RequestRateLimiter rateLimiter,
                                  AuthProperties properties) {
        this.notifications = notifications;
        this.rateLimiter = rateLimiter;
        this.properties = properties;
    }

    @GetMapping
    public NotificationInbox inbox(@AuthenticationPrincipal Jwt jwt,
                                   @RequestParam(name = "unreadOnly", defaultValue = "false") boolean unreadOnly,
                                   @RequestParam(name = "limit", defaultValue = "50") int limit) {
        UUID userId = toUserId(jwt);
        limit(userId);
        return notifications.inbox(userId, unreadOnly, limit);
    }

    @PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markRead(@AuthenticationPrincipal Jwt jwt, @PathVariable("id") UUID id) {
        UUID userId = toUserId(jwt);
        limit(userId);
        notifications.markRead(userId, id);
    }

    @PostMapping("/read-all")
    public MarkAllReadResponse markAllRead(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = toUserId(jwt);
        limit(userId);
        return new MarkAllReadResponse(notifications.markAllRead(userId));
    }

    private void limit(UUID userId) {
        if (properties.rateLimitEnabled()) {
            rateLimiter.check("notifications:" + userId, READ_LIMIT, READ_WINDOW);
        }
    }

    private static UUID toUserId(Jwt jwt) {
        try {
            return UUID.fromString(jwt.getSubject());
        } catch (IllegalArgumentException | NullPointerException exception) {
            // A token we signed cannot have a non-UUID subject; if one does, the
            // signing key is not ours and the request is not authenticated.
            throw ApiException.unauthenticated("Authentication is required.");
        }
    }
}
