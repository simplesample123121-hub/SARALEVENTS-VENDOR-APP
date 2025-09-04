-- Assign Vendor Roles to Existing Vendor Accounts
-- Run this in your Supabase SQL Editor to assign roles to existing vendors

-- First, ensure all existing vendors have 'vendor' role
INSERT INTO user_roles (user_id, role)
SELECT user_id, 'vendor' 
FROM vendor_profiles 
WHERE user_id NOT IN (
    SELECT user_id FROM user_roles WHERE role = 'vendor'
)
ON CONFLICT (user_id, role) DO NOTHING;

-- Check how many vendors were assigned roles
SELECT 
    'Vendors with roles' as status,
    COUNT(*) as count
FROM user_roles 
WHERE role = 'vendor';

-- Show all vendor roles
SELECT 
    vp.business_name,
    vp.email,
    ur.role,
    ur.created_at
FROM vendor_profiles vp
LEFT JOIN user_roles ur ON vp.user_id = ur.user_id
WHERE ur.role = 'vendor'
ORDER BY ur.created_at DESC;

-- Verify the role assignment worked
SELECT 
    'Total vendors' as metric,
    COUNT(*) as count
FROM vendor_profiles
UNION ALL
SELECT 
    'Vendors with vendor role' as metric,
    COUNT(*) as count
FROM user_roles 
WHERE role = 'vendor';
