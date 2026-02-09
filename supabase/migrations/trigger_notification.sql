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
    url := 'https://[YOUR_PROJECT_REF].supabase.co/functions/v1/notify-opportunity',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer [YOUR_ANON_KEY]"}',
    body := json_build_object('record', new)::jsonb
  );
  return new;
end;
$$;

-- Trigger to execute the function after a new row is inserted into opportunities
create trigger trigger_notify_new_opportunity
after insert on opportunities
for each row
execute function notify_new_opportunity();
