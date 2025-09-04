-- Fix Vendor Orders - Final Comprehensive Solution
-- Run this in your Supabase SQL Editor

-- 1. First, let's check the current state
SELECT 'Current state check:' as info, COUNT(*) as total_bookings FROM bookings;

-- 2. Check vendor profiles
SELECT 'Vendor profiles:' as info, COUNT(*) as total_vendors FROM vendor_profiles;

-- 3. Check user profiles
SELECT 'User profiles:' as info, COUNT(*) as total_users FROM user_profiles;

-- 4. Drop all existing booking policies to start fresh
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create their own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
DROP POLICY IF EXISTS "Vendors can view bookings for their services" ON bookings;
DROP POLICY IF EXISTS "Vendors can update booking status for their services" ON bookings;
DROP POLICY IF EXISTS "Vendors can view bookings by vendor_id" ON bookings;
DROP POLICY IF EXISTS "Vendors can update bookings by vendor_id" ON bookings;

-- 5. Drop all existing booking_status_updates policies
DROP POLICY IF EXISTS "Users can view status updates for their bookings" ON booking_status_updates;
DROP POLICY IF EXISTS "Vendors can view status updates for their service bookings" ON booking_status_updates;
DROP POLICY IF EXISTS "Vendors can create status updates for their service bookings" ON booking_status_updates;
DROP POLICY IF EXISTS "Vendors can view status updates by vendor_id" ON booking_status_updates;
DROP POLICY IF EXISTS "Vendors can create status updates by vendor_id" ON booking_status_updates;

-- 6. Create CORRECT RLS Policies for bookings table
-- Users can view their own bookings
CREATE POLICY "Users can view their own bookings" ON bookings
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own bookings
CREATE POLICY "Users can create their own bookings" ON bookings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own bookings (for cancellation)
CREATE POLICY "Users can update their own bookings" ON bookings
    FOR UPDATE USING (auth.uid() = user_id);

-- Vendors can view bookings where they are the vendor_id
CREATE POLICY "Vendors can view bookings by vendor_id" ON bookings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles vp 
            WHERE vp.id = bookings.vendor_id 
            AND vp.user_id = auth.uid()
        )
    );

-- Vendors can update bookings where they are the vendor_id
CREATE POLICY "Vendors can update bookings by vendor_id" ON bookings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles vp 
            WHERE vp.id = bookings.vendor_id 
            AND vp.user_id = auth.uid()
        )
    );

-- 7. Create CORRECT RLS Policies for booking_status_updates table
-- Users can view status updates for their bookings
CREATE POLICY "Users can view status updates for their bookings" ON booking_status_updates
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings b 
            WHERE b.id = booking_status_updates.booking_id 
            AND b.user_id = auth.uid()
        )
    );

-- Vendors can view status updates for their bookings
CREATE POLICY "Vendors can view status updates by vendor_id" ON booking_status_updates
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings b 
            JOIN vendor_profiles vp ON b.vendor_id = vp.id
            WHERE b.id = booking_status_updates.booking_id 
            AND vp.user_id = auth.uid()
        )
    );

-- Vendors can create status updates for their bookings
CREATE POLICY "Vendors can create status updates by vendor_id" ON booking_status_updates
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM bookings b 
            JOIN vendor_profiles vp ON b.vendor_id = vp.id
            WHERE b.id = booking_status_updates.booking_id 
            AND vp.user_id = auth.uid()
        )
    );

-- 8. Ensure services table has proper RLS for viewing
DROP POLICY IF EXISTS "Anonymous users can view active services" ON services;
DROP POLICY IF EXISTS "Authenticated users can view active services" ON services;

CREATE POLICY "Authenticated users can view active services" ON services
    FOR SELECT USING (is_active = true);

-- 9. Ensure user_profiles table has proper RLS
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- 10. Ensure vendor_profiles table has proper RLS
DROP POLICY IF EXISTS "Vendors can view own profile" ON vendor_profiles;
CREATE POLICY "Vendors can view own profile" ON vendor_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- 11. Test the policies - Check what the current user can see
SELECT 
    'Current user can see these bookings:' as info,
    COUNT(*) as visible_bookings
FROM bookings b
WHERE EXISTS (
    SELECT 1 FROM vendor_profiles vp 
    WHERE vp.id = b.vendor_id 
    AND vp.user_id = auth.uid()
);

-- 12. Show current user's vendor profile
SELECT 
    'Current user vendor profile:' as info,
    vp.id as vendor_id,
    vp.business_name,
    vp.user_id
FROM vendor_profiles vp
WHERE vp.user_id = auth.uid();

-- 13. Show all bookings with vendor info
SELECT 
    'All bookings with vendor info:' as info,
    b.id as booking_id,
    b.vendor_id,
    b.status,
    b.amount,
    vp.business_name as vendor_name,
    vp.user_id as vendor_user_id
FROM bookings b
LEFT JOIN vendor_profiles vp ON b.vendor_id = vp.id
ORDER BY b.created_at DESC;
