package com.fixloop.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class DatabaseConnectionSafetyTest {
    @Test
    void permitsDirectAndSessionPoolerHostOnlyUrls() {
        assertThatCode(() -> DatabaseConnectionSafety.validate(
            "jdbc:postgresql://db.example.supabase.co:5432/postgres", "verify-full", false))
            .doesNotThrowAnyException();
        assertThatCode(() -> DatabaseConnectionSafety.validate(
            "jdbc:postgresql://aws-example.pooler.supabase.com:5432/postgres", "verify-full", false))
            .doesNotThrowAnyException();
    }

    @Test
    void rejectsUrlCredentialsAndParametersWithoutEchoingThem() {
        for (String url : new String[] {
            "jdbc:postgresql://user:secret@db.example.supabase.co:5432/postgres",
            "jdbc:postgresql://db.example.supabase.co:5432/postgres?password=secret",
            "jdbc:postgresql://db.example.supabase.co:5432/postgres?sslmode=disable"
        }) {
            assertThatThrownBy(() -> DatabaseConnectionSafety.validate(url, "verify-full", false))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("host, port and database")
                .hasMessageNotContaining("secret");
        }
    }

    @Test
    void rejectsUnverifiedTlsAndAutomaticFlyway() {
        String url = "jdbc:postgresql://db.example.supabase.co:5432/postgres";
        assertThatThrownBy(() -> DatabaseConnectionSafety.validate(url, "require", false))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("verify-full");
        assertThatThrownBy(() -> DatabaseConnectionSafety.validate(url, "verify-full", true))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Flyway");
        assertThatThrownBy(() -> DatabaseConnectionSafety.validate("jdbc:mysql://localhost/db", "verify-full", false))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("PostgreSQL");
    }
}
