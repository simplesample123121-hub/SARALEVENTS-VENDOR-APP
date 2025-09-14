# Real-Time Banner Testing Guide

## 🧪 How to Test Real-Time Updates

### **Setup for Testing**

1. **Start both applications:**
   ```bash
   # Terminal 1: Company App
   cd apps/company_web
   npm run dev
   # Access: http://localhost:3005/dashboard/banners

   # Terminal 2: User App
   cd apps/user_app
   flutter run
   ```

2. **Enable Debug Mode in User App:**
   - Look for the blue bug icon in the top-right corner of home screen
   - Tap it to open the Banner Debug Widget
   - This shows real-time connection status and banner updates

### **Test Scenarios**

#### **Test 1: Upload New Banner**
1. **Company App:** Go to `/dashboard/banners`
2. **Company App:** Upload a new banner image
3. **User App:** Check debug widget - should show update within 10 seconds
4. **User App:** Go back to home screen - new banner should appear

#### **Test 2: Toggle Banner Status**
1. **Company App:** Click "Activate" or "Deactivate" on any banner
2. **User App:** Debug widget should show banner count change
3. **User App:** Home screen should update carousel accordingly

#### **Test 3: Delete Banner**
1. **Company App:** Delete a banner
2. **User App:** Should see banner removed from list in debug widget
3. **User App:** Carousel should update on home screen

#### **Test 4: Multiple Banner Carousel**
1. **Company App:** Ensure you have 2+ active banners
2. **User App:** Home screen should show carousel with:
   - Auto-play every 4 seconds
   - Page indicators at bottom
   - Banner counter (e.g., "2/5") in top-right
   - Pause on swipe/tap, resume after 2 seconds

### **Debug Information**

#### **Banner Debug Widget Shows:**
- **Connection Status:** Real-time vs Polling mode
- **Update Count:** How many times banners have been refreshed
- **Banner List:** All active banners with thumbnails
- **Manual Refresh:** Pull-to-refresh or tap refresh button

#### **Expected Behavior:**
- **Real-time mode:** Updates appear within 1-3 seconds
- **Polling mode:** Updates appear within 10 seconds (fallback)
- **Error mode:** Shows error message, falls back to manual refresh

### **Troubleshooting Real-Time Issues**

#### **If Updates Are Not Real-Time:**

1. **Check Supabase Configuration:**
   ```dart
   // In your Supabase project dashboard:
   // 1. Go to Settings > API
   // 2. Ensure "Enable Realtime" is turned ON
   // 3. Check that app_assets table has realtime enabled
   ```

2. **Check Network Connection:**
   - Real-time requires WebSocket connection
   - Check if firewall/proxy blocks WebSockets
   - Try on different network (mobile data vs WiFi)

3. **Check Flutter Console:**
   ```bash
   flutter logs
   # Look for messages like:
   # "Starting banner subscription..."
   # "Received real-time banner update: X records"
   # "Banner widget received X banners"
   ```

4. **Check Browser Console (Company App):**
   ```javascript
   // Open browser dev tools, look for:
   // - Network errors
   // - Supabase connection issues
   // - Upload/update success messages
   ```

#### **Force Manual Refresh:**
- **User App:** Pull down on banner area to refresh
- **Debug Widget:** Tap refresh button or pull-to-refresh
- **Programmatic:** Call `BannerService.refreshBanners()`

### **Performance Testing**

#### **Test Large Banner Sets:**
1. Upload 5-10 banners
2. Check carousel performance
3. Monitor memory usage
4. Test auto-play smoothness

#### **Test Network Conditions:**
1. **Slow Network:** Check loading indicators
2. **No Network:** Verify fallback to local assets
3. **Intermittent Network:** Test reconnection behavior

### **Expected Real-Time Flow**

```
Company App Action → Supabase Database → WebSocket Event → User App Update
     ↓                      ↓                    ↓              ↓
1. Upload banner      2. INSERT into app_assets  3. Stream event   4. Add to carousel
2. Toggle status      2. UPDATE app_assets       3. Stream event   4. Show/hide banner  
3. Delete banner      2. DELETE from app_assets  3. Stream event   4. Remove from carousel

Timing: 1-3 seconds for real-time, 10 seconds for polling fallback
```

### **Debug Commands**

#### **Flutter Console Commands:**
```dart
// Check current banners
final banners = await BannerService.getActiveBanners();
print('Current banners: ${banners.length}');

// Force refresh
await BannerService.refreshBanners();

// Check stream status
BannerService.getBannerStream().listen((banners) {
  print('Stream update: ${banners.length} banners');
});
```

#### **Supabase SQL Queries:**
```sql
-- Check active banners
SELECT asset_name, is_active, created_at 
FROM app_assets 
WHERE app_type = 'user' AND asset_type = 'banner'
ORDER BY created_at DESC;

-- Check real-time subscriptions
SELECT * FROM pg_stat_activity 
WHERE application_name LIKE '%realtime%';
```

### **Success Criteria**

✅ **Real-Time Working When:**
- Banner changes appear in user app within 3 seconds
- Debug widget shows "Connected - Real-time active"
- No manual refresh needed
- Carousel updates automatically
- Update count increases with each change

❌ **Real-Time Not Working When:**
- Changes take more than 10 seconds to appear
- Debug widget shows "Polling mode" or errors
- Manual refresh required to see changes
- Update count doesn't increase

### **Common Issues & Solutions**

#### **Issue: "Polling mode" instead of real-time**
**Solution:** 
- Check Supabase real-time is enabled
- Verify WebSocket connection isn't blocked
- Check Flutter console for connection errors

#### **Issue: No updates at all**
**Solution:**
- Check internet connection
- Verify Supabase credentials
- Try manual refresh to test basic connectivity

#### **Issue: Carousel not updating**
**Solution:**
- Check if banners are marked as active
- Verify banner count in debug widget
- Check Flutter console for widget errors

#### **Issue: Images not loading**
**Solution:**
- Check storage bucket permissions
- Verify image URLs in debug widget
- Test direct image URL in browser

The real-time system should now work reliably with both WebSocket real-time updates and polling fallback! 🚀