-- RLS Policies for User App Access
-- Run this in your Supabase SQL Editor to allow user app to read all vendor data

-- Allow anonymous users to read all active services from all vendors
CREATE POLICY "Anonymous users can view active services" ON services
    FOR SELECT USING (is_active = true);

-- Allow anonymous users to read all categories from all vendors
CREATE POLICY "Anonymous users can view all categories" ON categories
    FOR SELECT USING (true);

-- Optional: Allow anonymous users to read vendor profiles for service attribution
CREATE POLICY "Anonymous users can view vendor profiles" ON vendor_profiles
    FOR SELECT USING (true);

-- Note: These policies work alongside existing vendor policies
-- Vendors can still manage their own data, but users can now see all active content
