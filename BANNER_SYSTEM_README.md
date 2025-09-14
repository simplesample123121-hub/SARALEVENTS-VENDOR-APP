# Banner Management System

This system allows the **Company App** to manage banners that are displayed in the **User App** home screen.

## Architecture Overview

```
Company App (Next.js) → Supabase Storage & Database → User App (Flutter)
     ↓                           ↓                         ↓
Upload/Manage Banners    Store Images & Metadata    Fetch & Display Banners
```

## Features

### Company App (Admin Dashboard)
- **Upload banners** - Drag & drop or click to upload image files
- **Manage banner status** - Activate/deactivate banners
- **Delete banners** - Remove unwanted banners
- **Preview banners** - See how banners will look
- **File validation** - Automatic size and type checking

### User App (Flutter)
- **Dynamic banner loading** - Fetches banners from company app
- **Fallback system** - Shows local assets if no remote banners
- **Caching** - Uses cached_network_image for performance
- **Error handling** - Graceful fallback on network errors
- **Carousel support** - Multiple banners with auto-play (future enhancement)

## Setup Instructions

### 1. Database Setup
```sql
-- Run these SQL scripts in your Supabase SQL Editor:
-- 1. First run: app_assets_storage_setup.sql
-- 2. Then run: setup_banner_system.sql
```

### 2. Update Supabase Project Reference
In `setup_banner_system.sql`, replace `your-project-ref` with your actual Supabase project reference:
```sql
-- Change this line:
base_url text := 'https://your-project-ref.supabase.co/storage/v1/object/public/';
-- To your actual URL:
base_url text := 'https://abcdefghijklmnop.supabase.co/storage/v1/object/public/';
```

### 3. Company App Setup
```bash
cd apps/company_web
npm install
npm run dev
```

Navigate to: `http://localhost:3005/dashboard/banners`

### 4. User App Setup
```bash
cd apps/user_app
flutter pub get
flutter run
```

## Usage Guide

### For Admins (Company App)

1. **Access Banner Management**
   - Go to `/dashboard/banners`
   - Click "Upload Banner" to add new banners

2. **Upload Guidelines**
   - **Recommended size**: 1920x1080 (16:9 aspect ratio)
   - **File formats**: JPG, PNG, WebP, GIF
   - **File size limit**: 5MB
   - **Naming**: Use descriptive names (e.g., "summer_sale_banner")

3. **Banner Management**
   - **Activate/Deactivate**: Toggle banner visibility
   - **Delete**: Permanently remove banners
   - **Preview**: See how banners appear to users

### For Users (User App)

Banners automatically appear on the home screen:
- **Hero Banner**: Large banner at the top of home screen
- **Fallback**: If no remote banners, shows local default image
- **Loading**: Shows loading indicator while fetching
- **Error Handling**: Gracefully falls back to local assets

## File Structure

```
apps/
├── company_web/
│   └── src/app/dashboard/banners/
│       └── page.tsx                 # Banner management interface
├── user_app/
│   ├── lib/services/
│   │   └── banner_service.dart      # Banner fetching logic
│   ├── lib/widgets/
│   │   └── banner_widget.dart       # Banner display components
│   └── lib/screens/
│       └── home_screen.dart         # Updated to use banner widget
└── setup_banner_system.sql         # Database setup script
```

## API Reference

### Banner Service (Flutter)

```dart
// Get all active banners
List<BannerItem> banners = await BannerService.getActiveBanners();

// Get hero banner URL
String heroUrl = await BannerService.getHeroBannerUrl();

// Get specific banner by name
BannerItem? banner = await BannerService.getBannerByName('hero_banner');

// Check if remote banners are available
bool hasRemote = await BannerService.hasRemoteBanners();
```

### Banner Widget (Flutter)

```dart
// Simple banner widget
BannerWidget(
  aspectRatio: 16 / 9,
  borderRadius: BorderRadius.circular(16),
  fallbackAsset: 'assets/onboarding/onboarding_1.jpg',
)

// Banner carousel (multiple banners)
BannerCarousel(
  height: 200,
  autoPlay: true,
  autoPlayDuration: Duration(seconds: 5),
)
```

## Database Schema

### app_assets Table
```sql
CREATE TABLE app_assets (
  id uuid PRIMARY KEY,
  app_type text,           -- 'user', 'vendor', 'company'
  asset_type text,         -- 'banner', 'icon', 'logo', etc.
  asset_name text,         -- Human-readable name
  asset_path text,         -- Storage path
  bucket_name text,        -- Supabase storage bucket
  file_size bigint,        -- File size in bytes
  mime_type text,          -- MIME type
  description text,        -- Description
  is_active boolean,       -- Active status
  created_at timestamptz,  -- Creation timestamp
  updated_at timestamptz   -- Update timestamp
);
```

## Storage Buckets

- **user-app-assets**: Stores banners and assets for user app
- **vendor-app-assets**: Stores assets for vendor app
- **company-app-assets**: Stores assets for company app

## Security

- **RLS Policies**: Row Level Security enabled on all tables
- **Storage Policies**: Proper access control on storage buckets
- **File Validation**: Size and type restrictions on uploads
- **Public Access**: Banners are publicly accessible for app display

## Troubleshooting

### Common Issues

1. **Banners not loading in user app**
   - Check internet connection
   - Verify Supabase project URL is correct
   - Ensure banners are marked as active
   - Check Flutter console for error messages

2. **Upload failing in company app**
   - Check file size (must be < 5MB)
   - Verify file format (JPG, PNG, WebP, GIF only)
   - Check browser console for errors
   - Ensure proper authentication

3. **Images not displaying**
   - Verify storage bucket permissions
   - Check if RLS policies are correctly set
   - Ensure public access is enabled on storage

### Debug Commands

```sql
-- Check active banners
SELECT * FROM app_assets WHERE app_type = 'user' AND asset_type = 'banner' AND is_active = true;

-- Test banner functions
SELECT get_hero_banner_url();
SELECT * FROM get_active_banners();

-- Check storage policies
SELECT * FROM storage.policies WHERE bucket_id = 'user-app-assets';
```

## Future Enhancements

- **Banner scheduling**: Set start/end dates for banners
- **A/B testing**: Show different banners to different users
- **Analytics**: Track banner click-through rates
- **Bulk upload**: Upload multiple banners at once
- **Image optimization**: Automatic resizing and compression
- **Banner templates**: Pre-designed banner templates

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter and Next.js console logs
3. Verify database and storage configurations
4. Test with sample banners first