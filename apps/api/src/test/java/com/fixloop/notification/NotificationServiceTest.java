package com.fixloop.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fixloop.common.ApiException;
import com.fixloop.notification.dto.NotificationInbox;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class NotificationServiceTest {
    private static final UUID USER = UUID.randomUUID();

    private final NotificationRepository repository = mock(NotificationRepository.class);
    private final NotificationService service = new NotificationService(repository, new ObjectMapper());

    @Test
    void writesAnInAppNotificationAsSentWithItsPayloadAsJson() {
        UUID id = UUID.randomUUID();
        when(repository.insert(eq(USER), eq("IN_APP"), eq("COMPLAINT_RESOLVED"), eq("{\"code\":\"FIX-1042\"}")))
            .thenReturn(id);

        UUID written = service.notifyInApp(USER, "COMPLAINT_RESOLVED", Map.of("code", "FIX-1042"));

        assertThat(written).isEqualTo(id);
        verify(repository).insert(USER, "IN_APP", "COMPLAINT_RESOLVED", "{\"code\":\"FIX-1042\"}");
    }

    @Test
    void storesAnEmptyPayloadAsAnEmptyObjectRatherThanNull() {
        when(repository.insert(any(), any(), any(), any())).thenReturn(UUID.randomUUID());

        service.notifyInApp(USER, "WELCOME", null);

        verify(repository).insert(USER, "IN_APP", "WELCOME", "{}");
    }

    @Test
    void refusesAnUnknownChannel() {
        assertThatThrownBy(() -> service.enqueue(USER, "CARRIER_PIGEON", "WELCOME", Map.of()))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("channel");
    }

    @Test
    void refusesAnEmptyType() {
        assertThatThrownBy(() -> service.notifyInApp(USER, "  ", Map.of()))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("type");
    }

    @Test
    void refusesAPayloadLargerThanTheRowIsMeantToHold() {
        String huge = "x".repeat(5000);

        assertThatThrownBy(() -> service.notifyInApp(USER, "WELCOME", Map.of("body", huge)))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("too large");
    }

    @Test
    void capsThePageSizeAndReportsTheWholeUnreadCount() {
        Notification stored = new Notification(UUID.randomUUID(), USER, "IN_APP", "COMPLAINT_RESOLVED",
            "{\"code\":\"FIX-1042\"}", "SENT", Instant.parse("2026-11-05T10:00:00Z"), null, null);
        when(repository.findInApp(eq(USER), eq(false), anyInt())).thenReturn(List.of(stored));
        when(repository.countUnread(USER)).thenReturn(7);

        NotificationInbox inbox = service.inbox(USER, false, 500);

        assertThat(inbox.items()).hasSize(1);
        assertThat(inbox.items().get(0).payload().get("code").asText()).isEqualTo("FIX-1042");
        assertThat(inbox.unreadCount()).isEqualTo(7);
        // A caller cannot ask for the whole table; the page is capped.
        verify(repository).findInApp(USER, false, 100);
    }

    @Test
    void treatsAnUnreadableStoredPayloadAsEmptyInsteadOfFailingTheInbox() {
        Notification broken = new Notification(UUID.randomUUID(), USER, "IN_APP", "WELCOME",
            "not json at all", "SENT", Instant.now(), null, null);
        when(repository.findInApp(any(), anyBoolean(), anyInt())).thenReturn(List.of(broken));

        NotificationInbox inbox = service.inbox(USER, true, 10);

        assertThat(inbox.items().get(0).payload().isObject()).isTrue();
        assertThat(inbox.items().get(0).payload().isEmpty()).isTrue();
    }

    @Test
    void markingReadTwiceIsNotAnError() {
        UUID id = UUID.randomUUID();
        when(repository.markRead(id, USER)).thenReturn(0);
        when(repository.existsForUser(id, USER)).thenReturn(true);

        service.markRead(USER, id);
    }

    @Test
    void anotherAccountsNotificationIsNotFoundRatherThanForbidden() {
        UUID id = UUID.randomUUID();
        when(repository.markRead(id, USER)).thenReturn(0);
        when(repository.existsForUser(id, USER)).thenReturn(false);

        assertThatThrownBy(() -> service.markRead(USER, id))
            .isInstanceOf(ApiException.class)
            .satisfies(exception -> assertThat(((ApiException) exception).status())
                .isEqualTo(HttpStatus.NOT_FOUND));
    }
}
