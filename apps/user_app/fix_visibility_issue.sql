-- Fix visibility issue for user app
-- Run this in your Supabase SQL Editor

-- 1. First, ensure the column exists
ALTER TABLE services ADD COLUMN IF NOT EXISTS is_visible_to_users BOOLEAN DEFAULT true;

-- 2. Update all existing services to be visible to users
UPDATE services SET is_visible_to_users = true WHERE is_visible_to_users IS NULL;

-- 3. Update the RLS policy to not require visibility check for now
DROP POLICY IF EXISTS "Anonymous users can view active and visible services" ON services;
DROP POLICY IF EXISTS "Anonymous users can view active services" ON services;

-- Create a simple policy that allows viewing all active services
CREATE POLICY "Anonymous users can view active services" ON services
    FOR SELECT USING (is_active = true);

-- 4. Also allow authenticated users to view services
CREATE POLICY "Authenticated users can view active services" ON services
    FOR SELECT USING (is_active = true);

-- 5. Keep existing vendor policies
-- Vendors can manage their own services (existing policies should remain)
