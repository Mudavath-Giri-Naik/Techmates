-- 1. DELETE ORPHANED ROWS
-- Before adding foreign keys, we must delete rows in details tables 
-- that have an opportunity_id which no longer exists in the opportunities table.

DELETE FROM public.internship_details 
WHERE opportunity_id NOT IN (SELECT id FROM public.opportunities);

DELETE FROM public.hackathon_details 
WHERE opportunity_id NOT IN (SELECT id FROM public.opportunities);

DELETE FROM public.event_details 
WHERE opportunity_id NOT IN (SELECT id FROM public.opportunities);

-- 2. NOW ADD THE FOREIGN KEYS
-- Ensure `internship_details` references `opportunities.id`
ALTER TABLE public.internship_details
  DROP CONSTRAINT IF EXISTS internship_details_posted_by_fkey,
  DROP CONSTRAINT IF EXISTS internship_details_opportunity_id_fkey,
  ADD CONSTRAINT internship_details_opportunity_id_fkey 
  FOREIGN KEY (opportunity_id) 
  REFERENCES public.opportunities(id) 
  ON DELETE CASCADE;

-- Ensure `hackathon_details` references `opportunities.id`
ALTER TABLE public.hackathon_details
  DROP CONSTRAINT IF EXISTS hackathon_details_posted_by_fkey,
  DROP CONSTRAINT IF EXISTS hackathon_details_opportunity_id_fkey,
  ADD CONSTRAINT hackathon_details_opportunity_id_fkey 
  FOREIGN KEY (opportunity_id) 
  REFERENCES public.opportunities(id) 
  ON DELETE CASCADE;

-- Ensure `event_details` references `opportunities.id`
ALTER TABLE public.event_details
  DROP CONSTRAINT IF EXISTS event_details_posted_by_fkey,
  DROP CONSTRAINT IF EXISTS event_details_opportunity_id_fkey,
  ADD CONSTRAINT event_details_opportunity_id_fkey 
  FOREIGN KEY (opportunity_id) 
  REFERENCES public.opportunities(id) 
  ON DELETE CASCADE;

-- 3. DROP UNINTENDED POSTED_BY COLUMNS
ALTER TABLE public.internship_details DROP COLUMN IF EXISTS posted_by;
ALTER TABLE public.hackathon_details DROP COLUMN IF EXISTS posted_by;
ALTER TABLE public.event_details DROP COLUMN IF EXISTS posted_by;
