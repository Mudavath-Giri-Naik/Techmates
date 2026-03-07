-- 1. Insert Dummy Data into Opportunities and Detail Tables
-- Run this in the Supabase SQL Editor to populate your empty tables!

DO $$
DECLARE
    internship_id uuid := extensions.uuid_generate_v4();
    hackathon_id uuid := extensions.uuid_generate_v4();
    event_id uuid := extensions.uuid_generate_v4();
BEGIN

    -- ==========================================
    -- 1. INTERNSHIP DUMMY DATA
    -- ==========================================
    INSERT INTO public.opportunities (id, title, org_name, type, status, description, deadline, apply_url, location)
    VALUES (
        internship_id, 
        'Software Engineering Intern', 
        'Google', 
        'internship', 
        'active', 
        'Join the frontend team and build amazing mobile experiences using Flutter and Dart.', 
        '2026-12-31', 
        'https://careers.google.com', 
        'Bangalore, India'
    );

    INSERT INTO public.internship_details (opportunity_id, title, company, description, duration, location, deadline, emp_type, stipend, tags, eligibility, link, is_elite)
    VALUES (
        internship_id, 
        'Software Engineering Intern', 
        'Google', 
        'Join the frontend team and build amazing mobile experiences using Flutter and Dart.', 
        '6 Months', 
        'Bangalore, India', 
        '2026-12-31', 
        'Full-time Intern', 
        100000, 
        ARRAY['Flutter', 'Dart', 'Firebase'], 
        'B.Tech / B.E CS Pre-final Year', 
        'https://careers.google.com', 
        true
    );

    -- ==========================================
    -- 2. HACKATHON DUMMY DATA
    -- ==========================================
    INSERT INTO public.opportunities (id, title, org_name, type, status, description, deadline, apply_url, location)
    VALUES (
        hackathon_id, 
        'Global App Hackathon 2026', 
        'Devfolio', 
        'hackathon', 
        'active', 
        'Compete with the best developers in the world to build innovative mobile apps within 48 hours.', 
        '2026-10-15', 
        'https://devfolio.co', 
        'Remote'
    );

    INSERT INTO public.hackathon_details (opportunity_id, title, company, team_size, location, description, eligibility, rounds, prizes, deadline, link)
    VALUES (
        hackathon_id, 
        'Global App Hackathon 2026', 
        'Devfolio', 
        '1-4 Members', 
        'Remote', 
        'Compete with the best developers in the world to build innovative mobile apps within 48 hours.', 
        'All College Students', 
        2, 
        '$15,000 Grand Prize', 
        '2026-10-15', 
        'https://devfolio.co'
    );

    -- ==========================================
    -- 3. EVENT DUMMY DATA
    -- ==========================================
    INSERT INTO public.opportunities (id, title, org_name, type, status, description, deadline, apply_url, location)
    VALUES (
        event_id, 
        'TechMates Flutter Meetup', 
        'TechMates', 
        'event', 
        'active', 
        'An exclusive invite-only meetup for TechMates community members to network and talk about Flutter.', 
        '2026-08-20', 
        'https://techmates.app', 
        'New Delhi, India'
    );

    INSERT INTO public.event_details (opportunity_id, title, organiser, description, venue, entry_fee, start_date, end_date, location_link, apply_link, apply_deadline, eligible)
    VALUES (
        event_id, 
        'TechMates Flutter Meetup', 
        'TechMates', 
        'An exclusive invite-only meetup for TechMates community members to network and talk about Flutter.', 
        'Delhi Convention Center', 
        'Free', 
        '2026-08-20 10:00:00', 
        '2026-08-20 18:00:00', 
        'https://maps.google.com', 
        'https://techmates.app', 
        '2026-08-15', 
        'TechMates Members'
    );

END $$;
