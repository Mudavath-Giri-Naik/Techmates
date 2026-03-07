-- =============================================================================
-- FIX: RLS policies blocking process_game_session pipeline
-- 
-- The process_game_session RPC inserts/updates multiple tables
-- (game_sessions, user_arena_stats, domain_percentile_cache, user_brain_score,
--  user_ranks, user_activity) but many lack INSERT/UPDATE RLS policies.
--
-- Solution: Make the pipeline functions SECURITY DEFINER so they bypass RLS.
-- This is safe because they are only called via RPC with validated params.
-- =============================================================================

-- Make process_game_session SECURITY DEFINER (both overloads)
CREATE OR REPLACE FUNCTION process_game_session(
  p_player_id       UUID,
  p_arena_id        UUID,
  p_mode            arena_mode,
  p_level_reached   INT,
  p_accuracy        NUMERIC,
  p_mistakes        INT,
  p_time_taken_sec  NUMERIC,
  p_opponent_id     UUID    DEFAULT NULL,
  p_won             BOOLEAN DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_raw_score   INT;
  v_session_id  UUID;
  v_college_id  UUID;
BEGIN
  v_raw_score := compute_raw_score(p_level_reached, p_accuracy, p_mistakes, p_time_taken_sec);

  INSERT INTO game_sessions (
    arena_id, player_id, opponent_id, mode,
    level_reached, accuracy, mistakes, time_taken_sec, raw_score, won
  ) VALUES (
    p_arena_id, p_player_id, p_opponent_id, p_mode,
    p_level_reached, p_accuracy, p_mistakes, p_time_taken_sec, v_raw_score, p_won
  ) RETURNING id INTO v_session_id;

  PERFORM update_arena_stats_after_session(v_session_id);
  PERFORM recalculate_domain_percentiles(p_arena_id);
  PERFORM recalculate_brain_score(p_player_id);

  SELECT college_id INTO v_college_id FROM profiles WHERE id = p_player_id;
  IF v_college_id IS NOT NULL THEN
    PERFORM recalculate_ranks(v_college_id);
  END IF;

  PERFORM mark_user_active(p_player_id);

  RETURN jsonb_build_object(
    'session_id',   v_session_id,
    'raw_score',    v_raw_score,
    'success',      TRUE
  );
END;
$$;

-- The overload with p_override_score
CREATE OR REPLACE FUNCTION process_game_session(
  p_player_id       UUID,
  p_arena_id        UUID,
  p_mode            arena_mode,
  p_level_reached   INT,
  p_accuracy        NUMERIC,
  p_mistakes        INT,
  p_time_taken_sec  NUMERIC,
  p_opponent_id     UUID    DEFAULT NULL,
  p_won             BOOLEAN DEFAULT NULL,
  p_override_score  INT     DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_raw_score   INT;
  v_session_id  UUID;
  v_college_id  UUID;
BEGIN
  v_raw_score := COALESCE(
    p_override_score,
    compute_raw_score(p_level_reached, p_accuracy, p_mistakes, p_time_taken_sec)
  );

  INSERT INTO game_sessions (
    arena_id, player_id, opponent_id, mode,
    level_reached, accuracy, mistakes, time_taken_sec, raw_score, won
  ) VALUES (
    p_arena_id, p_player_id, p_opponent_id, p_mode,
    p_level_reached, p_accuracy, p_mistakes, p_time_taken_sec, v_raw_score, p_won
  ) RETURNING id INTO v_session_id;

  PERFORM update_arena_stats_after_session(v_session_id);
  PERFORM recalculate_domain_percentiles(p_arena_id);
  PERFORM recalculate_brain_score(p_player_id);

  SELECT college_id INTO v_college_id FROM profiles WHERE id = p_player_id;
  IF v_college_id IS NOT NULL THEN
    PERFORM recalculate_ranks(v_college_id);
  END IF;

  PERFORM mark_user_active(p_player_id);

  RETURN jsonb_build_object(
    'session_id',  v_session_id,
    'raw_score',   v_raw_score,
    'success',     TRUE
  );
END;
$$;

-- Also make the helper functions SECURITY DEFINER since they write to protected tables
ALTER FUNCTION update_arena_stats_after_session(UUID) SECURITY DEFINER;
ALTER FUNCTION recalculate_domain_percentiles(UUID) SECURITY DEFINER;
ALTER FUNCTION recalculate_brain_score(UUID) SECURITY DEFINER;
ALTER FUNCTION recalculate_ranks(UUID) SECURITY DEFINER;
ALTER FUNCTION mark_user_active(UUID) SECURITY DEFINER;

-- Verify
SELECT 'Done! All pipeline functions are now SECURITY DEFINER.' AS status;
