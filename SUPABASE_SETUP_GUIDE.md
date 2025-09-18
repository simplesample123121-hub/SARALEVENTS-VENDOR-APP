# Event Planning App - Supabase Backend Setup Guide

## Overview
This guide will help you set up the complete Supabase backend for the event planning app. The app now has full backend integration with proper database schema, Row Level Security (RLS), and real-time capabilities.

## Prerequisites
- Supabase account and project
- Flutter app with Supabase Flutter package installed
- Basic understanding of PostgreSQL and Supabase

## Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note down your project URL and anon key from Settings > API

## Step 2: Set Up Database Schema
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the entire contents of `supabase_schema.sql` file
4. Execute the SQL script

This will create:
- All necessary tables (events, checklist_tasks, budget_items, etc.)
- Custom types and enums
- Indexes for performance
- Row Level Security policies
- Database functions and triggers
- Sample data initialization function

## Step 3: Configure Flutter App
1. Update your `main.dart` to initialize Supabase:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(MyApp());
}
```

2. Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with your actual values.

## Step 4: Test the Integration

### Initialize Sample Data (Optional)
To test with sample data, run this SQL in Supabase SQL Editor:

```sql
-- Replace 'your-user-id' with an actual user ID from auth.users
SELECT initialize_sample_data('your-user-id');
```

### Test Authentication
1. Set up authentication in your Flutter app
2. Create a user account
3. Test creating, reading, updating, and deleting events

## Database Schema Details

### Tables Created:
1. **events** - Main event information
2. **checklist_tasks** - Task management for events
3. **budget_items** - Budget tracking for events
4. **event_timeline** - Event schedule and milestones
5. **event_notes** - Notes and comments for events
6. **guest_categories** - Guest grouping
7. **guests** - Individual guest information
8. **event_activity_log** - Activity tracking
9. **event_statistics** - Computed statistics (auto-updated)

### Key Features:
- **Row Level Security**: Users can only access their own events and shared events
- **Real-time Updates**: Automatic UI updates when data changes
- **Statistics Calculation**: Auto-calculated completion percentages and budget usage
- **Caching**: Intelligent caching with local fallback
- **Offline Support**: Local storage fallback when offline

## Security Features

### Row Level Security (RLS)
- Users can only view/edit their own events
- Shared events are accessible to invited users
- All data is protected at the database level

### Data Validation
- Proper foreign key constraints
- Type validation with custom enums
- Automatic timestamp management

## Performance Optimizations

### Indexes
- Optimized queries for common operations
- GIN indexes for array operations (shared_with)
- Composite indexes for complex queries

### Caching
- 5-minute cache for most data
- 2-minute cache for statistics
- Local storage fallback

## Real-time Features

### Subscriptions
The app supports real-time updates for:
- Event changes
- Task updates
- Budget modifications
- Guest list changes

### Usage Example:
```dart
// Subscribe to event updates
eventService.subscribeToEventUpdates(eventId, (data) {
  // Update UI with new data
});

// Subscribe to task updates
eventService.subscribeToTaskUpdates(eventId, (data) {
  // Update task list
});
```

## Troubleshooting

### Common Issues:

1. **Authentication Errors**
   - Ensure RLS policies are enabled
   - Check user authentication status
   - Verify user permissions

2. **Data Not Syncing**
   - Check network connectivity
   - Verify Supabase URL and keys
   - Check browser console for errors

3. **Performance Issues**
   - Monitor database query performance
   - Check index usage
   - Consider pagination for large datasets

### Debug Mode:
Enable debug logging in your Flutter app:

```dart
Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
  debug: true, // Enable debug logging
);
```

## Next Steps

1. **Customize the Schema**: Modify tables as needed for your specific requirements
2. **Add More Features**: Implement additional event planning features
3. **Optimize Performance**: Monitor and optimize database queries
4. **Add Analytics**: Implement user analytics and reporting
5. **Mobile Optimization**: Optimize for mobile-specific features

## Support

For issues or questions:
1. Check Supabase documentation
2. Review Flutter Supabase package docs
3. Check the app's error logs
4. Verify database permissions and RLS policies

## File Structure

```
apps/user_app/
├── lib/
│   ├── models/
│   │   └── event_planning_models.dart  # Updated with Supabase mappings
│   ├── services/
│   │   └── event_planning_service.dart # Full Supabase integration
│   └── screens/
│       ├── event_details_screen.dart   # Updated with proper service usage
│       ├── planning_screen.dart        # Updated with edit functionality
│       └── budget_tracking_screen.dart # Updated with null safety
├── supabase_schema.sql                 # Complete database schema
└── SUPABASE_SETUP_GUIDE.md            # This guide
```

The event planning app is now fully integrated with Supabase backend and ready for production use!
