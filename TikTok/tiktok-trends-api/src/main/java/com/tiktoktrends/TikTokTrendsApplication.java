package com.tiktoktrends;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling   // activates @Scheduled CRON jobs
@EnableCaching      // activates @Cacheable / Redis
public class TikTokTrendsApplication {

    public static void main(String[] args) {
        SpringApplication.run(TikTokTrendsApplication.class, args);
    }
}
