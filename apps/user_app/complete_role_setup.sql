-- Complete Role Setup for Existing Accounts
-- Run this in your Supabase SQL Editor to set up roles for all existing accounts

-- Step 1: Create user_roles table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'vendor', 'company')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, role)
);

       -- Step 2: Create user_profiles table if it doesn't exist
       CREATE TABLE IF NOT EXISTS user_profiles (
           id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
           user_id UUID NOT NULL UNIQUE,
           first_name TEXT NOT NULL,
           last_name TEXT NOT NULL,
           phone_number TEXT,
           email TEXT,
           preferences JSONB DEFAULT '{}',
           created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
           updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
       );

-- Step 3: Add foreign key constraint if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_profiles_user_id_fkey'
    ) THEN
        ALTER TABLE user_profiles 
        ADD CONSTRAINT user_profiles_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 4: Enable RLS on tables
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies for user_roles
DROP POLICY IF EXISTS "Users can view own roles" ON user_roles;
CREATE POLICY "Users can view own roles" ON user_roles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own roles" ON user_roles;
CREATE POLICY "Users can insert own roles" ON user_roles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Step 6: Create RLS policies for user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Step 7: Assign vendor roles to existing vendors
INSERT INTO user_roles (user_id, role)
SELECT user_id, 'vendor' 
FROM vendor_profiles 
WHERE user_id NOT IN (
    SELECT user_id FROM user_roles WHERE role = 'vendor'
)
ON CONFLICT (user_id, role) DO NOTHING;

-- Step 8: Create helper functions
CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID DEFAULT auth.uid())
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT role FROM user_roles WHERE user_id = user_uuid LIMIT 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION has_role(required_role TEXT, user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM user_roles WHERE user_id = user_uuid AND role = required_role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_vendor(user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM user_roles WHERE user_id = user_uuid AND role = 'vendor');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Update vendor_profiles RLS to check vendor role
DROP POLICY IF EXISTS "Vendors can view own profile" ON vendor_profiles;
CREATE POLICY "Vendors can view own profile" ON vendor_profiles
    FOR SELECT USING (auth.uid() = user_id AND is_vendor(auth.uid()));

DROP POLICY IF EXISTS "Vendors can insert own profile" ON vendor_profiles;
CREATE POLICY "Vendors can insert own profile" ON vendor_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id AND is_vendor(auth.uid()));

DROP POLICY IF EXISTS "Vendors can update own profile" ON vendor_profiles;
CREATE POLICY "Vendors can update own profile" ON vendor_profiles
    FOR UPDATE USING (auth.uid() = user_id AND is_vendor(auth.uid()));

DROP POLICY IF EXISTS "Vendors can delete own profile" ON vendor_profiles;
CREATE POLICY "Vendors can delete own profile" ON vendor_profiles
    FOR DELETE USING (auth.uid() = user_id AND is_vendor(auth.uid()));

-- Step 10: Show results
SELECT 'Setup Complete!' as status;

-- Show all roles
SELECT 
    'All roles' as category,
    role,
    COUNT(*) as count
FROM user_roles 
GROUP BY role
ORDER BY role;

-- Show vendor details
SELECT 
    'Vendor details' as category,
    vp.business_name,
    vp.email,
    ur.role,
    ur.created_at
FROM vendor_profiles vp
LEFT JOIN user_roles ur ON vp.user_id = ur.user_id
WHERE ur.role = 'vendor'
ORDER BY ur.created_at DESC;
