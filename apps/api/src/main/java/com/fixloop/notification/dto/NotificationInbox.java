package com.fixloop.notification.dto;

import java.util.List;

/**
 * A page of the caller's inbox. {@code unreadCount} counts every unread in-app
 * notification, not just the ones on this page, because that is the number the tab
 * badge shows.
 */
public record NotificationInbox(List<NotificationResponse> items, int unreadCount) {
}
