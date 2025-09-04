# Role-Based Authentication System

This document explains how the role-based authentication system works across the Saral Events applications.

## Overview

The system allows the same email address to have different accounts for different roles:
- **User App**: For customers browsing and booking services
- **Vendor App**: For service providers managing their business
- **Company App**: For companies managing multiple vendors (future)

## Database Schema

### Tables Created

1. **`user_roles`** - Maps users to their roles
   ```sql
   CREATE TABLE user_roles (
       id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
       user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
       role TEXT NOT NULL CHECK (role IN ('user', 'vendor', 'company')),
       created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
       UNIQUE(user_id, role)
   );
   ```

2. **`user_profiles`** - User-specific profile data
   ```sql
   CREATE TABLE user_profiles (
       id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
       user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
       first_name TEXT NOT NULL,
       last_name TEXT NOT NULL,
       phone_number TEXT,
       email TEXT,
       preferences JSONB DEFAULT '{}',
       created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
       updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

### Helper Functions

- `get_user_role(user_uuid)` - Returns the role of a user
- `has_role(required_role, user_uuid)` - Checks if user has specific role
- `is_vendor(user_uuid)` - Checks if user is a vendor

## Setup Instructions

### 1. Run SQL Scripts

Execute these SQL scripts in your Supabase SQL Editor in order:

1. **User App Schema** (`role_based_auth_schema.sql`)
   - Creates user_roles and user_profiles tables
   - Sets up RLS policies
   - Creates helper functions

2. **Vendor App Schema** (`vendor_role_schema.sql`)
   - Assigns 'vendor' role to existing vendors
   - Updates RLS policies to check vendor role
   - Creates vendor-specific helper functions

### 2. Application Flow

#### User App Registration
1. User signs up with email/password
2. System creates auth.users entry
3. System creates user_profiles entry with user details
4. System assigns 'user' role in user_roles table

#### Vendor App Registration
1. Vendor signs up with email/password
2. System creates auth.users entry
3. System creates vendor_profiles entry
4. System assigns 'vendor' role in user_roles table

#### Login Flow
1. User logs in with email/password
2. System checks user_roles table for role
3. If role matches app type → proceed
4. If role doesn't match → show role mismatch screen

## Role Mismatch Handling

When a user tries to access the wrong app:

### User App
- Shows "This account is registered as a vendor. Please use the vendor app."
- Provides option to sign out or try different account

### Vendor App
- Shows "This account is registered as a user. Please use the user app."
- Provides option to sign out or try different account

## Security Features

### Row Level Security (RLS)
- Users can only access their own profiles
- Vendors can only access their own vendor data
- Role-based access control for all operations

### Role Validation
- Each app validates user role on login
- Prevents cross-app access
- Clear error messages for wrong app usage

## Code Implementation

### User Session Class
```dart
class UserSession extends ChangeNotifier {
  String? _userRole;
  
  bool get isUserRole => _userRole == 'user';
  bool get isVendorRole => _userRole == 'vendor';
  bool get hasCorrectRole => isUserRole || _userRole == null;
  
  String? get roleMismatchMessage {
    if (_userRole == 'vendor') {
      return 'This account is registered as a vendor. Please use the vendor app.';
    }
    // ... other cases
  }
}
```

### Router Protection
```dart
GoRoute(
  path: '/',
  redirect: (ctx, state) {
    final session = Provider.of<UserSession>(ctx, listen: false);
    if (!session.hasCorrectRole) return '/auth/role-mismatch';
    // ... other checks
  },
)
```

## Benefits

1. **Same Email, Different Accounts**: Users can have separate accounts for different roles
2. **Clear Separation**: No confusion between user and vendor functionality
3. **Security**: Role-based access control prevents unauthorized access
4. **Scalability**: Easy to add new roles (company, admin, etc.)
5. **User Experience**: Clear error messages guide users to correct app

## Future Enhancements

1. **Company Role**: Add company role for managing multiple vendors
2. **Multi-Role Support**: Allow users to have multiple roles
3. **Role Switching**: Allow users to switch between roles in same app
4. **Admin Panel**: Centralized user and role management

## Testing

To test the system:

1. Create a user account in User App
2. Try to login with same email in Vendor App → Should show role mismatch
3. Create a vendor account in Vendor App
4. Try to login with same email in User App → Should show role mismatch
5. Verify each app only shows appropriate data for their role
