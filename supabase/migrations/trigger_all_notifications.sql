-- Enable pg_net extension to make HTTP requests
create extension if not exists "pg_net";

-- Function to call the notify-opportunity Edge Function for internships
create or replace function notify_new_internship()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://hmcxfkirqqifahhbipdt.supabase.co/functions/v1/notify-opportunity',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_publishable_O9gXifvrsfgnKedZagtBIw_i8zQsy5E"}',
    body := json_build_object('record', row_to_json(new))::jsonb
  );
  return new;
end;
$$;

-- Function to call the notify-opportunity Edge Function for hackathons
create or replace function notify_new_hackathon()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://hmcxfkirqqifahhbipdt.supabase.co/functions/v1/notify-opportunity',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_publishable_O9gXifvrsfgnKedZagtBIw_i8zQsy5E"}',
    body := json_build_object('record', row_to_json(new))::jsonb
  );
  return new;
end;
$$;

-- Function to call the notify-opportunity Edge Function for events
create or replace function notify_new_event()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://hmcxfkirqqifahhbipdt.supabase.co/functions/v1/notify-opportunity',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_publishable_O9gXifvrsfgnKedZagtBIw_i8zQsy5E"}',
    body := json_build_object('record', row_to_json(new))::jsonb
  );
  return new;
end;
$$;

-- Drop existing triggers if they exist
drop trigger if exists trigger_notify_new_internship on internships;
drop trigger if exists trigger_notify_new_hackathon on hackathons;
drop trigger if exists trigger_notify_new_event on events;

-- Trigger for internships table
create trigger trigger_notify_new_internship
after insert on internships
for each row
execute function notify_new_internship();

-- Trigger for hackathons table
create trigger trigger_notify_new_hackathon
after insert on hackathons
for each row
execute function notify_new_hackathon();

-- Trigger for events table
create trigger trigger_notify_new_event
after insert on events
for each row
execute function notify_new_event();
