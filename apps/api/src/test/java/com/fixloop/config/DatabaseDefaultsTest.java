package com.fixloop.config;

import java.io.IOException;

import org.junit.jupiter.api.Test;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.core.env.PropertySource;
import org.springframework.core.io.ClassPathResource;

import static org.assertj.core.api.Assertions.assertThat;

class DatabaseDefaultsTest {
    @Test
    void hostedConnectionDoesNotRunMigrationsAndVerifiesTls() throws IOException {
        PropertySource<?> defaults = new YamlPropertySourceLoader()
            .load("application", new ClassPathResource("application.yml")).getFirst();

        assertThat(defaults.getProperty("spring.flyway.enabled")).isEqualTo(false);
        assertThat(defaults.getProperty("spring.flyway.baseline-on-migrate")).isEqualTo(false);
        assertThat(defaults.getProperty("spring.flyway.clean-disabled")).isEqualTo(true);
        assertThat(defaults.getProperty("spring.datasource.hikari.data-source-properties.sslmode"))
            .isEqualTo("verify-full");
        assertThat(defaults.getProperty("spring.datasource.url")).isEqualTo("${DATABASE_URL}");
        assertThat(defaults.getProperty("spring.datasource.username")).isEqualTo("${DATABASE_USER}");
        assertThat(defaults.getProperty("spring.datasource.password")).isEqualTo("${DATABASE_PASSWORD}");
    }
}
