-- Run this in your Supabase SQL Editor and share the output or a screenshot!

-- 1. Check the columns of the game_sessions table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'game_sessions';

-- 2. Check the parameters of the process_game_session RPC function
SELECT pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.proname = 'process_game_session';
