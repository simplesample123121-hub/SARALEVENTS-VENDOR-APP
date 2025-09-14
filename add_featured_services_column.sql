-- Add is_featured column to services table for featured events functionality
-- This script is safe to run multiple times

-- 1. Add is_featured column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'services' 
        AND column_name = 'is_featured'
    ) THEN
        ALTER TABLE public.services 
        ADD COLUMN is_featured boolean DEFAULT false;
        
        RAISE NOTICE 'Added is_featured column to services table';
    ELSE
        RAISE NOTICE 'is_featured column already exists in services table';
    END IF;
END $$;

-- 2. Create index for better performance on featured services queries
CREATE INDEX IF NOT EXISTS idx_services_featured 
ON public.services(is_featured, is_active, is_visible_to_users) 
WHERE is_featured = true AND is_active = true AND is_visible_to_users = true;

-- 3. Update some existing services to be featured (optional - for testing)
-- Uncomment the lines below if you want to mark some services as featured for testing

/*
UPDATE public.services 
SET is_featured = true 
WHERE is_active = true 
  AND is_visible_to_users = true 
  AND id IN (
    SELECT id FROM public.services 
    WHERE is_active = true 
      AND is_visible_to_users = true 
    ORDER BY updated_at DESC 
    LIMIT 5
  );
*/

-- 4. Create a function to get featured services with vendor info
CREATE OR REPLACE FUNCTION get_featured_services(
  p_limit integer DEFAULT 12
)
RETURNS TABLE (
  id uuid,
  name text,
  price numeric,
  description text,
  media_urls text[],
  vendor_id uuid,
  vendor_name text,
  category_id text,
  tags text[],
  rating_avg numeric,
  rating_count integer,
  capacity_min integer,
  capacity_max integer,
  suited_for text[],
  features jsonb,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    s.price,
    s.description,
    s.media_urls,
    s.vendor_id,
    COALESCE(vp.business_name, 'Unknown Vendor') as vendor_name,
    s.category_id,
    s.tags,
    s.rating_avg,
    s.rating_count,
    s.capacity_min,
    s.capacity_max,
    s.suited_for,
    s.features,
    s.created_at,
    s.updated_at
  FROM public.services s
  LEFT JOIN public.vendor_profiles vp ON s.vendor_id = vp.id
  WHERE s.is_active = true
    AND s.is_visible_to_users = true
    AND s.is_featured = true
  ORDER BY s.updated_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 5. Test the function
SELECT 'Testing get_featured_services function:' as status;
SELECT COUNT(*) as featured_services_count FROM get_featured_services(10);

-- 6. Show current featured services status
SELECT 
  COUNT(*) as total_services,
  COUNT(CASE WHEN is_featured = true THEN 1 END) as featured_services,
  COUNT(CASE WHEN is_active = true AND is_visible_to_users = true THEN 1 END) as active_visible_services
FROM public.services;

-- 7. Enable real-time for services table (if not already enabled)
-- This allows the Flutter app to receive real-time updates
ALTER PUBLICATION supabase_realtime ADD TABLE services;

-- Instructions:
-- 1. Run this script in your Supabase SQL Editor
-- 2. Go to Company App -> Dashboard -> Services
-- 3. Toggle the "Featured" checkbox for services you want to feature
-- 4. The User App will automatically show these services in the Featured Events section
-- 5. Changes will appear in real-time (within 15 seconds)