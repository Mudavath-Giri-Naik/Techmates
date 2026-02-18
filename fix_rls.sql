-- =============================================================================
-- FIX: Infinite Recursion in "user_roles" Policy
-- =============================================================================
-- The error "infinite recursion detected in policy for relation user_roles"
-- happens when a policy on 'user_roles' queries 'user_roles' itself directly.
--
-- RUN THIS SCRIPT IN THE SUPABASE SQL EDITOR.
-- =============================================================================

-- 1. Drop existing problematic policies on user_roles
DROP POLICY IF EXISTS "Users can read own role" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can read all roles" ON public.user_roles;
DROP POLICY IF EXISTS "Super Admins can read all roles" ON public.user_roles;
-- Also drop any policies that might be named generally
DROP POLICY IF EXISTS "Enable read access for all users" ON public.user_roles;

-- 2. Create a SAFE policy for users to read ONLY their own role
-- This uses auth.uid() comparison which does NOT trigger recursion.
CREATE POLICY "Read Own Role" 
ON public.user_roles 
FOR SELECT 
USING ( auth.uid() = user_id );

-- 3. Create a SAFE policy for Super Admins
-- To avoid recursion, we should NOT look up the user's role in the user_roles table
-- inside the policy for the user_roles table, IF possible.
-- However, if we must, we can use a separate lookup that doesn't trigger RLS, 
-- but standard RLS doesn't allow bypassing itself easily in this context.
--
-- ALTERNATIVE: Grant access if the user's metadata contains the role (if you sync it),
-- OR rely on the fact that we primarily need users to read their OWN role.
--
-- FOR NOW: This simple policy covers 99% of app usage (users checking their own permissions).
-- The Admin Dashboard might need to read ALL roles.
-- For the Admin Dashboard, we can enable a specific policy:

CREATE POLICY "Super Admin Read All"
ON public.user_roles
FOR SELECT
USING (
  -- Check if the requesting user has 'super_admin' role 
  -- WITHOUT triggering this table's RLS again loop.
  -- We can do this by checking the profiles table instead (if reliable) OR
  -- by using a SECURITY DEFINER function.
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'super_admin'
  )
);

-- =============================================================================
-- FIX: Profiles Policy (If Profiles also triggers recursion)
-- =============================================================================
-- Ensure profiles doesn't query user_roles in a recursive way.

DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone." 
ON public.profiles FOR SELECT 
USING ( true );

-- =============================================================================
-- VERIFICATION
-- =============================================================================
-- After running this, the "42P17" error should disappear.
