-- Fix Vendor Orders Visibility Issue
-- Run this in your Supabase SQL Editor

-- 1. First, let's check the current state
SELECT 
    'Current state check:' as info,
    COUNT(*) as total_bookings
FROM bookings;

-- 2. Check what vendor the current user is
SELECT 
    'Current user vendor profile:' as info,
    vp.id as vendor_id,
    vp.business_name,
    vp.user_id
FROM vendor_profiles vp
WHERE vp.user_id = auth.uid();

-- 3. Check if the vendor can see their bookings with current RLS
SELECT 
    'Bookings visible to current vendor:' as info,
    COUNT(*) as visible_bookings
FROM bookings b
WHERE b.vendor_id = (
    SELECT vp.id 
    FROM vendor_profiles vp 
    WHERE vp.user_id = auth.uid()
);

-- 4. Check all bookings and their vendor assignments
SELECT 
    b.id as booking_id,
    b.vendor_id as booking_vendor_id,
    b.service_id,
    b.status,
    s.vendor_id as service_vendor_id,
    vp.business_name as vendor_name,
    vp.user_id as vendor_user_id
FROM bookings b
LEFT JOIN services s ON b.service_id = s.id
LEFT JOIN vendor_profiles vp ON b.vendor_id = vp.id
ORDER BY b.created_at DESC;

-- 5. Fix RLS policies for vendor bookings visibility
-- Drop existing policies
DROP POLICY IF EXISTS "Vendors can view bookings for their services" ON bookings;
DROP POLICY IF EXISTS "Vendors can update booking status for their services" ON bookings;

-- Create new policies that check vendor_id directly
CREATE POLICY "Vendors can view bookings for their services" ON bookings
    FOR SELECT USING (
        vendor_id IN (
            SELECT vp.id 
            FROM vendor_profiles vp 
            WHERE vp.user_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can update booking status for their services" ON bookings
    FOR UPDATE USING (
        vendor_id IN (
            SELECT vp.id 
            FROM vendor_profiles vp 
            WHERE vp.user_id = auth.uid()
        )
    );

-- 6. Test the fix
SELECT 
    'After fix - bookings visible to current vendor:' as info,
    COUNT(*) as visible_bookings
FROM bookings b
WHERE b.vendor_id = (
    SELECT vp.id 
    FROM vendor_profiles vp 
    WHERE vp.user_id = auth.uid()
);
