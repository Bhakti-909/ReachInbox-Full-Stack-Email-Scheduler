# ReachInbox Full-Stack Email Scheduler

A full-stack email scheduling platform. Users sign in with Google, compose emails, schedule them for future delivery, and track sending status from a dashboard. A background worker processes jobs reliably, with search, Slack notifications, and per-sender rate limiting.

---

## Features

- Google OAuth login with session-based authentication
- Dashboard for scheduled, sent, and failed emails
- Compose and schedule emails for a future delivery time
- Email detail view with metadata and status tracking
- Background processing with BullMQ and Redis (durable, retry-capable jobs)
- Per-sender hourly sending limits using Redis counters
- PostgreSQL persistence through Prisma ORM
- Elasticsearch-powered email search and filtering
- Slack integration (OAuth connect and notifications)
- BullMQ admin dashboard at `/admin/queues`
- Docker Compose setup for local infrastructure

---

## Tech Stack

| Layer    | Technology                              |
| -------- | --------------------------------------- |
| Frontend | React, Vite                             |
| Backend  | Node.js, Express 5, TypeScript          |
| Queue    | BullMQ, Redis                           |
| Database | PostgreSQL, Prisma                      |
| Search   | Elasticsearch                           |
| Mail     | Nodemailer (Ethereal for local testing) |
| Auth     | Passport, Google OAuth 2.0              |

---

## Architecture

```text
Frontend (React + Vite)
    │  login, dashboard, compose, email detail
    ▼
Backend API (Express + TypeScript)
    ├── Auth routes (Google OAuth)
    ├── Email routes (create, list, schedule)
    ├── Slack routes (OAuth and settings)
    ├── Prisma → PostgreSQL
    ├── Redis → rate limiting and queue
    └── Elasticsearch → indexing and search
    ▼
Worker (BullMQ)
    ├── Consumes scheduled jobs from Redis
    ├── Sends email through Nodemailer
    ├── Updates status in PostgreSQL
    └── Handles retries and Slack notifications
```

---

## Prerequisites

- Node.js 20 or newer
- Docker Desktop
- A Google Cloud OAuth client (for login)
- Optional: a Slack app and ngrok (for Slack integration)

---

## Getting Started

### 1. Clone and install

```bash
git clone https://github.com/Bhakti-909/ReachInbox-Full-Stack-Email-Scheduler.git
cd ReachInbox-Full-Stack-Email-Scheduler

npm install
npm --prefix backend install
npm --prefix frontend install
```

### 2. Start infrastructure

```bash
docker compose up -d
```

| Service       | Host port |
| ------------- | --------- |
| PostgreSQL    | `5434`    |
| Redis         | `6380`    |
| Elasticsearch | `9200`    |

### 3. Configure environment variables

Create `backend/.env`:

```env
PORT=5000
NODE_ENV=development

# Database (matches docker-compose.yml)
DATABASE_URL="postgresql://postgres:root@localhost:5434/reachinbox"

# Redis (matches docker-compose.yml)
REDIS_HOST=localhost
REDIS_PORT=6380

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:5000/api/auth/google/callback

# Session
SESSION_SECRET=your_long_random_secret

# SMTP (Ethereal for development)
SMTP_HOST=smtp.ethereal.email
SMTP_PORT=587
SMTP_USER=your-ethereal-user
SMTP_PASS=your-ethereal-pass
SMTP_FROM=your-sender@example.com

# Worker and rate limiting
WORKER_CONCURRENCY=5
MIN_DELAY_MS=2000
MAX_EMAILS_PER_HOUR_PER_SENDER=15
RUN_WORKER=true

# Frontend
FRONTEND_URL=http://localhost:5173
FRONTEND_URLS=http://localhost:5173

# Elasticsearch
ELASTICSEARCH_URL=http://localhost:9200
ELASTIC_EMAIL_INDEX=emails

# Slack (optional)
SLACK_CLIENT_ID=your-slack-client-id
SLACK_CLIENT_SECRET=your-slack-client-secret
SLACK_REDIRECT_URI=https://your-ngrok-domain.ngrok-free.dev/api/slack/callback
```

Never commit this file. It is already covered by `.gitignore`.

### 4. Set up the database

```bash
cd backend
npx prisma generate
npx prisma migrate dev
cd ..
```

### 5. Run the app

From the project root:

```bash
npm run dev
```

This starts the backend API, the BullMQ worker, and the frontend dev server together.

### 6. Open the app

- Frontend: http://localhost:5173
- Backend API: http://localhost:5000
- Queue dashboard: http://localhost:5000/admin/queues

---

## Slack Integration (optional)

Slack requires a public HTTPS callback URL, so use ngrok during development:

```bash
npm --prefix backend run ngrok
```

Then:

1. Set `SLACK_REDIRECT_URI` in `backend/.env` to `https://<your-ngrok-domain>/api/slack/callback`.
2. Add the same URL under **OAuth & Permissions → Redirect URLs** in your Slack app settings.
3. Restart the backend.

The ngrok script uses PowerShell, so it runs on Windows.

---

## Scripts

```bash
# root
npm run dev        # backend + worker + frontend
npm run build      # build backend and frontend
npm run start      # backend + worker (production)

# backend
npm --prefix backend run dev
npm --prefix backend run worker
npm --prefix backend run reindex   # rebuild the Elasticsearch index
npm --prefix backend run build

# frontend
npm --prefix frontend run dev
npm --prefix frontend run build
```

---

## Project Structure

```text
ReachInbox-Full-Stack-Email-Scheduler/
├── backend/
│   ├── prisma/          # schema and migrations
│   ├── src/
│   │   ├── lib/         # prisma, redis, mailer, slack, elasticsearch
│   │   ├── middleware/
│   │   ├── queue/       # BullMQ queue
│   │   ├── routes/      # auth, email, slack
│   │   ├── scripts/     # reindex, seed, ngrok
│   │   ├── services/    # search, rate limiter, tokens
│   │   ├── workers/     # email worker
│   │   └── server.ts
│   ├── prisma.config.ts
│   └── package.json
├── frontend/
│   ├── src/
│   └── package.json
├── docker-compose.yml
├── package.json
└── Readme.md
```

---

## How It Works

1. A user signs in with Google.
2. They create a scheduled email from the dashboard.
3. The backend saves it to PostgreSQL, indexes it in Elasticsearch, and enqueues a delayed BullMQ job.
4. At the scheduled time, the worker checks the sender's hourly limit and sends the email.
5. The email status is updated to sent or failed, and a Slack notification is sent if connected.

BullMQ jobs are stored in Redis, so queued work survives worker restarts.

---

## Deployment Notes

Before deploying, update these to your live public URLs:

- `FRONTEND_URL` and `FRONTEND_URLS`
- `GOOGLE_REDIRECT_URI` (also in Google Cloud Console)
- `SLACK_REDIRECT_URI` (also in Slack app settings)
- CORS origins in the backend

Use strong values for `SESSION_SECRET` and database credentials, and use a real SMTP provider instead of Ethereal.

---

## Troubleshooting

- **Cannot connect to Postgres or Redis:** confirm the containers are running with `docker compose ps`, and that `.env` uses ports `5434` and `6380`.
- **Prisma client errors:** run `npx prisma generate` inside `backend`.
- **Emails not sending:** make sure the worker is running and `RUN_WORKER` and the SMTP settings are correct.
- **Slack OAuth fails:** the redirect URL must match exactly in both `.env` and the Slack app, and ngrok must be running.
