-- Fix Booking Issue - Comprehensive Solution (Version 2)
-- Run this in your Supabase SQL Editor

-- 1. First, let's check and fix the services table structure
-- Ensure services table has vendor_id column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'services' AND column_name = 'vendor_id'
    ) THEN
        ALTER TABLE services ADD COLUMN vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Let's see what columns exist in the services table
-- This will help us understand the current structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'services' 
ORDER BY ordinal_position;

-- 3. Update existing services to have vendor_id if they don't have it
-- We'll assign them to the first available vendor for now
UPDATE services 
SET vendor_id = (
    SELECT vp.id 
    FROM vendor_profiles vp 
    LIMIT 1
)
WHERE vendor_id IS NULL;

-- 4. Ensure the visibility column exists
ALTER TABLE services ADD COLUMN IF NOT EXISTS is_visible_to_users BOOLEAN DEFAULT true;

-- 5. Update all existing services to be visible to users
UPDATE services SET is_visible_to_users = true WHERE is_visible_to_users IS NULL;

-- 6. Create bookings table if it doesn't exist
CREATE TABLE IF NOT EXISTS bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    booking_time TIME,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    amount DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create booking_status_updates table if it doesn't exist
CREATE TABLE IF NOT EXISTS booking_status_updates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    updated_by UUID NOT NULL REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Enable RLS on tables
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_status_updates ENABLE ROW LEVEL SECURITY;

-- 9. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create their own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
DROP POLICY IF EXISTS "Vendors can view bookings for their services" ON bookings;
DROP POLICY IF EXISTS "Vendors can update booking status for their services" ON bookings;

DROP POLICY IF EXISTS "Users can view status updates for their bookings" ON booking_status_updates;
DROP POLICY IF EXISTS "Vendors can view status updates for their service bookings" ON booking_status_updates;
DROP POLICY IF EXISTS "Vendors can create status updates for their service bookings" ON booking_status_updates;

-- 10. Create RLS Policies for bookings table
CREATE POLICY "Users can view their own bookings" ON bookings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own bookings" ON bookings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bookings" ON bookings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Vendors can view bookings for their services" ON bookings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM services s 
            WHERE s.id = bookings.service_id 
            AND s.vendor_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can update booking status for their services" ON bookings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM services s 
            WHERE s.id = bookings.service_id 
            AND s.vendor_id = auth.uid()
        )
    );

-- 11. Create RLS Policies for booking_status_updates table
CREATE POLICY "Users can view status updates for their bookings" ON booking_status_updates
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings b 
            WHERE b.id = booking_status_updates.booking_id 
            AND b.user_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can view status updates for their service bookings" ON booking_status_updates
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings b 
            JOIN services s ON b.service_id = s.id
            WHERE b.id = booking_status_updates.booking_id 
            AND s.vendor_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can create status updates for their service bookings" ON booking_status_updates
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM bookings b 
            JOIN services s ON b.service_id = s.id
            WHERE b.id = booking_status_updates.booking_id 
            AND s.vendor_id = auth.uid()
        )
    );

-- 12. Update services RLS policy to allow viewing
DROP POLICY IF EXISTS "Anonymous users can view active and visible services" ON services;
DROP POLICY IF EXISTS "Anonymous users can view active services" ON services;
DROP POLICY IF EXISTS "Authenticated users can view active services" ON services;

CREATE POLICY "Anonymous users can view active services" ON services
    FOR SELECT USING (is_active = true);

CREATE POLICY "Authenticated users can view active services" ON services
    FOR SELECT USING (is_active = true);

-- 13. Create function to automatically create status update when booking status changes
CREATE OR REPLACE FUNCTION create_booking_status_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO booking_status_updates (booking_id, status, updated_by, notes)
        VALUES (NEW.id, NEW.status, auth.uid(), 'Status updated from ' || OLD.status || ' to ' || NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 14. Create trigger for automatic status updates
DROP TRIGGER IF EXISTS booking_status_update_trigger ON bookings;
CREATE TRIGGER booking_status_update_trigger
    AFTER UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION create_booking_status_update();

-- 15. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_service_id ON bookings(service_id);
CREATE INDEX IF NOT EXISTS idx_bookings_vendor_id ON bookings(vendor_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_services_visible ON services(is_visible_to_users);
CREATE INDEX IF NOT EXISTS idx_services_vendor_id ON services(vendor_id);

-- 16. Create view for vendor dashboard
CREATE OR REPLACE VIEW vendor_bookings_view AS
SELECT 
    b.id as booking_id,
    b.booking_date,
    b.booking_time,
    b.status,
    b.amount,
    b.notes,
    b.created_at,
    s.name as service_name,
    s.id as service_id,
    up.first_name || ' ' || up.last_name as customer_name,
    up.email as customer_email,
    up.phone_number as customer_phone
FROM bookings b
JOIN services s ON b.service_id = s.id
JOIN user_profiles up ON b.user_id = up.user_id
WHERE s.vendor_id = auth.uid()
ORDER BY b.created_at DESC;

-- Grant access to the view
GRANT SELECT ON vendor_bookings_view TO authenticated;

-- 17. Create function to get user's booking history
CREATE OR REPLACE FUNCTION get_user_bookings(user_uuid UUID)
RETURNS TABLE (
    booking_id UUID,
    service_name TEXT,
    vendor_name TEXT,
    booking_date DATE,
    booking_time TIME,
    status TEXT,
    amount DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        s.name,
        vp.business_name,
        b.booking_date,
        b.booking_time,
        b.status,
        b.amount,
        b.created_at
    FROM bookings b
    JOIN services s ON b.service_id = s.id
    JOIN vendor_profiles vp ON s.vendor_id = vp.id
    WHERE b.user_id = user_uuid
    ORDER BY b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_bookings(UUID) TO authenticated;

-- 18. Ensure vendor_profiles table has proper RLS
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Vendors can view own profile" ON vendor_profiles;
CREATE POLICY "Vendors can view own profile" ON vendor_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- 19. Ensure user_profiles table has proper RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- 20. Create a function to get vendor_id from service_id
CREATE OR REPLACE FUNCTION get_vendor_id_from_service(service_uuid UUID)
RETURNS UUID AS $$
DECLARE
    vendor_uuid UUID;
BEGIN
    SELECT vendor_id INTO vendor_uuid
    FROM services
    WHERE id = service_uuid;
    
    RETURN vendor_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_vendor_id_from_service(UUID) TO authenticated;

-- 21. Show current services and their vendor assignments
SELECT 
    s.id as service_id,
    s.name as service_name,
    s.vendor_id,
    vp.business_name as vendor_name
FROM services s
LEFT JOIN vendor_profiles vp ON s.vendor_id = vp.id
ORDER BY s.created_at DESC
LIMIT 10;
