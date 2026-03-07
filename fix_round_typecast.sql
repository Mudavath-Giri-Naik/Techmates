-- =============================================================================
-- FIX: ROUND(double precision, integer) does not exist
-- 
-- PERCENT_RANK() returns double precision, but PostgreSQL's ROUND() with
-- a precision argument only works with NUMERIC. We need explicit casts.
--
-- This fixes recalculate_domain_percentiles which is called inside
-- process_game_session.
-- =============================================================================

-- Fix recalculate_domain_percentiles
CREATE OR REPLACE FUNCTION recalculate_domain_percentiles(p_arena_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_domain_id INT;
BEGIN
  SELECT domain_id INTO v_domain_id FROM arenas WHERE id = p_arena_id;

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
    LEAST(1000, ROUND(r.percentile * 10)),
    NOW()
  FROM ranked r
  ON CONFLICT (user_id, domain_id) DO UPDATE
    SET percentile   = EXCLUDED.percentile,
        domain_score = EXCLUDED.domain_score,
        college_id   = EXCLUDED.college_id,
        updated_at   = NOW();
END;
$$;

-- Also fix recalculate_brain_score in case it has similar issues
CREATE OR REPLACE FUNCTION recalculate_brain_score(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_scores        INT[];
  v_weights       NUMERIC[] := ARRAY[1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4];
  v_weights_sum   NUMERIC   := 4.9;
  v_weighted_sum  NUMERIC   := 0;
  v_normalized    INT       := 0;
  v_breadth_bonus INT       := 0;
  v_streak_mult   NUMERIC   := 1.0;
  v_brain_score   INT       := 0;
  v_domains_played INT      := 0;
  v_streak        INT;

  v_speed           INT := 0;
  v_memory          INT := 0;
  v_attention       INT := 0;
  v_flexibility     INT := 0;
  v_problem_solving INT := 0;
  v_math            INT := 0;
  v_language        INT := 0;
  v_i               INT;
BEGIN
  SELECT
    MAX(CASE WHEN d.key = 'speed'           THEN dpc.domain_score ELSE 0 END),
    MAX(CASE WHEN d.key = 'memory'          THEN dpc.domain_score ELSE 0 END),
    MAX(CASE WHEN d.key = 'attention'       THEN dpc.domain_score ELSE 0 END),
    MAX(CASE WHEN d.key = 'flexibility'     THEN dpc.domain_score ELSE 0 END),
    MAX(CASE WHEN d.key = 'problem_solving' THEN dpc.domain_score ELSE 0 END),
    MAX(CASE WHEN d.key = 'math'            THEN dpc.domain_score ELSE 0 END),
    MAX(CASE WHEN d.key = 'language'        THEN dpc.domain_score ELSE 0 END)
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

  v_normalized := LEAST(1000, ROUND(v_weighted_sum / (1000 * v_weights_sum) * 1000)::INT);

  v_breadth_bonus := CASE WHEN v_domains_played = 7 THEN 60 ELSE 0 END;

  SELECT streak_days INTO v_streak FROM profiles WHERE id = p_user_id;
  v_streak_mult := get_streak_multiplier(COALESCE(v_streak, 0));

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

-- Verify
SELECT 'Done! Fixed ROUND type casts in domain percentile and brain score functions.' AS status;
