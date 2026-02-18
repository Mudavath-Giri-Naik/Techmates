-- Add foreign key relationship between event_details and opportunities
ALTER TABLE public.event_details
ADD CONSTRAINT fk_event_opportunities
FOREIGN KEY (opportunity_id)
REFERENCES public.opportunities (id)
ON DELETE CASCADE;

-- Optional: Ensure 1:1 relationship
ALTER TABLE public.event_details
ADD CONSTRAINT unique_event_opportunity
UNIQUE (opportunity_id);
