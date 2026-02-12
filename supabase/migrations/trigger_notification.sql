-- Enable pg_net extension to make HTTP requests
create extension if not exists "pg_net";

-- Function to call the notify-opportunity Edge Function
create or replace function notify_new_opportunity()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://hmcxfkirqqifahhbipdt.supabase.co/functions/v1/notify-opportunity',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer sb_publishable_O9gXifvrsfgnKedZagtBIw_i8zQsy5E"}',
    body := json_build_object('record', new)::jsonb
  );
  return new;
end;
$$;

-- Drop existing trigger if it exists
drop trigger if exists trigger_notify_new_opportunity on opportunities;

-- Trigger to execute the function after a new row is inserted into opportunities
create trigger trigger_notify_new_opportunity
after insert on opportunities
for each row
execute function notify_new_opportunity();
