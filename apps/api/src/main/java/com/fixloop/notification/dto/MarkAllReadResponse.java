package com.fixloop.notification.dto;

/** How many notifications the "mark all read" call changed. Zero is a valid answer. */
public record MarkAllReadResponse(int markedRead) {
}
