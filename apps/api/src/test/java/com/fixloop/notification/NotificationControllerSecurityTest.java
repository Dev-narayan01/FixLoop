package com.fixloop.notification;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.UUID;

import com.fixloop.auth.AuthService;
import com.fixloop.common.RequestRateLimiter;
import com.fixloop.config.AuthConfiguration;
import com.fixloop.config.SecurityConfiguration;
import com.fixloop.notification.dto.NotificationInbox;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/** The inbox needs a signed-in account and is scoped to that account. */
@WebMvcTest(NotificationController.class)
@Import({SecurityConfiguration.class, AuthConfiguration.class})
class NotificationControllerSecurityTest {
    private static final String STUDENT_ID = "3f1a6c1e-1111-4a2b-9a10-0c2b7d5e4f60";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private NotificationService notifications;

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private RequestRateLimiter rateLimiter;

    @Test
    void refusesTheInboxWithoutAToken() throws Exception {
        mvc.perform(get("/api/v1/notifications"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.code").value("UNAUTHENTICATED"));

        verify(notifications, never()).inbox(any(), anyBoolean(), anyInt());
    }

    @Test
    void returnsOnlyTheCallersInbox() throws Exception {
        when(notifications.inbox(eq(UUID.fromString(STUDENT_ID)), anyBoolean(), anyInt()))
            .thenReturn(new NotificationInbox(List.of(), 3));

        mvc.perform(get("/api/v1/notifications?unreadOnly=true&limit=20")
                .with(jwt().jwt(token -> token.subject(STUDENT_ID))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.unreadCount").value(3))
            .andExpect(jsonPath("$.items").isArray());

        // The account comes from the token, never from a query parameter.
        verify(notifications).inbox(UUID.fromString(STUDENT_ID), true, 20);
    }

    @Test
    void marksOneNotificationRead() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(post("/api/v1/notifications/" + id + "/read")
                .with(jwt().jwt(token -> token.subject(STUDENT_ID))))
            .andExpect(status().isNoContent());

        verify(notifications).markRead(UUID.fromString(STUDENT_ID), id);
    }

    @Test
    void rejectsANotificationIdThatIsNotAUuid() throws Exception {
        mvc.perform(post("/api/v1/notifications/not-a-uuid/read")
                .with(jwt().jwt(token -> token.subject(STUDENT_ID))))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("MALFORMED_REQUEST"));
    }

    @Test
    void marksEverythingRead() throws Exception {
        when(notifications.markAllRead(UUID.fromString(STUDENT_ID))).thenReturn(4);

        mvc.perform(post("/api/v1/notifications/read-all")
                .with(jwt().jwt(token -> token.subject(STUDENT_ID))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.markedRead").value(4));
    }
}
