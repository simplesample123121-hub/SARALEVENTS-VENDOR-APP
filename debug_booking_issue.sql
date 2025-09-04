-- Debug Booking Issue - Check Current State
-- Run this in your Supabase SQL Editor to see what's happening

-- 1. Check all bookings
SELECT 
    b.id as booking_id,
    b.user_id,
    b.service_id,
    b.vendor_id,
    b.status,
    b.amount,
    b.created_at,
    s.name as service_name,
    vp.business_name as vendor_name,
    up.first_name || ' ' || up.last_name as customer_name
FROM bookings b
LEFT JOIN services s ON b.service_id = s.id
LEFT JOIN vendor_profiles vp ON b.vendor_id = vp.id
LEFT JOIN user_profiles up ON b.user_id = up.user_id
ORDER BY b.created_at DESC;

-- 2. Check all services and their vendor assignments
SELECT 
    s.id as service_id,
    s.name as service_name,
    s.vendor_id,
    s.is_active,
    s.is_visible_to_users,
    vp.business_name as vendor_name,
    vp.user_id as vendor_user_id
FROM services s
LEFT JOIN vendor_profiles vp ON s.vendor_id = vp.id
ORDER BY s.created_at DESC;

-- 3. Check vendor profiles
SELECT 
    vp.id as vendor_id,
    vp.business_name,
    vp.user_id,
    u.email as vendor_email
FROM vendor_profiles vp
LEFT JOIN auth.users u ON vp.user_id = u.id;

-- 4. Check if there are any RLS issues
-- This will show what the current user can see
SELECT 
    'Current user can see these bookings:' as info,
    COUNT(*) as count
FROM bookings;

-- 5. Check specific vendor's bookings (replace with actual vendor ID)
-- First, get a vendor ID from the above queries, then run:
-- SELECT * FROM bookings WHERE vendor_id = 'actual-vendor-id-here';
