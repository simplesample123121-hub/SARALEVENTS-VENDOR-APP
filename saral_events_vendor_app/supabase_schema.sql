-- Supabase Database Schema for Vendor App
-- Run this in your Supabase SQL Editor

-- Create vendor_profiles table
CREATE TABLE IF NOT EXISTS vendor_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    business_name TEXT NOT NULL,
    address TEXT NOT NULL,
    category TEXT NOT NULL,
    phone_number TEXT,
    email TEXT,
    website TEXT,
    description TEXT,
    services TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Ensure one profile per user
    UNIQUE(user_id)
);

-- Create categories table for service categories (must be created before services)
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create services table for individual service items
CREATE TABLE IF NOT EXISTS services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    tags TEXT[] DEFAULT '{}',
    media_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create vendor_documents table
CREATE TABLE IF NOT EXISTS vendor_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE NOT NULL,
    document_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_user_id ON vendor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_category ON vendor_profiles(category);
CREATE INDEX IF NOT EXISTS idx_vendor_documents_vendor_id ON vendor_documents(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_documents_type ON vendor_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_services_vendor_id ON services(vendor_id);
CREATE INDEX IF NOT EXISTS idx_services_category_id ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_services_price ON services(price);
CREATE INDEX IF NOT EXISTS idx_categories_vendor_id ON categories(vendor_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);

-- Enable Row Level Security
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Users can view their own vendor profile
CREATE POLICY "Users can view their own vendor profile" ON vendor_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own vendor profile
CREATE POLICY "Users can insert their own vendor profile" ON vendor_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own vendor profile
CREATE POLICY "Users can update their own vendor profile" ON vendor_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own vendor profile
CREATE POLICY "Users can delete their own vendor profile" ON vendor_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Users can view documents for their vendor profile
CREATE POLICY "Users can view documents for their vendor profile" ON vendor_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = vendor_documents.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can insert documents for their vendor profile
CREATE POLICY "Users can insert documents for their vendor profile" ON vendor_documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = vendor_documents.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can update documents for their vendor profile
CREATE POLICY "Users can update documents for their vendor profile" ON vendor_documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = vendor_documents.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can delete documents for their vendor profile
CREATE POLICY "Users can delete documents for their vendor profile" ON vendor_documents
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = vendor_documents.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can view services for their vendor profile
CREATE POLICY "Users can view services for their vendor profile" ON services
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = services.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can insert services for their vendor profile
CREATE POLICY "Users can insert services for their vendor profile" ON services
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = services.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can update services for their vendor profile
CREATE POLICY "Users can update services for their vendor profile" ON services
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = services.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can delete services for their vendor profile
CREATE POLICY "Users can delete services for their vendor profile" ON services
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = services.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can view categories for their vendor profile
CREATE POLICY "Users can view categories for their vendor profile" ON categories
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = categories.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can insert categories for their vendor profile
CREATE POLICY "Users can insert categories for their vendor profile" ON categories
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = categories.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can update categories for their vendor profile
CREATE POLICY "Users can update categories for their vendor profile" ON categories
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = categories.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Users can delete categories for their vendor profile
CREATE POLICY "Users can delete categories for their vendor profile" ON categories
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE vendor_profiles.id = categories.vendor_id 
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_vendor_profiles_updated_at 
    BEFORE UPDATE ON vendor_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at 
    BEFORE UPDATE ON services 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to get vendor profile with services count
CREATE OR REPLACE FUNCTION get_vendor_profile_with_stats(user_uuid UUID)
RETURNS TABLE (
    id UUID,
    business_name TEXT,
    address TEXT,
    category TEXT,
    phone_number TEXT,
    email TEXT,
    website TEXT,
    description TEXT,
    services_count BIGINT,
    categories_count BIGINT,
    documents_count BIGINT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vp.id,
        vp.business_name,
        vp.address,
        vp.category,
        vp.phone_number,
        vp.email,
        vp.website,
        vp.description,
        COALESCE(svc_count.count, 0) as services_count,
        COALESCE(cat_count.count, 0) as categories_count,
        COALESCE(doc_count.count, 0) as documents_count,
        vp.created_at,
        vp.updated_at
    FROM vendor_profiles vp
    LEFT JOIN (
        SELECT vendor_id, COUNT(*) as count 
        FROM services 
        GROUP BY vendor_id
    ) svc_count ON vp.id = svc_count.vendor_id
    LEFT JOIN (
        SELECT vendor_id, COUNT(*) as count 
        FROM categories 
        GROUP BY vendor_id
    ) cat_count ON vp.id = cat_count.vendor_id
    LEFT JOIN (
        SELECT vendor_id, COUNT(*) as count 
        FROM vendor_documents 
        GROUP BY vendor_id
    ) doc_count ON vp.id = doc_count.vendor_id
    WHERE vp.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get vendor services with category info
CREATE OR REPLACE FUNCTION get_vendor_services(vendor_uuid UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    price DECIMAL(10,2),
    tags TEXT[],
    media_urls TEXT[],
    is_active BOOLEAN,
    category_name TEXT,
    category_id UUID,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.description,
        s.price,
        s.tags,
        s.media_urls,
        s.is_active,
        c.name as category_name,
        c.id as category_id,
        s.created_at
    FROM services s
    LEFT JOIN categories c ON s.category_id = c.id
    WHERE s.vendor_id = vendor_uuid
    ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get vendor categories with hierarchy
CREATE OR REPLACE FUNCTION get_vendor_categories_hierarchy(vendor_uuid UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    parent_id UUID,
    parent_name TEXT,
    level INTEGER,
    path TEXT,
    services_count BIGINT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE category_tree AS (
        -- Base case: root categories
        SELECT 
            c.id,
            c.name,
            c.parent_id,
            NULL::TEXT as parent_name,
            0 as level,
            c.name as path,
            COALESCE(svc_count.count, 0) as services_count,
            c.created_at
        FROM categories c
        LEFT JOIN (
            SELECT category_id, COUNT(*) as count 
            FROM services 
            GROUP BY category_id
        ) svc_count ON c.id = svc_count.category_id
        WHERE c.vendor_id = vendor_uuid AND c.parent_id IS NULL
        
        UNION ALL
        
        -- Recursive case: child categories
        SELECT 
            c.id,
            c.name,
            c.parent_id,
            ct.name as parent_name,
            ct.level + 1,
            ct.path || ' > ' || c.name as path,
            COALESCE(svc_count.count, 0) as services_count,
            c.created_at
        FROM categories c
        INNER JOIN category_tree ct ON c.parent_id = ct.id
        LEFT JOIN (
            SELECT category_id, COUNT(*) as count 
            FROM services 
            GROUP BY category_id
        ) svc_count ON c.id = svc_count.category_id
        WHERE c.vendor_id = vendor_uuid
    )
    SELECT * FROM category_tree
    ORDER BY level, name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search services by text
CREATE OR REPLACE FUNCTION search_vendor_services(
    vendor_uuid UUID,
    search_term TEXT,
    category_filter UUID DEFAULT NULL,
    price_min DECIMAL DEFAULT NULL,
    price_max DECIMAL DEFAULT NULL,
    tags_filter TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    price DECIMAL(10,2),
    tags TEXT[],
    media_urls TEXT[],
    is_active BOOLEAN,
    category_name TEXT,
    relevance_score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.description,
        s.price,
        s.tags,
        s.media_urls,
        s.is_active,
        c.name as category_name,
        (
            CASE 
                WHEN s.name ILIKE '%' || search_term || '%' THEN 3.0
                WHEN s.description ILIKE '%' || search_term || '%' THEN 2.0
                WHEN EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag ILIKE '%' || search_term || '%') THEN 1.5
                ELSE 0.0
            END
        ) as relevance_score
    FROM services s
    LEFT JOIN categories c ON s.category_id = c.id
    WHERE s.vendor_id = vendor_uuid
        AND s.is_active = true
        AND (
            s.name ILIKE '%' || search_term || '%'
            OR s.description ILIKE '%' || search_term || '%'
            OR EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag ILIKE '%' || search_term || '%')
        )
        AND (category_filter IS NULL OR s.category_id = category_filter)
        AND (price_min IS NULL OR s.price >= price_min)
        AND (price_max IS NULL OR s.price <= price_max)
        AND (
            tags_filter IS NULL 
            OR tags_filter = '{}'::TEXT[]
            OR EXISTS(SELECT 1 FROM unnest(s.tags) tag WHERE tag = ANY(tags_filter))
        )
    ORDER BY relevance_score DESC, s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create storage policies for vendor_documents bucket
CREATE POLICY "Users can upload documents to their vendor folder" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'vendor_documents' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view documents in their vendor folder" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'vendor_documents' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can update documents in their vendor folder" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'vendor_documents' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete documents in their vendor folder" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'vendor_documents' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Create composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_services_vendor_active ON services(vendor_id, is_active);
CREATE INDEX IF NOT EXISTS idx_services_category_active ON services(category_id, is_active);
CREATE INDEX IF NOT EXISTS idx_categories_vendor_parent ON categories(vendor_id, parent_id);

-- Analyze tables for better query planning
ANALYZE vendor_profiles;
ANALYZE vendor_documents;
ANALYZE services;
ANALYZE categories;
