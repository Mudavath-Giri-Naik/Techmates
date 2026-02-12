# Notification System Setup Guide

## Overview
The Techmates app uses Firebase Cloud Messaging (FCM) to send push notifications when new opportunities are added to the database. This guide explains how to set up and verify the notification system.

## Architecture
1. **Topic Subscription**: All authenticated users are automatically subscribed to the FCM topic "all" for broadcast notifications
2. **Database Trigger**: When a new row is inserted into `opportunities`, `internships`, `hackathons`, or `events` tables, a PostgreSQL trigger fires
3. **Edge Function**: The trigger calls the `notify-opportunity` Edge Function via HTTP
4. **Broadcast**: The Edge Function formats the notification and calls `send-notification` to broadcast to all users via the "all" topic
5. **FCM**: The `send-notification` function sends push notifications via Firebase Cloud Messaging to all devices subscribed to the topic

## Setup Steps

### 1. Apply Database Triggers

Run the following SQL migration in your Supabase SQL Editor:

```bash
# Navigate to Supabase Dashboard → SQL Editor
# Copy and paste the contents of:
supabase/migrations/trigger_all_notifications.sql
```

This will create triggers for:
- `opportunities` table
- `internships` table  
- `hackathons` table
- `events` table

### 2. Verify Edge Functions are Deployed

Ensure these Edge Functions are deployed to Supabase:
- `notify-opportunity` - Formats notification content
- `send-notification` - Sends FCM messages

```bash
# Deploy Edge Functions (if not already deployed)
supabase functions deploy notify-opportunity
supabase functions deploy send-notification
```

### 3. Configure Firebase Environment Variables

In your Supabase Dashboard → Edge Functions → Secrets, add:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

These values come from your Firebase service account JSON file.

### 4. Test the System

1. **Insert a test opportunity** in Supabase:
```sql
INSERT INTO opportunities (title, organization, location, deadline, type, apply_link)
VALUES ('Test Internship', 'Test Org', 'Remote', '2026-03-01', 'internship', 'https://example.com');
```

2. **Check logs** in Supabase Dashboard → Edge Functions → Logs
3. **Verify notification** appears on your device

## Troubleshooting

### No notifications received?
1. Check if FCM token is saved in `profiles` table
2. Verify Edge Functions are deployed and have correct environment variables
3. Check Edge Function logs for errors
4. Ensure `pg_net` extension is enabled in Supabase

### Token not saving?
- Check app logs for `[NotificationService]` messages
- Verify user is authenticated before `NotificationService.init()` is called

### Trigger not firing?
- Run `SELECT * FROM pg_trigger WHERE tgname LIKE 'trigger_notify%';` to verify triggers exist
- Check Supabase logs for trigger execution errors
