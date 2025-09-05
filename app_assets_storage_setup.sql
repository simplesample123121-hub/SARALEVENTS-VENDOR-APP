-- App Assets Storage Setup for Saral Events
-- Storage buckets for default images and media assets for user, vendor, and company apps

-- 1. Create storage buckets for each application
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('user-app-assets', 'user-app-assets', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']),
  ('vendor-app-assets', 'vendor-app-assets', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']),
  ('company-app-assets', 'company-app-assets', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'])
ON CONFLICT (id) DO NOTHING;

-- 2. Create RLS policies for user-app-assets bucket
CREATE POLICY "user_app_assets_select" ON storage.objects FOR SELECT USING (bucket_id = 'user-app-assets');
CREATE POLICY "user_app_assets_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'user-app-assets');
CREATE POLICY "user_app_assets_update" ON storage.objects FOR UPDATE USING (bucket_id = 'user-app-assets');
CREATE POLICY "user_app_assets_delete" ON storage.objects FOR DELETE USING (bucket_id = 'user-app-assets');

-- 3. Create RLS policies for vendor-app-assets bucket
CREATE POLICY "vendor_app_assets_select" ON storage.objects FOR SELECT USING (bucket_id = 'vendor-app-assets');
CREATE POLICY "vendor_app_assets_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'vendor-app-assets');
CREATE POLICY "vendor_app_assets_update" ON storage.objects FOR UPDATE USING (bucket_id = 'vendor-app-assets');
CREATE POLICY "vendor_app_assets_delete" ON storage.objects FOR DELETE USING (bucket_id = 'vendor-app-assets');

-- 4. Create RLS policies for company-app-assets bucket
CREATE POLICY "company_app_assets_select" ON storage.objects FOR SELECT USING (bucket_id = 'company-app-assets');
CREATE POLICY "company_app_assets_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'company-app-assets');
CREATE POLICY "company_app_assets_update" ON storage.objects FOR UPDATE USING (bucket_id = 'company-app-assets');
CREATE POLICY "company_app_assets_delete" ON storage.objects FOR DELETE USING (bucket_id = 'company-app-assets');

-- 5. Create a table to manage app assets metadata
CREATE TABLE IF NOT EXISTS public.app_assets (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  app_type text NOT NULL CHECK (app_type IN ('user', 'vendor', 'company')),
  asset_type text NOT NULL CHECK (asset_type IN ('image', 'icon', 'banner', 'logo', 'background', 'pattern', 'placeholder')),
  asset_name text NOT NULL,
  asset_path text NOT NULL,
  bucket_name text NOT NULL,
  file_size bigint,
  mime_type text,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_app_assets_app_type ON public.app_assets(app_type);
CREATE INDEX IF NOT EXISTS idx_app_assets_asset_type ON public.app_assets(asset_type);
CREATE INDEX IF NOT EXISTS idx_app_assets_active ON public.app_assets(is_active);

-- 7. Create updated_at trigger for app_assets table
CREATE TRIGGER update_app_assets_updated_at 
  BEFORE UPDATE ON public.app_assets 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Enable RLS on app_assets table
ALTER TABLE public.app_assets ENABLE ROW LEVEL SECURITY;

-- 9. Create RLS policies for app_assets table (open access for now)
CREATE POLICY "app_assets_select" ON public.app_assets FOR SELECT USING (true);
CREATE POLICY "app_assets_insert" ON public.app_assets FOR INSERT WITH CHECK (true);
CREATE POLICY "app_assets_update" ON public.app_assets FOR UPDATE USING (true);
CREATE POLICY "app_assets_delete" ON public.app_assets FOR DELETE USING (true);

-- 10. Insert default asset records (these will be populated when you upload actual assets)
INSERT INTO public.app_assets (app_type, asset_type, asset_name, asset_path, bucket_name, description) VALUES
-- User App Assets
('user', 'banner', 'hero_banner', 'banners/hero_banner.jpg', 'user-app-assets', 'Main hero banner for user app home screen'),
('user', 'icon', 'photography_icon', 'icons/photography.png', 'user-app-assets', 'Photography category icon'),
('user', 'icon', 'decoration_icon', 'icons/decoration.png', 'user-app-assets', 'Decoration category icon'),
('user', 'icon', 'catering_icon', 'icons/catering.png', 'user-app-assets', 'Catering category icon'),
('user', 'icon', 'farmhouse_icon', 'icons/farmhouse.png', 'user-app-assets', 'Farmhouse category icon'),
('user', 'icon', 'music_dj_icon', 'icons/music_dj.png', 'user-app-assets', 'Music DJ category icon'),
('user', 'icon', 'venue_icon', 'icons/venue.png', 'user-app-assets', 'Venue category icon'),
('user', 'icon', 'event_essentials_icon', 'icons/event_essentials.png', 'user-app-assets', 'Event essentials category icon'),
('user', 'pattern', 'henna_pattern', 'patterns/henna_pattern.png', 'user-app-assets', 'Henna pattern for background decoration'),
('user', 'placeholder', 'service_placeholder', 'placeholders/service_placeholder.jpg', 'user-app-assets', 'Default placeholder for services'),

-- Vendor App Assets
('vendor', 'logo', 'vendor_logo', 'logos/vendor_logo.png', 'vendor-app-assets', 'Default vendor app logo'),
('vendor', 'icon', 'calendar_icon', 'icons/calendar.png', 'vendor-app-assets', 'Calendar availability icon'),
('vendor', 'icon', 'service_icon', 'icons/service.png', 'vendor-app-assets', 'Service management icon'),
('vendor', 'icon', 'profile_icon', 'icons/profile.png', 'vendor-app-assets', 'Profile management icon'),
('vendor', 'placeholder', 'service_image_placeholder', 'placeholders/service_image_placeholder.jpg', 'vendor-app-assets', 'Default placeholder for service images'),
('vendor', 'background', 'login_background', 'backgrounds/login_background.jpg', 'vendor-app-assets', 'Login screen background'),

-- Company App Assets
('company', 'logo', 'company_logo', 'logos/company_logo.png', 'company-app-assets', 'Main company logo'),
('company', 'banner', 'admin_banner', 'banners/admin_banner.jpg', 'company-app-assets', 'Admin dashboard banner'),
('company', 'icon', 'dashboard_icon', 'icons/dashboard.png', 'company-app-assets', 'Dashboard icon'),
('company', 'icon', 'analytics_icon', 'icons/analytics.png', 'company-app-assets', 'Analytics icon'),
('company', 'icon', 'users_icon', 'icons/users.png', 'company-app-assets', 'Users management icon'),
('company', 'icon', 'vendors_icon', 'icons/vendors.png', 'company-app-assets', 'Vendors management icon'),
('company', 'background', 'admin_background', 'backgrounds/admin_background.jpg', 'company-app-assets', 'Admin panel background')
ON CONFLICT DO NOTHING;

-- 11. Create a function to get assets by app type and asset type
CREATE OR REPLACE FUNCTION get_app_assets(
  p_app_type text,
  p_asset_type text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  asset_name text,
  asset_path text,
  bucket_name text,
  file_size bigint,
  mime_type text,
  description text,
  created_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    aa.id,
    aa.asset_name,
    aa.asset_path,
    aa.bucket_name,
    aa.file_size,
    aa.mime_type,
    aa.description,
    aa.created_at
  FROM public.app_assets aa
  WHERE aa.app_type = p_app_type
    AND aa.is_active = true
    AND (p_asset_type IS NULL OR aa.asset_type = p_asset_type)
  ORDER BY aa.asset_name;
END;
$$ LANGUAGE plpgsql;

-- 12. Create a function to get asset URL
CREATE OR REPLACE FUNCTION get_asset_url(
  p_bucket_name text,
  p_asset_path text
)
RETURNS text AS $$
BEGIN
  RETURN 'https://your-project-ref.supabase.co/storage/v1/object/public/' || p_bucket_name || '/' || p_asset_path;
END;
$$ LANGUAGE plpgsql;
