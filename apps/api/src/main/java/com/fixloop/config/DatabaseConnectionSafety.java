package com.fixloop.config;

import java.net.URI;

import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;

/**
 * Fail before opening a database connection if unsafe settings were copied from
 * a connection string. The disposable integration-test profile is test-only.
 */
@Configuration(proxyBeanMethods = false)
@Profile("!integration-test")
public class DatabaseConnectionSafety {
    @Bean
    static BeanFactoryPostProcessor validateDatabaseSettings(Environment environment) {
        return factory -> validate(
            environment.getProperty("spring.datasource.url"),
            environment.getProperty("spring.datasource.hikari.data-source-properties.sslmode"),
            environment.getProperty("spring.flyway.enabled", Boolean.class, false));
    }

    static void validate(String url, String sslMode, boolean flywayEnabled) {
        if (url == null || !url.startsWith("jdbc:postgresql://")) {
            throw new IllegalStateException("DATABASE_URL must be a PostgreSQL JDBC URL.");
        }
        try {
            URI uri = URI.create(url.substring("jdbc:".length()));
            if (uri.getHost() == null || uri.getRawUserInfo() != null || uri.getRawQuery() != null
                    || uri.getRawFragment() != null || uri.getPath() == null || uri.getPath().length() < 2) {
                throw new IllegalArgumentException("Unsupported JDBC URL format");
            }
        } catch (IllegalArgumentException exception) {
            // Never include the provided URL in an error; it may contain a secret.
            throw new IllegalStateException("DATABASE_URL must contain only the host, port and database. "
                + "Set the username, password and TLS certificate separately.");
        }
        if (!"verify-full".equals(sslMode)) {
            throw new IllegalStateException("Database TLS must use sslmode=verify-full.");
        }
        if (flywayEnabled) {
            throw new IllegalStateException("Automatic Flyway migrations are disabled for the hosted database. "
                + "Review a migration plan before changing this safeguard.");
        }
    }
}
