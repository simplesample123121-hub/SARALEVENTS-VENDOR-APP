-- Database Schema Updates for Saral Events
-- Connect allServicesFull with vendor_profiles and create category-specific tables

-- 1. vendor_id already exists in allServicesFull table, so we just create index for better performance
CREATE INDEX IF NOT EXISTS idx_allServicesFull_vendor_id ON public."allServicesFull"(vendor_id);

-- 2. Add vendor_id to existing category-specific tables (they already exist)

-- Add vendor_id to photographyServices if not exists
ALTER TABLE public."photographyServices" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- Add vendor_id to cateringServices if not exists  
ALTER TABLE public."cateringServices" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- Add vendor_id to decorServices if not exists
ALTER TABLE public."decorServices" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- Add vendor_id to eventEssentials if not exists
ALTER TABLE public."eventEssentials" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- Add vendor_id to farmhouseServices if not exists
ALTER TABLE public."farmhouseServices" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- Add vendor_id to musicDjServices if not exists
ALTER TABLE public."musicDjServices" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- Add vendor_id to venueservice if not exists
ALTER TABLE public."venueservice" 
ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendor_profiles(id) ON DELETE CASCADE;

-- 3. Create indexes for all category tables
CREATE INDEX IF NOT EXISTS idx_photographyServices_vendor_id ON public."photographyServices"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_decorServices_vendor_id ON public."decorServices"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_cateringServices_vendor_id ON public."cateringServices"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_farmhouseServices_vendor_id ON public."farmhouseServices"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_musicDjServices_vendor_id ON public."musicDjServices"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_venueservice_vendor_id ON public."venueservice"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_eventEssentials_vendor_id ON public."eventEssentials"(vendor_id);

-- 4. Create updated_at triggers for all tables
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all category tables (drop first if they exist)
DROP TRIGGER IF EXISTS update_photographyServices_updated_at ON public."photographyServices";
DROP TRIGGER IF EXISTS update_decorServices_updated_at ON public."decorServices";
DROP TRIGGER IF EXISTS update_cateringServices_updated_at ON public."cateringServices";
DROP TRIGGER IF EXISTS update_farmhouseServices_updated_at ON public."farmhouseServices";
DROP TRIGGER IF EXISTS update_musicDjServices_updated_at ON public."musicDjServices";
DROP TRIGGER IF EXISTS update_venueservice_updated_at ON public."venueservice";
DROP TRIGGER IF EXISTS update_eventEssentials_updated_at ON public."eventEssentials";

CREATE TRIGGER update_photographyServices_updated_at BEFORE UPDATE ON public."photographyServices" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_decorServices_updated_at BEFORE UPDATE ON public."decorServices" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cateringServices_updated_at BEFORE UPDATE ON public."cateringServices" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_farmhouseServices_updated_at BEFORE UPDATE ON public."farmhouseServices" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_musicDjServices_updated_at BEFORE UPDATE ON public."musicDjServices" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_venueservice_updated_at BEFORE UPDATE ON public."venueservice" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_eventEssentials_updated_at BEFORE UPDATE ON public."eventEssentials" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Enable RLS on all tables
ALTER TABLE public."photographyServices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."decorServices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."cateringServices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."farmhouseServices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."musicDjServices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."venueservice" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."eventEssentials" ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for all category tables (open access for now)
-- Drop existing policies first to avoid conflicts

-- Photography Services
DROP POLICY IF EXISTS "photographyServices_select" ON public."photographyServices";
DROP POLICY IF EXISTS "photographyServices_insert" ON public."photographyServices";
DROP POLICY IF EXISTS "photographyServices_update" ON public."photographyServices";
DROP POLICY IF EXISTS "photographyServices_delete" ON public."photographyServices";
CREATE POLICY "photographyServices_select" ON public."photographyServices" FOR SELECT USING (true);
CREATE POLICY "photographyServices_insert" ON public."photographyServices" FOR INSERT WITH CHECK (true);
CREATE POLICY "photographyServices_update" ON public."photographyServices" FOR UPDATE USING (true);
CREATE POLICY "photographyServices_delete" ON public."photographyServices" FOR DELETE USING (true);

-- Decor Services
DROP POLICY IF EXISTS "decorServices_select" ON public."decorServices";
DROP POLICY IF EXISTS "decorServices_insert" ON public."decorServices";
DROP POLICY IF EXISTS "decorServices_update" ON public."decorServices";
DROP POLICY IF EXISTS "decorServices_delete" ON public."decorServices";
CREATE POLICY "decorServices_select" ON public."decorServices" FOR SELECT USING (true);
CREATE POLICY "decorServices_insert" ON public."decorServices" FOR INSERT WITH CHECK (true);
CREATE POLICY "decorServices_update" ON public."decorServices" FOR UPDATE USING (true);
CREATE POLICY "decorServices_delete" ON public."decorServices" FOR DELETE USING (true);

-- Catering Services
DROP POLICY IF EXISTS "cateringServices_select" ON public."cateringServices";
DROP POLICY IF EXISTS "cateringServices_insert" ON public."cateringServices";
DROP POLICY IF EXISTS "cateringServices_update" ON public."cateringServices";
DROP POLICY IF EXISTS "cateringServices_delete" ON public."cateringServices";
CREATE POLICY "cateringServices_select" ON public."cateringServices" FOR SELECT USING (true);
CREATE POLICY "cateringServices_insert" ON public."cateringServices" FOR INSERT WITH CHECK (true);
CREATE POLICY "cateringServices_update" ON public."cateringServices" FOR UPDATE USING (true);
CREATE POLICY "cateringServices_delete" ON public."cateringServices" FOR DELETE USING (true);

-- Farmhouse Services
DROP POLICY IF EXISTS "farmhouseServices_select" ON public."farmhouseServices";
DROP POLICY IF EXISTS "farmhouseServices_insert" ON public."farmhouseServices";
DROP POLICY IF EXISTS "farmhouseServices_update" ON public."farmhouseServices";
DROP POLICY IF EXISTS "farmhouseServices_delete" ON public."farmhouseServices";
CREATE POLICY "farmhouseServices_select" ON public."farmhouseServices" FOR SELECT USING (true);
CREATE POLICY "farmhouseServices_insert" ON public."farmhouseServices" FOR INSERT WITH CHECK (true);
CREATE POLICY "farmhouseServices_update" ON public."farmhouseServices" FOR UPDATE USING (true);
CREATE POLICY "farmhouseServices_delete" ON public."farmhouseServices" FOR DELETE USING (true);

-- Music DJ Services
DROP POLICY IF EXISTS "musicDjServices_select" ON public."musicDjServices";
DROP POLICY IF EXISTS "musicDjServices_insert" ON public."musicDjServices";
DROP POLICY IF EXISTS "musicDjServices_update" ON public."musicDjServices";
DROP POLICY IF EXISTS "musicDjServices_delete" ON public."musicDjServices";
CREATE POLICY "musicDjServices_select" ON public."musicDjServices" FOR SELECT USING (true);
CREATE POLICY "musicDjServices_insert" ON public."musicDjServices" FOR INSERT WITH CHECK (true);
CREATE POLICY "musicDjServices_update" ON public."musicDjServices" FOR UPDATE USING (true);
CREATE POLICY "musicDjServices_delete" ON public."musicDjServices" FOR DELETE USING (true);

-- Venue Services
DROP POLICY IF EXISTS "venueservice_select" ON public."venueservice";
DROP POLICY IF EXISTS "venueservice_insert" ON public."venueservice";
DROP POLICY IF EXISTS "venueservice_update" ON public."venueservice";
DROP POLICY IF EXISTS "venueservice_delete" ON public."venueservice";
CREATE POLICY "venueservice_select" ON public."venueservice" FOR SELECT USING (true);
CREATE POLICY "venueservice_insert" ON public."venueservice" FOR INSERT WITH CHECK (true);
CREATE POLICY "venueservice_update" ON public."venueservice" FOR UPDATE USING (true);
CREATE POLICY "venueservice_delete" ON public."venueservice" FOR DELETE USING (true);

-- Event Essentials
DROP POLICY IF EXISTS "eventEssentials_select" ON public."eventEssentials";
DROP POLICY IF EXISTS "eventEssentials_insert" ON public."eventEssentials";
DROP POLICY IF EXISTS "eventEssentials_update" ON public."eventEssentials";
DROP POLICY IF EXISTS "eventEssentials_delete" ON public."eventEssentials";
CREATE POLICY "eventEssentials_select" ON public."eventEssentials" FOR SELECT USING (true);
CREATE POLICY "eventEssentials_insert" ON public."eventEssentials" FOR INSERT WITH CHECK (true);
CREATE POLICY "eventEssentials_update" ON public."eventEssentials" FOR UPDATE USING (true);
CREATE POLICY "eventEssentials_delete" ON public."eventEssentials" FOR DELETE USING (true);

-- 7. service_type already exists in allServicesFull table, no need to add it

-- 8. Create a view to connect vendor_profiles with allServicesFull based on category
CREATE OR REPLACE VIEW public.vendor_services_view AS
SELECT 
    vp.id as vendor_id,
    vp.business_name,
    vp.category,
    vp.user_id,
    vp.created_at as vendor_created_at,
    asf.id as service_id,
    asf.service_name,
    asf.service_type
FROM public.vendor_profiles vp
LEFT JOIN public."allServicesFull" asf ON vp.id = asf.vendor_id 
    AND vp.category = asf.service_type;

-- 9. Create a function to get services by category with vendor info
CREATE OR REPLACE FUNCTION get_services_by_category(category_name text)
RETURNS TABLE (
    vendor_id uuid,
    business_name text,
    category text,
    service_id uuid,
    service_name text,
    service_type text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vp.id,
        vp.business_name,
        vp.category,
        asf.id,
        asf.service_name,
        asf.service_type
    FROM public.vendor_profiles vp
    JOIN public."allServicesFull" asf ON vp.id = asf.vendor_id
    WHERE vp.category = category_name 
        AND asf.service_type = category_name;
END;
$$ LANGUAGE plpgsql;
