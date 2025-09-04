-- Vendor Role-Based Authentication Schema
-- Run this in your Supabase SQL Editor to enable vendor role separation

-- Update existing vendor_profiles to include role assignment
-- First, ensure all existing vendors have 'vendor' role
INSERT INTO user_roles (user_id, role)
SELECT user_id, 'vendor' 
FROM vendor_profiles 
WHERE user_id NOT IN (SELECT user_id FROM user_roles WHERE role = 'vendor')
ON CONFLICT (user_id, role) DO NOTHING;

-- Function to check if user is a vendor
CREATE OR REPLACE FUNCTION is_vendor(user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM user_roles WHERE user_id = user_uuid AND role = 'vendor');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update vendor_profiles RLS to check vendor role
DROP POLICY IF EXISTS "Users can view own vendor profile" ON vendor_profiles;
CREATE POLICY "Vendors can view own profile" ON vendor_profiles
    FOR SELECT USING (auth.uid() = user_id AND is_vendor(auth.uid()));

DROP POLICY IF EXISTS "Users can insert own vendor profile" ON vendor_profiles;
CREATE POLICY "Vendors can insert own profile" ON vendor_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id AND is_vendor(auth.uid()));

DROP POLICY IF EXISTS "Users can update own vendor profile" ON vendor_profiles;
CREATE POLICY "Vendors can update own profile" ON vendor_profiles
    FOR UPDATE USING (auth.uid() = user_id AND is_vendor(auth.uid()));

DROP POLICY IF EXISTS "Users can delete own vendor profile" ON vendor_profiles;
CREATE POLICY "Vendors can delete own profile" ON vendor_profiles
    FOR DELETE USING (auth.uid() = user_id AND is_vendor(auth.uid()));

-- Update vendor_documents RLS to check vendor role
DROP POLICY IF EXISTS "Users can view own vendor documents" ON vendor_documents;
CREATE POLICY "Vendors can view own documents" ON vendor_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE id = vendor_documents.vendor_id 
            AND user_id = auth.uid()
            AND is_vendor(auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can insert own vendor documents" ON vendor_documents;
CREATE POLICY "Vendors can insert own documents" ON vendor_documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE id = vendor_documents.vendor_id 
            AND user_id = auth.uid()
            AND is_vendor(auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can delete own vendor documents" ON vendor_documents;
CREATE POLICY "Vendors can delete own documents" ON vendor_documents
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE id = vendor_documents.vendor_id 
            AND user_id = auth.uid()
            AND is_vendor(auth.uid())
        )
    );
