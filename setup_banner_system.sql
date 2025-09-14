-- Banner Management System Setup for Saral Events
-- This script sets up the complete banner management infrastructure

-- 1. Ensure the app_assets table exists (from app_assets_storage_setup.sql)
-- Run app_assets_storage_setup.sql first if not already done

-- 2. Insert a sample banner record for testing
INSERT INTO public.app_assets (
  app_type, 
  asset_type, 
  asset_name, 
  asset_path, 
  bucket_name, 
  description, 
  is_active
) VALUES (
  'user',
  'banner', 
  'hero_banner',
  'banners/hero_banner.jpg',
  'user-app-assets',
  'Main hero banner for user app home screen - managed by company app',
  true
) ON CONFLICT DO NOTHING;

-- 3. Create a function to get the current hero banner URL
CREATE OR REPLACE FUNCTION get_hero_banner_url()
RETURNS text AS $$
DECLARE
  banner_record RECORD;
  base_url text := 'https://your-project-ref.supabase.co/storage/v1/object/public/';
BEGIN
  -- Try to get the specific hero banner first
  SELECT asset_path, bucket_name INTO banner_record
  FROM public.app_assets 
  WHERE app_type = 'user' 
    AND asset_type = 'banner' 
    AND asset_name = 'hero_banner'
    AND is_active = true
  LIMIT 1;
  
  -- If hero banner exists, return its URL
  IF FOUND THEN
    RETURN base_url || banner_record.bucket_name || '/' || banner_record.asset_path;
  END IF;
  
  -- Fallback to any active banner
  SELECT asset_path, bucket_name INTO banner_record
  FROM public.app_assets 
  WHERE app_type = 'user' 
    AND asset_type = 'banner' 
    AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- If any banner exists, return its URL
  IF FOUND THEN
    RETURN base_url || banner_record.bucket_name || '/' || banner_record.asset_path;
  END IF;
  
  -- Ultimate fallback
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a function to get all active banners for carousel
CREATE OR REPLACE FUNCTION get_active_banners()
RETURNS TABLE (
  id uuid,
  asset_name text,
  asset_path text,
  bucket_name text,
  description text,
  created_at timestamp with time zone,
  image_url text
) AS $$
DECLARE
  base_url text := 'https://your-project-ref.supabase.co/storage/v1/object/public/';
BEGIN
  RETURN QUERY
  SELECT 
    aa.id,
    aa.asset_name,
    aa.asset_path,
    aa.bucket_name,
    aa.description,
    aa.created_at,
    (base_url || aa.bucket_name || '/' || aa.asset_path) as image_url
  FROM public.app_assets aa
  WHERE aa.app_type = 'user'
    AND aa.asset_type = 'banner'
    AND aa.is_active = true
  ORDER BY aa.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. Create an index for better performance on banner queries
CREATE INDEX IF NOT EXISTS idx_app_assets_user_banners 
ON public.app_assets(app_type, asset_type, is_active) 
WHERE app_type = 'user' AND asset_type = 'banner';

-- 6. Create a trigger to automatically update the updated_at timestamp
-- (This should already exist from app_assets_storage_setup.sql)

-- 7. Grant necessary permissions (adjust as needed for your setup)
-- These are already handled by the RLS policies in app_assets_storage_setup.sql

-- 8. Test the functions
SELECT 'Testing banner functions:' as status;
SELECT get_hero_banner_url() as hero_banner_url;
SELECT * FROM get_active_banners();

-- 9. Show current banner status
SELECT 
  asset_name,
  description,
  is_active,
  created_at,
  'https://your-project-ref.supabase.co/storage/v1/object/public/' || bucket_name || '/' || asset_path as full_url
FROM public.app_assets 
WHERE app_type = 'user' AND asset_type = 'banner'
ORDER BY created_at DESC;

-- Instructions:
-- 1. Replace 'your-project-ref' with your actual Supabase project reference
-- 2. Run app_assets_storage_setup.sql first if not already done
-- 3. Upload banner images through the company web app at /dashboard/banners
-- 4. The user app will automatically fetch and display the banners