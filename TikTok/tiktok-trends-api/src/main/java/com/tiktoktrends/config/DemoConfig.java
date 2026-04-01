package com.tiktoktrends.config;

import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration;
import org.springframework.cache.CacheManager;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Duration;

/**
 * Demo profile config — provides stubs for Redis so the app
 * starts without a real Redis server. OAuth state storage won't work
 * but demo login bypasses OAuth entirely.
 */
@Configuration
@Profile("demo")
@EnableAutoConfiguration(exclude = {
        RedisAutoConfiguration.class,
        RedisRepositoriesAutoConfiguration.class
})
public class DemoConfig {

    @Bean
    @Primary
    public CacheManager demoCacheManager() {
        return new ConcurrentMapCacheManager();
    }

    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        // Lazy connection — won't actually connect unless Redis ops are called.
        // In demo mode, OAuth (which uses Redis) is bypassed via /auth/demo.
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration("localhost", 6379);
        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
                .commandTimeout(Duration.ofMillis(100))
                .build();
        LettuceConnectionFactory factory = new LettuceConnectionFactory(config, clientConfig);
        factory.setEagerInitialization(false);
        return factory;
    }

    @Bean
    public StringRedisTemplate stringRedisTemplate(RedisConnectionFactory factory) {
        return new StringRedisTemplate(factory);
    }
}
