-- =====================================================
-- TECHMATES COMPETE FIX — RUN IN SUPABASE SQL EDITOR
-- =====================================================
-- Fixes: missing columns, SECURITY DEFINER, RLS policies,
-- user_activity init, view column name, missing row guards
-- =====================================================


-- ─────────────────────────────────────────────────────
-- 0. ADD MISSING COLUMNS TO EXISTING TABLES
-- ─────────────────────────────────────────────────────

-- game_sessions: add rating tracking columns
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS difficulty_level int NOT NULL DEFAULT 1;
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS time_taken_ms bigint NOT NULL DEFAULT 0;
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS mistakes int NOT NULL DEFAULT 0;
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS rating_before numeric;
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS rating_after numeric;
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS is_counted boolean NOT NULL DEFAULT true;
ALTER TABLE public.game_sessions ADD COLUMN IF NOT EXISTS session_metadata jsonb;

-- game_sessions: add generated column for rating_delta (skip if exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'game_sessions' AND column_name = 'rating_delta'
  ) THEN
    ALTER TABLE public.game_sessions
      ADD COLUMN rating_delta numeric GENERATED ALWAYS AS (rating_after - rating_before) STORED;
  END IF;
END $$;

-- user_arena_stats: add missing columns
ALTER TABLE public.user_arena_stats ADD COLUMN IF NOT EXISTS avg_raw_score numeric NOT NULL DEFAULT 0;
ALTER TABLE public.user_arena_stats ADD COLUMN IF NOT EXISTS stale_days int NOT NULL DEFAULT 0;
ALTER TABLE public.user_arena_stats ADD COLUMN IF NOT EXISTS is_stale boolean NOT NULL DEFAULT false;

-- arenas: add missing columns
ALTER TABLE public.arenas ADD COLUMN IF NOT EXISTS ability_weight numeric NOT NULL DEFAULT 0.25;
ALTER TABLE public.arenas ADD COLUMN IF NOT EXISTS rating_default numeric NOT NULL DEFAULT 500;
ALTER TABLE public.arenas ADD COLUMN IF NOT EXISTS sort_order int NOT NULL DEFAULT 0;

-- Create missing tables if they don't exist

CREATE TABLE IF NOT EXISTS public.user_activity (
  user_id               uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  college_id            uuid NOT NULL REFERENCES public.colleges(id) ON DELETE CASCADE,
  last_active_at        timestamptz,
  inactive_days         int NOT NULL DEFAULT 0,
  current_streak        int NOT NULL DEFAULT 0,
  longest_streak        int NOT NULL DEFAULT 0,
  active_days_last_7    int NOT NULL DEFAULT 0,
  active_days_last_30   int NOT NULL DEFAULT 0,
  consistency_score     numeric NOT NULL DEFAULT 1.0,
  updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tpi_history (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  college_id     uuid NOT NULL REFERENCES public.colleges(id) ON DELETE CASCADE,
  final_tpi      numeric NOT NULL,
  campus_rank    int,
  ability_score  numeric,
  consistency_score numeric,
  growth_score   numeric,
  recorded_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.arena_percentile_cache (
  user_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  arena_id     uuid NOT NULL REFERENCES public.arenas(id) ON DELETE CASCADE,
  college_id   uuid NOT NULL REFERENCES public.colleges(id) ON DELETE CASCADE,
  percentile   numeric NOT NULL DEFAULT 0,
  arena_rank   int,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, arena_id)
);

CREATE TABLE IF NOT EXISTS public.leaderboard_snapshots (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  college_id      uuid NOT NULL REFERENCES public.colleges(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  final_tpi       numeric NOT NULL,
  final_tpi_1000  numeric NOT NULL DEFAULT 0,
  campus_rank     int,
  ability_score   numeric,
  consistency_score numeric,
  growth_score    numeric,
  snapshot_date   date NOT NULL DEFAULT current_date,
  UNIQUE (college_id, user_id, snapshot_date)
);

-- user_tpi: add missing columns
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS ability_score numeric NOT NULL DEFAULT 0;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS consistency_score numeric NOT NULL DEFAULT 0;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS growth_score numeric NOT NULL DEFAULT 0;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS ability_weight numeric NOT NULL DEFAULT 0.60;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS consistency_weight numeric NOT NULL DEFAULT 0.25;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS growth_weight numeric NOT NULL DEFAULT 0.15;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS final_tpi_1000 numeric NOT NULL DEFAULT 0;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS campus_percentile numeric;
ALTER TABLE public.user_tpi ADD COLUMN IF NOT EXISTS total_campus_players int;


-- ─────────────────────────────────────────────────────
-- 1. RLS POLICIES
-- ─────────────────────────────────────────────────────

-- game_sessions: users can insert/read their own
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users insert own sessions" ON public.game_sessions;
CREATE POLICY "Users insert own sessions" ON public.game_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users read own sessions" ON public.game_sessions;
CREATE POLICY "Users read own sessions" ON public.game_sessions FOR SELECT USING (auth.uid() = user_id);

-- user_arena_stats: read own
ALTER TABLE public.user_arena_stats ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own arena stats" ON public.user_arena_stats;
CREATE POLICY "Users read own arena stats" ON public.user_arena_stats FOR SELECT USING (auth.uid() = user_id);

-- user_tpi: read all (for leaderboard)
ALTER TABLE public.user_tpi ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read tpi" ON public.user_tpi;
CREATE POLICY "Anyone can read tpi" ON public.user_tpi FOR SELECT USING (true);

-- arena_rating_history: read own
ALTER TABLE public.arena_rating_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own rating history" ON public.arena_rating_history;
CREATE POLICY "Users read own rating history" ON public.arena_rating_history FOR SELECT USING (auth.uid() = user_id);

-- user_activity: read own
ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own activity" ON public.user_activity;
CREATE POLICY "Users read own activity" ON public.user_activity FOR SELECT USING (auth.uid() = user_id);

-- arena_percentile_cache: read all
ALTER TABLE public.arena_percentile_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone read percentile cache" ON public.arena_percentile_cache;
CREATE POLICY "Anyone read percentile cache" ON public.arena_percentile_cache FOR SELECT USING (true);

-- tpi_history: read own
ALTER TABLE public.tpi_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own tpi history" ON public.tpi_history;
CREATE POLICY "Users read own tpi history" ON public.tpi_history FOR SELECT USING (auth.uid() = user_id);

-- leaderboard_snapshots: read all
ALTER TABLE public.leaderboard_snapshots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone read leaderboard snapshots" ON public.leaderboard_snapshots;
CREATE POLICY "Anyone read leaderboard snapshots" ON public.leaderboard_snapshots FOR SELECT USING (true);


-- ─────────────────────────────────────────────────────
-- 2. UTILITY FUNCTIONS (must exist before other functions)
-- ─────────────────────────────────────────────────────

-- F1: Compute raw session score
CREATE OR REPLACE FUNCTION public.compute_raw_score(
  p_level      int,
  p_accuracy   numeric,
  p_mistakes   int,
  p_time_ms    bigint
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT greatest(0,
    (p_level * 100)
    + (p_accuracy * 10)
    - (p_mistakes * 20)
    - (p_time_ms::numeric / 1000 / 10)
  );
$$;

-- F2: Compute ELO delta based on current rating and session percentile
CREATE OR REPLACE FUNCTION public.compute_elo_delta(
  p_current_rating   numeric,
  p_player_percentile numeric
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT round(
    CASE
      WHEN p_current_rating < 300 THEN 32
      WHEN p_current_rating < 500 THEN 24
      WHEN p_current_rating < 700 THEN 16
      ELSE 12
    END
    * ((p_player_percentile / 100.0) - 0.5)
  , 2);
$$;


-- ─────────────────────────────────────────────────────
-- 3. FIX update_arena_stats_after_session (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_arena_stats_after_session(
  p_session_id         uuid,
  p_user_id            uuid,
  p_arena_id           uuid,
  p_college_id         uuid,
  p_raw_score          numeric,
  p_accuracy           numeric,
  p_level              int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_rating  numeric;
  v_new_rating      numeric;
  v_delta           numeric;
  v_total_recent    int;
  v_below           int;
  v_player_percentile numeric;
  v_min             numeric;
  v_max             numeric;
  v_default         numeric;
BEGIN
  SELECT rating_min, rating_max, rating_default
  INTO v_min, v_max, v_default
  FROM public.arenas WHERE id = p_arena_id;

  INSERT INTO public.user_arena_stats
    (user_id, arena_id, college_id, rating, last_played_at)
  VALUES (p_user_id, p_arena_id, p_college_id, v_default, now())
  ON CONFLICT (user_id, arena_id) DO NOTHING;

  SELECT rating INTO v_current_rating
  FROM public.user_arena_stats
  WHERE user_id = p_user_id AND arena_id = p_arena_id;

  -- Compute accurate player percentile server-side (bypasses RLS limits)
  SELECT count(*) INTO v_total_recent
  FROM (
    SELECT raw_score FROM public.game_sessions
    WHERE arena_id = p_arena_id AND college_id = p_college_id
    ORDER BY created_at DESC LIMIT 100
  ) sub;

  IF coalesce(v_total_recent, 0) = 0 THEN
    v_player_percentile := 50.0;
  ELSE
    SELECT count(*) INTO v_below
    FROM (
      SELECT raw_score FROM public.game_sessions
      WHERE arena_id = p_arena_id AND college_id = p_college_id
      ORDER BY created_at DESC LIMIT 100
    ) sub
    WHERE raw_score < p_raw_score;
    v_player_percentile := (v_below::numeric / v_total_recent::numeric) * 100.0;
  END IF;

  v_delta := public.compute_elo_delta(v_current_rating, v_player_percentile);
  v_new_rating := greatest(v_min, least(v_max, v_current_rating + v_delta));

  UPDATE public.game_sessions
  SET rating_before = v_current_rating, rating_after = v_new_rating
  WHERE id = p_session_id;

  UPDATE public.user_arena_stats
  SET
    rating             = v_new_rating,
    total_sessions     = total_sessions + 1,
    avg_accuracy       = ((avg_accuracy * total_sessions) + p_accuracy) / (total_sessions + 1),
    best_raw_score     = greatest(best_raw_score, p_raw_score),
    best_level_reached = greatest(best_level_reached, p_level),
    avg_raw_score      = ((avg_raw_score * total_sessions) + p_raw_score) / (total_sessions + 1),
    last_played_at     = now(),
    stale_days         = 0,
    is_stale           = false,
    updated_at         = now()
  WHERE user_id = p_user_id AND arena_id = p_arena_id;

  INSERT INTO public.arena_rating_history
    (user_id, arena_id, rating, delta, session_id)
  VALUES (p_user_id, p_arena_id, v_new_rating, v_delta, p_session_id);
END;
$$;


-- ─────────────────────────────────────────────────────
-- 3. FIX mark_user_active (SECURITY DEFINER + auto-create row)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.mark_user_active(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_last_active   timestamptz;
  v_streak        int;
  v_college_id    uuid;
BEGIN
  -- Get college_id from profiles
  SELECT college_id INTO v_college_id FROM public.profiles WHERE id = p_user_id;

  -- Ensure user_activity row exists
  INSERT INTO public.user_activity (user_id, college_id, last_active_at, consistency_score)
  VALUES (p_user_id, v_college_id, now(), 1.0)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT last_active_at, current_streak
  INTO v_last_active, v_streak
  FROM public.user_activity WHERE user_id = p_user_id;

  IF v_last_active::date = current_date - 1 THEN
    v_streak := coalesce(v_streak, 0) + 1;
  ELSIF v_last_active IS NULL OR v_last_active::date < current_date - 1 THEN
    v_streak := 1;
  END IF;

  UPDATE public.user_activity
  SET
    last_active_at      = now(),
    inactive_days       = 0,
    consistency_score   = least(1.0, consistency_score + 0.02),
    current_streak      = coalesce(v_streak, 1),
    longest_streak      = greatest(coalesce(longest_streak, 0), coalesce(v_streak, 1)),
    active_days_last_7  = (
      SELECT count(distinct created_at::date)
      FROM public.game_sessions WHERE user_id = p_user_id AND created_at >= now() - interval '7 days'
    ),
    active_days_last_30 = (
      SELECT count(distinct created_at::date)
      FROM public.game_sessions WHERE user_id = p_user_id AND created_at >= now() - interval '30 days'
    ),
    updated_at = now()
  WHERE user_id = p_user_id;
END;
$$;


-- ─────────────────────────────────────────────────────
-- 4. FIX recalculate_user_tpi (SECURITY DEFINER + get college from profiles)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.recalculate_user_tpi(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ability       numeric := 0;
  v_consistency   numeric := 0;
  v_growth        numeric := 0;
  v_final_tpi     numeric := 0;
  v_college_id    uuid;
  v_ab_w          numeric := 0.60;
  v_co_w          numeric := 0.25;
  v_gr_w          numeric := 0.15;
BEGIN
  -- Get college_id from profiles (always works, even for new users)
  SELECT college_id INTO v_college_id FROM public.profiles WHERE id = p_user_id;

  -- Check if user_tpi row exists, use its weights if so
  SELECT ability_weight, consistency_weight, growth_weight
  INTO v_ab_w, v_co_w, v_gr_w
  FROM public.user_tpi WHERE user_id = p_user_id;

  -- Use defaults if row didn't exist
  v_ab_w := coalesce(v_ab_w, 0.60);
  v_co_w := coalesce(v_co_w, 0.25);
  v_gr_w := coalesce(v_gr_w, 0.15);

  -- ABILITY: weighted sum of arena ratings normalized to 0–100
  SELECT coalesce(sum(uas.rating * a.ability_weight / 10.0), 0)
  INTO v_ability
  FROM public.user_arena_stats uas
  JOIN public.arenas a ON uas.arena_id = a.id
  WHERE uas.user_id = p_user_id AND a.is_active = true;

  -- CONSISTENCY: from user_activity
  SELECT coalesce(consistency_score * 100, 50) INTO v_consistency
  FROM public.user_activity WHERE user_id = p_user_id;
  v_consistency := coalesce(v_consistency, 50);

  -- GROWTH
  v_growth := public.compute_growth_score(p_user_id);

  -- FINAL TPI (0–100)
  v_final_tpi := round(
    (v_ability * v_ab_w) + (v_consistency * v_co_w) + (v_growth * v_gr_w)
  , 2);

  -- Upsert user_tpi
  INSERT INTO public.user_tpi
    (user_id, college_id, ability_score, consistency_score, growth_score,
     final_tpi, final_tpi_1000, last_calculated_at, updated_at)
  VALUES
    (p_user_id, v_college_id, v_ability, v_consistency, v_growth,
     v_final_tpi, v_final_tpi * 10, now(), now())
  ON CONFLICT (user_id) DO UPDATE SET
    ability_score      = excluded.ability_score,
    consistency_score  = excluded.consistency_score,
    growth_score       = excluded.growth_score,
    final_tpi          = excluded.final_tpi,
    final_tpi_1000     = excluded.final_tpi_1000,
    last_calculated_at = excluded.last_calculated_at,
    updated_at         = excluded.updated_at;

  -- Snapshot for graphs
  INSERT INTO public.tpi_history
    (user_id, college_id, final_tpi, ability_score, consistency_score, growth_score)
  VALUES (p_user_id, v_college_id, v_final_tpi, v_ability, v_consistency, v_growth);
END;
$$;


-- ─────────────────────────────────────────────────────
-- 5. FIX recalculate_college_ranks (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.recalculate_college_ranks(p_college_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total int;
BEGIN
  SELECT count(*) INTO v_total
  FROM public.user_tpi WHERE college_id = p_college_id;

  WITH ranked AS (
    SELECT user_id,
           rank() OVER (ORDER BY final_tpi DESC) AS rnk,
           round(
             (1 - (rank() OVER (ORDER BY final_tpi DESC) - 1.0) / nullif(count(*) OVER () - 1, 0)) * 100
           , 1) AS pct
    FROM public.user_tpi WHERE college_id = p_college_id
  )
  UPDATE public.user_tpi t
  SET campus_rank = r.rnk, campus_percentile = r.pct, total_campus_players = v_total
  FROM ranked r WHERE t.user_id = r.user_id;
END;
$$;


-- ─────────────────────────────────────────────────────
-- 6. FIX compute_growth_score (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.compute_growth_score(p_user_id uuid)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tpi_30d_ago numeric;
  v_tpi_now     numeric;
  v_growth      numeric;
BEGIN
  SELECT final_tpi INTO v_tpi_30d_ago
  FROM public.tpi_history
  WHERE user_id = p_user_id AND recorded_at >= now() - interval '30 days'
  ORDER BY recorded_at ASC LIMIT 1;

  SELECT coalesce(final_tpi, 0) INTO v_tpi_now
  FROM public.user_tpi WHERE user_id = p_user_id;

  IF v_tpi_30d_ago IS NULL OR v_tpi_30d_ago = 0 THEN
    RETURN 50;
  END IF;

  v_growth := greatest(0, least(100,
    50 + ((v_tpi_now - v_tpi_30d_ago) / v_tpi_30d_ago * 100)
  ));
  RETURN round(v_growth, 2);
END;
$$;


-- ─────────────────────────────────────────────────────
-- 7. FIX process_game_session (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.process_game_session(
  p_session_id        uuid,
  p_user_id           uuid,
  p_arena_id          uuid,
  p_college_id        uuid,
  p_raw_score         numeric,
  p_accuracy          numeric,
  p_level             int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.update_arena_stats_after_session(
    p_session_id, p_user_id, p_arena_id, p_college_id,
    p_raw_score, p_accuracy, p_level
  );
  PERFORM public.mark_user_active(p_user_id);
  PERFORM public.recalculate_user_tpi(p_user_id);
  PERFORM public.recalculate_college_ranks(p_college_id);
  PERFORM public.recalculate_arena_percentiles(p_arena_id, p_college_id);
END;
$$;


-- ─────────────────────────────────────────────────────
-- 8. FIX apply_activity_decay (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.apply_activity_decay()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.user_activity
  SET
    inactive_days     = greatest(0, extract(day from now() - last_active_at)::int),
    consistency_score = greatest(0.50, 1.0 - greatest(0,
      (extract(day from now() - last_active_at)::int - 2)) * 0.02),
    updated_at = now()
  WHERE last_active_at < now() - interval '2 days';

  UPDATE public.user_arena_stats
  SET stale_days = extract(day from now() - last_played_at)::int,
      is_stale = (extract(day from now() - last_played_at)::int >= 14)
  WHERE last_played_at < now() - interval '3 days';
END;
$$;


-- ─────────────────────────────────────────────────────
-- 9. FIX recalculate_arena_percentiles (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.recalculate_arena_percentiles(
  p_arena_id uuid, p_college_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  WITH ranked AS (
    SELECT uas.user_id,
           round((percent_rank() OVER (ORDER BY uas.rating ASC) * 100)::numeric, 1) AS pct,
           rank() OVER (ORDER BY uas.rating DESC) AS arena_rank
    FROM public.user_arena_stats uas
    WHERE uas.arena_id = p_arena_id AND uas.college_id = p_college_id
  )
  INSERT INTO public.arena_percentile_cache
    (user_id, arena_id, college_id, percentile, arena_rank, updated_at)
  SELECT r.user_id, p_arena_id, p_college_id, r.pct, r.arena_rank, now()
  FROM ranked r
  ON CONFLICT (user_id, arena_id) DO UPDATE SET
    percentile = excluded.percentile, arena_rank = excluded.arena_rank, updated_at = excluded.updated_at;

  UPDATE public.user_arena_stats uas
  SET percentile = apc.percentile
  FROM public.arena_percentile_cache apc
  WHERE uas.user_id = apc.user_id AND uas.arena_id = apc.arena_id AND apc.college_id = p_college_id;
END;
$$;


-- ─────────────────────────────────────────────────────
-- 10. FIX take_leaderboard_snapshot (SECURITY DEFINER)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.take_leaderboard_snapshot(p_college_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.leaderboard_snapshots
    (college_id, user_id, final_tpi, final_tpi_1000,
     campus_rank, ability_score, consistency_score, growth_score, snapshot_date)
  SELECT t.college_id, t.user_id, t.final_tpi, t.final_tpi_1000,
         t.campus_rank, t.ability_score, t.consistency_score, t.growth_score, current_date
  FROM public.user_tpi t WHERE t.college_id = p_college_id
  ON CONFLICT (college_id, user_id, snapshot_date) DO UPDATE SET
    final_tpi = excluded.final_tpi, final_tpi_1000 = excluded.final_tpi_1000,
    campus_rank = excluded.campus_rank, ability_score = excluded.ability_score,
    consistency_score = excluded.consistency_score, growth_score = excluded.growth_score;
END;
$$;


-- ─────────────────────────────────────────────────────
-- 11. FIX VIEWS (profiles.name not full_name)
-- ─────────────────────────────────────────────────────

CREATE OR REPLACE VIEW public.v_campus_leaderboard AS
SELECT
  t.college_id, t.user_id,
  p.name AS full_name,
  p.avatar_url,
  t.final_tpi, t.final_tpi_1000,
  t.campus_rank, t.campus_percentile,
  t.ability_score, t.consistency_score, t.growth_score,
  t.total_campus_players, t.last_calculated_at
FROM public.user_tpi t
JOIN public.profiles p ON p.id = t.user_id
ORDER BY t.final_tpi DESC;

CREATE OR REPLACE VIEW public.v_user_scorecard AS
SELECT
  t.user_id, t.college_id,
  t.final_tpi, t.final_tpi_1000,
  t.ability_score, t.consistency_score, t.growth_score,
  t.campus_rank, t.campus_percentile, t.total_campus_players,
  ua.current_streak, ua.longest_streak,
  ua.active_days_last_7, ua.active_days_last_30,
  ua.inactive_days, t.last_calculated_at
FROM public.user_tpi t
LEFT JOIN public.user_activity ua ON ua.user_id = t.user_id;

CREATE OR REPLACE VIEW public.v_user_arena_breakdown AS
SELECT
  uas.user_id, uas.college_id,
  a.code AS arena_code, a.name AS arena_name,
  a.ability_weight, uas.rating, uas.percentile,
  apc.arena_rank, uas.total_sessions, uas.avg_accuracy,
  uas.best_raw_score, uas.best_level_reached,
  uas.last_played_at, uas.stale_days, uas.is_stale
FROM public.user_arena_stats uas
JOIN public.arenas a ON a.id = uas.arena_id
LEFT JOIN public.arena_percentile_cache apc
  ON apc.user_id = uas.user_id AND apc.arena_id = uas.arena_id;


-- =====================================================
-- DONE. After running this, hot restart your Flutter app.
-- =====================================================
