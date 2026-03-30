# TikTok Trends Dashboard — Claude Context

## Project Overview

A full-stack application that analyzes real-time TikTok trends and generates AI-powered video recommendations for content creators (TikTok influencers).

**Portfolio project** · Status: Backend mostly complete, frontend not started.

| Layer | Technology |
|-------|-----------|
| Frontend | React + Vite + Tailwind CSS (not started) |
| Backend | Java 21 + Spring Boot 3.2.3 |
| Database | PostgreSQL + Flyway migrations |
| Cache | Redis (1-hour TTL) |
| AI | Claude API (`claude-sonnet-4-20250514`) |
| Auth | JWT + Spring Security |
| Data Source | TikTok Research API |
| Build | Maven |

**Design theme:** Light pink — primary `#FFB6C1`, background `#FFF0F3`, accent `#E91E8C`

---

## Architecture

```
React Dashboard (localhost:3000)
        │
        ▼
Spring Boot API (localhost:8080)
        │
   ┌────┴─────────────────────┐
   │                          │
Ingestion Service         Recommendation Engine
(CRON every 2h)           (on user request)
   │                          │
TikTok Research API       Claude API
   │                          │
PostgreSQL ◄──────────────────┘
   │
Redis Cache (hot trend data)
```

**Key Components:**
- **IngestionScheduler** — polls TikTok Research API every 2 hours, normalizes/deduplicates, persists to DB
- **TrendService** — aggregates trends by velocity/engagement, Redis-cached
- **RecommendationService** — scores trends → calls Claude API → returns video concept (title, description, music, hashtags)
- **PerformanceAnalyticsService** — compares user KPIs vs platform benchmarks, grades A–F

---

## Build Status

| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | Foundation (DB schema, Spring Boot, JWT auth) | ✅ Done |
| Phase 2 | Data Ingestion (TikTok API client + CRON) | ⚠️ In Progress |
| Phase 3 | Trend Engine (SQL aggregation + Redis cache) | ✅ Done |
| Phase 4 | AI Recommendations (Claude API) | ✅ Done |
| Phase 5 | Frontend (React dashboard) | ❌ Not Started |
| Phase 6 | Polish (tests, docs, error handling) | ❌ Not Started |

---

## Todo List

### Phase 2 — Data Ingestion (in progress)
- [ ] Implement TikTok Research API OAuth2 client credentials flow in `IngestionScheduler.java`
- [ ] Replace stub HTTP calls with real `WebClient` calls to `POST /v2/research/video/query/`
- [ ] Implement `GET /v2/research/user/info/` for per-user stats snapshots
- [ ] Add deduplication logic before persisting video records
- [ ] Add retry/backoff for TikTok API rate limits

### Phase 5 — Frontend (not started)
- [ ] Install Figma MCP for free tier: `npx @arinspunk/claude-talk-to-figma-mcp` and configure in `.claude/settings.json`
- [ ] Set up Figma design system with light pink theme (`#FFB6C1` primary, `#FFF0F3` background, `#E91E8C` accent)
- [ ] Scaffold React app with Vite + Tailwind CSS at `/tiktok-trends-ui/`
- [ ] Configure Tailwind custom pink palette in `tailwind.config.js`
- [ ] Implement JWT auth flow (login + register pages)
- [ ] Build Trends dashboard (hashtag, music, content category tabs)
- [ ] Build engagement velocity charts (Recharts or Chart.js)
- [ ] Build AI Recommendations display panel
- [ ] Build Performance Analytics / KPI grades view
- [ ] Wire all pages to Spring Boot REST API (`localhost:8080`)

### Phase 6 — Polish (not started)
- [ ] Write unit tests for `TrendService`, `PerformanceAnalyticsService`, `RecommendationService`
- [ ] Write integration tests with Testcontainers (PostgreSQL + Redis)
- [ ] Add Swagger/OpenAPI docs via `springdoc-openapi`
- [ ] Write README.md with local setup instructions
- [ ] Move secrets out of `application.properties` → environment variables / `.env`
- [ ] Add structured logging (SLF4J)
- [ ] Add `POST /api/v1/ingest/trigger` admin endpoint

---

## Key Files

| File | Purpose |
|------|---------|
| `tiktok-trends-api/src/main/java/com/tiktoktrends/scheduler/IngestionScheduler.java` | CRON job — TikTok API calls stubbed here (Phase 2 work) |
| `tiktok-trends-api/src/main/java/com/tiktoktrends/service/impl/RecommendationService.java` | Claude API integration |
| `tiktok-trends-api/src/main/java/com/tiktoktrends/service/impl/TrendService.java` | Redis-cached trend queries |
| `tiktok-trends-api/src/main/java/com/tiktoktrends/service/impl/PerformanceAnalyticsService.java` | KPI grading logic |
| `tiktok-trends-api/src/main/resources/application.properties` | All config + API key placeholders |
| `tiktok-trends-api/src/main/resources/db/migration/` | Flyway SQL migrations (V1 core schema, V2 analytics) |
| `Project Planning/TikTokTrends_TechnicalDesign.pdf` | Full architecture reference doc |

---

## Environment Setup

### Required local services
```bash
# PostgreSQL
psql -U postgres -c "CREATE DATABASE tiktok_trends;"

# Redis
redis-server
```

### Required environment variables (replace placeholders in application.properties)
```
TIKTOK_CLIENT_KEY=...
TIKTOK_CLIENT_SECRET=...
ANTHROPIC_API_KEY=...
DB_PASSWORD=...
JWT_SECRET=...   # Must be 256-bit minimum
```

### Run the backend
```bash
cd tiktok-trends-api
mvn spring-boot:run
# API available at http://localhost:8080
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new influencer account |
| POST | `/api/v1/auth/login` | Authenticate, returns JWT |
| GET | `/api/v1/trends` | List active trends sorted by velocity |
| GET | `/api/v1/trends/music` | Top trending music tracks |
| GET | `/api/v1/trends/hashtags` | Top hashtags by category |
| GET | `/api/v1/videos/trending` | Recent high-velocity video feed |
| POST | `/api/v1/recommendations` | Generate AI video concept (auth required) |
| GET | `/api/v1/recommendations/{id}` | Fetch a previous recommendation |
| POST | `/api/v1/ingest/trigger` | Admin: manually trigger ingestion |

---

## Figma MCP Setup (free tier)

For frontend development with Claude Code + Figma:
```bash
npx @arinspunk/claude-talk-to-figma-mcp
```
Add to `.claude/settings.json`:
```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["@arinspunk/claude-talk-to-figma-mcp"]
    }
  }
}
```
