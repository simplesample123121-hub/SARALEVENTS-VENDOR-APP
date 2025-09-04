# Same Email, Different Roles Solution

## Problem
You want to use the same email address for both vendor and user accounts, but Supabase auth doesn't allow duplicate emails.

## Solution Implemented

### 1. **Unique Auth Emails**
- User App: Creates auth user with `user_timestamp_original@email.com`
- Vendor App: Creates auth user with `vendor_timestamp_original@email.com`
- Both store the original email in their respective profile tables

### 2. **Role-Based Separation**
- `user_roles` table tracks which role each auth user has
- Same original email can have different auth users with different roles
- Login checks role to ensure correct app access

### 3. **Registration Flow**

#### User App Registration:
1. Check if email already has 'user' role → Block if exists
2. Create auth user with unique email: `user_1234567890_original@email.com`
3. Create `user_roles` entry with 'user' role
4. Create `user_profiles` entry with original email
5. Send confirmation to unique email

#### Vendor App Registration:
1. Check if email already has 'vendor' role → Block if exists  
2. Create auth user with unique email: `vendor_1234567890_original@email.com`
3. Create `user_roles` entry with 'vendor' role
4. Create `vendor_profiles` entry with original email
5. Send confirmation to unique email

### 4. **Login Flow**
1. User enters original email
2. System finds profile with that email
3. System checks role matches app type
4. If role mismatch → Show error
5. If role matches → Allow login

### 5. **Benefits**
- ✅ Same email can have different accounts
- ✅ Clear role separation
- ✅ No auth conflicts
- ✅ User-friendly experience
- ✅ Secure role validation

### 6. **User Experience**
- User registers with `john@example.com` in User App
- Same user registers with `john@example.com` in Vendor App  
- Both accounts exist independently
- Login checks role and directs to correct app

## Implementation Status
- ✅ User App registration with unique emails
- ✅ Role checking and validation
- ✅ Profile creation with original email
- ❌ Need to implement similar logic in Vendor App
- ❌ Need to update login flow to handle email lookup

## Next Steps
1. Run SQL scripts to create tables
2. Test User App registration
3. Implement Vendor App registration
4. Test cross-app login scenarios
