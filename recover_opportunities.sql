-- 1. Recover Internships
INSERT INTO public.opportunities (
  id,
  title,
  org_name,
  type,
  status,
  description,
  deadline,
  apply_url,
  location
)
SELECT 
  opportunity_id,
  title,
  company,
  'internship'::public.opp_type,
  'active'::public.opp_status,
  description,
  deadline::date,
  link,
  location
FROM public.internship_details
ON CONFLICT (id) DO NOTHING;

-- 2. Recover Hackathons
INSERT INTO public.opportunities (
  id,
  title,
  org_name,
  type,
  status,
  description,
  deadline,
  apply_url,
  location
)
SELECT 
  opportunity_id,
  title,
  company,
  'hackathon'::public.opp_type,
  'active'::public.opp_status,
  description,
  deadline::date,
  link,
  location
FROM public.hackathon_details
ON CONFLICT (id) DO NOTHING;

-- 3. Recover Events
INSERT INTO public.opportunities (
  id,
  title,
  org_name,
  type,
  status,
  description,
  deadline,
  apply_url,
  location
)
SELECT 
  opportunity_id,
  title,
  COALESCE(organiser, 'TechMates'), -- Fallback just in case
  'event'::public.opp_type,
  'active'::public.opp_status,
  description,
  apply_deadline::date,
  apply_link,
  venue
FROM public.event_details
ON CONFLICT (id) DO NOTHING;
