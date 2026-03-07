-- =============================================================================
-- COMPREHENSIVE PIPELINE FIX — RUN THIS SINGLE FILE
-- Replaces ALL game pipeline functions in the correct order.
-- Safe to run multiple times (all CREATE OR REPLACE).
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════
-- 1. Ensure compute_raw_score exists
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION compute_raw_score(
  p_level_reached   INT,
  p_accuracy        NUMERIC,
  p_mistakes        INT,
  p_time_taken_sec  NUMERIC
) RETURNS INT
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  v_base       INT;
  v_acc_bonus  INT;
  v_speed_bonus INT;
  v_total      INT;
BEGIN
  -- Base score from level reached
  v_base := p_level_reached * 100;

  -- Accuracy bonus: up to 500 points for perfect accuracy
  v_acc_bonus := ROUND(GREATEST(0, p_accuracy) * 5)::INT;

  -- Speed bonus: faster = more points (max 300)
  v_speed_bonus := GREATEST(0, 300 - ROUND(COALESCE(p_time_taken_sec, 60) * 3)::INT);

  -- Penalty for mistakes
  v_total := v_base + v_acc_bonus + v_speed_bonus - (p_mistakes * 20);

  RETURN GREATEST(0, v_total);
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 2. mark_user_active
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION mark_user_active(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Update the active timestamp or streak in profiles
  UPDATE profiles
  SET updated_at = NOW()
  WHERE id = p_user_id;
EXCEPTION WHEN OTHERS THEN
  -- Non-critical, swallow errors
  NULL;
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 3. update_arena_stats_after_session
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_arena_stats_after_session(p_session_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_player_id  UUID;
  v_arena_id   UUID;
  v_raw_score  INT;
  v_accuracy   NUMERIC;
  v_won        BOOLEAN;
BEGIN
  -- Get session details
  SELECT player_id, arena_id, raw_score, accuracy, won
  INTO v_player_id, v_arena_id, v_raw_score, v_accuracy, v_won
  FROM game_sessions
  WHERE id = p_session_id;

  IF v_player_id IS NULL THEN
    RAISE NOTICE 'update_arena_stats: session % not found', p_session_id;
    RETURN;
  END IF;

  -- Upsert user_arena_stats (use best_score and last_played_at which are guaranteed to exist)
  INSERT INTO user_arena_stats (
    user_id, arena_id, best_score, last_played_at
  ) VALUES (
    v_player_id, v_arena_id, v_raw_score, NOW()
  )
  ON CONFLICT (user_id, arena_id) DO UPDATE SET
    best_score     = GREATEST(user_arena_stats.best_score, v_raw_score),
    last_played_at = NOW();
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 4. recalculate_domain_percentiles — uses actual best_score
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION recalculate_domain_percentiles(p_arena_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_domain_id INT;
BEGIN
  SELECT domain_id INTO v_domain_id FROM arenas WHERE id = p_arena_id;

  IF v_domain_id IS NULL THEN
    RAISE NOTICE 'recalculate_domain_percentiles: arena % not found or no domain', p_arena_id;
    RETURN;
  END IF;

  WITH domain_best AS (
    SELECT
      uas.user_id,
      p.college_id,
      MAX(uas.best_score) AS best_score
    FROM user_arena_stats uas
    JOIN profiles p ON p.id = uas.user_id
    JOIN arenas   a ON a.id = uas.arena_id
    WHERE a.domain_id = v_domain_id
      AND p.college_id IS NOT NULL
    GROUP BY uas.user_id, p.college_id
  ),
  ranked AS (
    SELECT
      user_id,
      college_id,
      best_score,
      ROUND(
        (PERCENT_RANK() OVER (
          PARTITION BY college_id ORDER BY best_score ASC
        ) * 100)::NUMERIC
      , 2) AS percentile
    FROM domain_best
  )
  INSERT INTO domain_percentile_cache (user_id, domain_id, college_id, percentile, domain_score, updated_at)
  SELECT
    r.user_id,
    v_domain_id,
    r.college_id,
    r.percentile,
    LEAST(1000, r.best_score),   -- actual best_score, NOT percentile-derived
    NOW()
  FROM ranked r
  ON CONFLICT (user_id, domain_id) DO UPDATE
    SET percentile   = EXCLUDED.percentile,
        domain_score = EXCLUDED.domain_score,
        college_id   = EXCLUDED.college_id,
        updated_at   = NOW();
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 5. recalculate_brain_score — self-contained, no external deps
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION recalculate_brain_score(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_scores         INT[];
  v_weights        NUMERIC[] := ARRAY[1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4];
  v_weights_sum    NUMERIC   := 4.9;
  v_weighted_sum   NUMERIC   := 0;
  v_normalized     INT       := 0;
  v_breadth_bonus  INT       := 0;
  v_streak_mult    NUMERIC   := 1.0;
  v_brain_score    INT       := 0;
  v_domains_played INT       := 0;

  v_speed           INT := 0;
  v_memory          INT := 0;
  v_attention       INT := 0;
  v_flexibility     INT := 0;
  v_problem_solving INT := 0;
  v_math            INT := 0;
  v_language        INT := 0;
  v_i               INT;
  v_streak          INT;
BEGIN
  SELECT
    COALESCE(MAX(CASE WHEN d.key = 'speed'           THEN dpc.domain_score END), 0),
    COALESCE(MAX(CASE WHEN d.key = 'memory'          THEN dpc.domain_score END), 0),
    COALESCE(MAX(CASE WHEN d.key = 'attention'       THEN dpc.domain_score END), 0),
    COALESCE(MAX(CASE WHEN d.key = 'flexibility'     THEN dpc.domain_score END), 0),
    COALESCE(MAX(CASE WHEN d.key = 'problem_solving' THEN dpc.domain_score END), 0),
    COALESCE(MAX(CASE WHEN d.key = 'math'            THEN dpc.domain_score END), 0),
    COALESCE(MAX(CASE WHEN d.key = 'language'        THEN dpc.domain_score END), 0)
  INTO
    v_speed, v_memory, v_attention, v_flexibility,
    v_problem_solving, v_math, v_language
  FROM domain_percentile_cache dpc
  JOIN domains d ON d.id = dpc.domain_id
  WHERE dpc.user_id = p_user_id;

  v_domains_played := (
    (CASE WHEN v_speed           > 0 THEN 1 ELSE 0 END) +
    (CASE WHEN v_memory          > 0 THEN 1 ELSE 0 END) +
    (CASE WHEN v_attention       > 0 THEN 1 ELSE 0 END) +
    (CASE WHEN v_flexibility     > 0 THEN 1 ELSE 0 END) +
    (CASE WHEN v_problem_solving > 0 THEN 1 ELSE 0 END) +
    (CASE WHEN v_math            > 0 THEN 1 ELSE 0 END) +
    (CASE WHEN v_language        > 0 THEN 1 ELSE 0 END)
  );

  v_scores := ARRAY(
    SELECT s FROM UNNEST(ARRAY[
      v_speed, v_memory, v_attention, v_flexibility,
      v_problem_solving, v_math, v_language
    ]) AS s
    ORDER BY s DESC
  );

  v_weighted_sum := 0;
  FOR v_i IN 1..7 LOOP
    v_weighted_sum := v_weighted_sum + (v_scores[v_i] * v_weights[v_i]);
  END LOOP;

  v_normalized := LEAST(1000, ROUND(v_weighted_sum / (1000.0 * v_weights_sum) * 1000.0)::INT);
  v_breadth_bonus := CASE WHEN v_domains_played = 7 THEN 60 ELSE 0 END;

  SELECT COALESCE(streak_days, 0) INTO v_streak FROM profiles WHERE id = p_user_id;
  v_streak_mult := CASE
    WHEN v_streak >= 30 THEN 1.15
    WHEN v_streak >= 14 THEN 1.10
    WHEN v_streak >= 7  THEN 1.05
    WHEN v_streak >= 3  THEN 1.02
    ELSE 1.0
  END;

  v_brain_score := LEAST(1000, ROUND((v_normalized + v_breadth_bonus) * v_streak_mult)::INT);

  INSERT INTO user_brain_score (
    user_id,
    score_speed, score_memory, score_attention, score_flexibility,
    score_problem_solving, score_math, score_language,
    domains_played, weighted_sum, normalized_score,
    breadth_bonus, streak_multiplier, brain_score, updated_at
  ) VALUES (
    p_user_id,
    v_speed, v_memory, v_attention, v_flexibility,
    v_problem_solving, v_math, v_language,
    v_domains_played, v_weighted_sum, v_normalized,
    v_breadth_bonus, v_streak_mult, v_brain_score, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    score_speed           = EXCLUDED.score_speed,
    score_memory          = EXCLUDED.score_memory,
    score_attention       = EXCLUDED.score_attention,
    score_flexibility     = EXCLUDED.score_flexibility,
    score_problem_solving = EXCLUDED.score_problem_solving,
    score_math            = EXCLUDED.score_math,
    score_language        = EXCLUDED.score_language,
    domains_played        = EXCLUDED.domains_played,
    weighted_sum          = EXCLUDED.weighted_sum,
    normalized_score      = EXCLUDED.normalized_score,
    breadth_bonus         = EXCLUDED.breadth_bonus,
    streak_multiplier     = EXCLUDED.streak_multiplier,
    brain_score           = EXCLUDED.brain_score,
    updated_at            = NOW();
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 6. recalculate_ranks
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION recalculate_ranks(p_college_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Delete existing ranks for this college, then re-insert
  DELETE FROM user_ranks WHERE college_id = p_college_id;

  INSERT INTO user_ranks (user_id, college_id, college_rank, class_rank, updated_at)
  SELECT
    ubs.user_id,
    p.college_id,
    ROW_NUMBER() OVER (
      PARTITION BY p.college_id
      ORDER BY ubs.brain_score DESC
    ) AS college_rank,
    ROW_NUMBER() OVER (
      PARTITION BY p.college_id, p.branch, p.year
      ORDER BY ubs.brain_score DESC
    ) AS class_rank,
    NOW()
  FROM user_brain_score ubs
  JOIN profiles p ON p.id = ubs.user_id
  WHERE p.college_id = p_college_id;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'recalculate_ranks error: %', SQLERRM;
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 7. process_game_session — THE MAIN PIPELINE (both overloads)
-- ═══════════════════════════════════════════════════════════════

-- Drop both overloads first to avoid conflicts
DROP FUNCTION IF EXISTS process_game_session(UUID, UUID, arena_mode, INT, NUMERIC, INT, NUMERIC, UUID, BOOLEAN);
DROP FUNCTION IF EXISTS process_game_session(UUID, UUID, arena_mode, INT, NUMERIC, INT, NUMERIC, UUID, BOOLEAN, INT);

-- Single function with optional p_override_score (no overloading needed!)
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
  -- Compute score (or use override for duels)
  v_raw_score := COALESCE(
    p_override_score,
    compute_raw_score(p_level_reached, p_accuracy, p_mistakes, p_time_taken_sec)
  );

  RAISE NOTICE 'process_game_session: player=% arena=% mode=% raw_score=%',
    p_player_id, p_arena_id, p_mode, v_raw_score;

  -- Insert game session
  INSERT INTO game_sessions (
    arena_id, player_id, opponent_id, mode,
    level_reached, accuracy, mistakes, time_taken_sec, raw_score, won
  ) VALUES (
    p_arena_id, p_player_id, p_opponent_id, p_mode,
    p_level_reached, p_accuracy, p_mistakes, p_time_taken_sec, v_raw_score, p_won
  ) RETURNING id INTO v_session_id;

  RAISE NOTICE 'process_game_session: session_id=%', v_session_id;

  -- Update arena stats
  PERFORM update_arena_stats_after_session(v_session_id);
  RAISE NOTICE 'process_game_session: arena stats updated';

  -- Recalculate domain percentiles
  PERFORM recalculate_domain_percentiles(p_arena_id);
  RAISE NOTICE 'process_game_session: domain percentiles recalculated';

  -- Recalculate brain score
  PERFORM recalculate_brain_score(p_player_id);
  RAISE NOTICE 'process_game_session: brain score recalculated';

  -- Recalculate ranks for the college
  SELECT college_id INTO v_college_id FROM profiles WHERE id = p_player_id;
  IF v_college_id IS NOT NULL THEN
    PERFORM recalculate_ranks(v_college_id);
    RAISE NOTICE 'process_game_session: ranks recalculated for college %', v_college_id;
  END IF;

  -- Mark user active
  PERFORM mark_user_active(p_player_id);

  RETURN jsonb_build_object(
    'session_id',   v_session_id,
    'raw_score',    v_raw_score,
    'brain_score',  (SELECT brain_score FROM user_brain_score WHERE user_id = p_player_id),
    'success',      TRUE
  );
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 8. RECALCULATE ALL EXISTING DATA
-- ═══════════════════════════════════════════════════════════════
DO $$
DECLARE
  r RECORD;
  cnt INT := 0;
BEGIN
  -- Recalculate domain percentiles for all active arenas
  FOR r IN SELECT id, name FROM arenas WHERE is_active = TRUE
  LOOP
    PERFORM recalculate_domain_percentiles(r.id);
    RAISE NOTICE 'Recalculated percentiles for arena: %', r.name;
  END LOOP;

  -- Recalculate brain score for all users who have arena stats
  FOR r IN SELECT DISTINCT user_id FROM user_arena_stats
  LOOP
    PERFORM recalculate_brain_score(r.user_id);
    cnt := cnt + 1;
  END LOOP;
  RAISE NOTICE 'Recalculated brain scores for % users', cnt;

  -- Recalculate ranks for all colleges
  FOR r IN SELECT DISTINCT college_id FROM profiles WHERE college_id IS NOT NULL
  LOOP
    PERFORM recalculate_ranks(r.college_id);
  END LOOP;
  RAISE NOTICE 'Ranks recalculated for all colleges';
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 9. VERIFY — Show all scores
-- ═══════════════════════════════════════════════════════════════

-- Check domain scores
SELECT 'domain_percentile_cache' AS source,
       p.full_name, d.key AS domain, dpc.domain_score, dpc.percentile
FROM domain_percentile_cache dpc
JOIN profiles p ON p.id = dpc.user_id
JOIN domains d ON d.id = dpc.domain_id
ORDER BY dpc.domain_score DESC;

-- Check brain scores
SELECT 'user_brain_score' AS source,
       p.full_name, ubs.brain_score, ubs.score_speed, ubs.domains_played,
       ubs.weighted_sum, ubs.normalized_score
FROM user_brain_score ubs
JOIN profiles p ON p.id = ubs.user_id
ORDER BY ubs.brain_score DESC;

-- Check game sessions
SELECT 'game_sessions' AS source,
       p.full_name, gs.raw_score, gs.accuracy, gs.level_reached,
       gs.played_at
FROM game_sessions gs
JOIN profiles p ON p.id = gs.player_id
ORDER BY gs.played_at DESC
LIMIT 10;

-- Check arena stats
SELECT 'user_arena_stats' AS source,
       p.full_name, a.name AS arena, uas.best_score
FROM user_arena_stats uas
JOIN profiles p ON p.id = uas.user_id
JOIN arenas a ON a.id = uas.arena_id
ORDER BY uas.best_score DESC;

SELECT '🎉 Pipeline fix complete! Check the result tables above.' AS status;
