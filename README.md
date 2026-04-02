# TikTok Trends Dashboard

A full-stack app I built to help TikTok creators stop guessing what to post. It pulls live trend data from TikTok, compares your account stats against platform benchmarks, and uses Claude (Anthropic's AI) to suggest actual video ideas based on what's trending right now.

![Landing Page](TikTok/docs/screenshots/landing.png)

---

## What it does

**Trending Now** — shows what's gaining traction on TikTok right now, broken into hashtags, music, and content categories. Each trend has a velocity score that measures week-over-week growth, so you can see not just what's popular but what's *accelerating*. No login needed to browse this.

![Trends Dashboard](TikTok/docs/screenshots/trends.png)

**AI Video Concepts** — hit Generate and it takes the top trending hashtags, combines them with your niche, and sends it to Claude to generate a full video idea: title, what to film, which sound to use, and which hashtags to put in the caption.

![AI Recommendations](TikTok/docs/screenshots/recommendations.png)

**Performance Analytics** — connects to your TikTok account and tracks your engagement rate, view velocity, follower growth, watch time, and share rate over the past 6 months. Plots them on a chart against platform averages so you can actually see how you're doing, and grades each metric A–F.

![Performance Analytics](TikTok/docs/screenshots/analytics.png)

You sign in with your TikTok account (OAuth) so your real data gets pulled on login. There's also a demo mode if you just want to click around without connecting an account.

---

## Quick start

Make sure PostgreSQL and Redis are running, then:

```bash
# 1. Create the database
psql -U postgres -c "CREATE DATABASE tiktok_trends;"

# 2. Set your secrets
export DB_PASSWORD=...
export JWT_SECRET=...
export ANTHROPIC_API_KEY=...
export TIKTOK_CLIENT_KEY=...
export TIKTOK_CLIENT_SECRET=...

# 3. Start the backend (runs Flyway migrations automatically)
cd tiktok-trends-api
mvn spring-boot:run

# 4. In a new terminal, start the frontend
cd tiktok-trends-ui
npm install && npm run dev
```

Open `http://localhost:3000` — click **Try Demo** to explore without a TikTok account, or **Sign in with TikTok** if you have a developer app configured.

The backend API runs at `http://localhost:8080`. Swagger docs are at `http://localhost:8080/swagger-ui.html`.

---

## Tech stack

| | |
|---|---|
| Frontend | React 18 + Vite + Tailwind CSS |
| Backend | Java 21 + Spring Boot 3.2 |
| Database | PostgreSQL + Flyway |
| Cache | Redis |
| AI | Claude API (`claude-sonnet-4-20250514`) |
| Auth | TikTok OAuth 2.0 + JWT |
| Data | TikTok Research API |

---

## How it's structured

```
React (localhost:3000)
        │
        ▼
Spring Boot API (localhost:8080)
        │
   ┌────┴──────────────────────┐
   │                           │
Ingestion Scheduler       Recommendation Engine
(runs every 2h)           (on demand)
   │                           │
TikTok Research API       Claude API
   │                           │
PostgreSQL ◄───────────────────┘
   │
Redis Cache
```

A background job runs every 2 hours, fetches recent videos from the TikTok Research API, aggregates them into trend records, and computes platform-wide KPI benchmarks. For each connected user, it also refreshes their account stats and auto-grades them against the latest benchmarks. Trend queries are cached in Redis for 1 hour.

---

## Running locally

**Prerequisites:** Java 21, Maven, PostgreSQL, Redis, Node 18+, Anthropic API key

**1. Create the database**
```bash
psql -U postgres -c "CREATE DATABASE tiktok_trends;"
```

**2. Set env variables**
```bash
export DB_PASSWORD=...
export JWT_SECRET=...          # min 32 chars
export ANTHROPIC_API_KEY=...
export TIKTOK_CLIENT_KEY=...
export TIKTOK_CLIENT_SECRET=...
```

**3. Start the backend**
```bash
cd tiktok-trends-api
mvn spring-boot:run
# http://localhost:8080
# Swagger: http://localhost:8080/swagger-ui.html
```

**4. Start the frontend**
```bash
cd tiktok-trends-ui
npm install
npm run dev
# http://localhost:3000
```

If you don't have a TikTok developer app set up, just use demo mode — it works without any TikTok credentials.

**Setting up TikTok OAuth (optional)**
1. Register at [developers.tiktok.com](https://developers.tiktok.com)
2. Enable Login Kit, request scopes: `user.info.basic`, `user.info.profile`, `user.info.stats`, `video.list`
3. Add redirect URI: `http://localhost:3000/auth/callback`
4. Paste `client_key` and `client_secret` into your env vars

---

## API endpoints

| Method | Endpoint | Auth | |
|--------|----------|------|-|
| GET | `/api/v1/auth/tiktok/authorize` | — | TikTok OAuth URL |
| POST | `/api/v1/auth/tiktok/callback` | — | Exchange code → JWT |
| POST | `/api/v1/auth/demo` | — | Demo login |
| GET | `/api/v1/trends/hashtags` | — | Hashtag trends |
| GET | `/api/v1/trends/music` | — | Music trends |
| GET | `/api/v1/trends/categories` | — | Category trends |
| POST | `/api/v1/recommendations` | JWT | Generate video concept |
| GET | `/api/v1/recommendations` | JWT | Past recommendations |
| GET | `/api/v1/analytics/performance` | JWT | KPI history + grades |

---

## DB schema

| Table | What's in it |
|-------|-------------|
| `users` | Accounts + TikTok OAuth tokens |
| `videos` | Videos pulled from TikTok Research API |
| `trends` | Aggregated hashtag / music / category trend signals |
| `recommendations` | AI-generated video concepts per user |
| `user_performance_snapshots` | Weekly KPI snapshots |
| `trend_benchmarks` | Platform-wide weekly averages |
| `user_kpi_grades` | A–F grades per snapshot |

---

## Build status

| Phase | | Status |
|-------|--|--------|
| 1 | DB schema + Spring Boot + JWT auth | ✅ |
| 2 | TikTok Research API ingestion + CRON | ✅ |
| 3 | Trend engine + Redis caching | ✅ |
| 4 | AI recommendations via Claude | ✅ |
| 5 | React frontend | ✅ |
| 6 | Swagger docs + demo mode + tests | ✅ |
