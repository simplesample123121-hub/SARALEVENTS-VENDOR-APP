-- Debug queries to check availability data

-- 1. Check if service_availability table exists and has data
SELECT COUNT(*) as total_records FROM service_availability;

-- 2. Check the structure of the service_availability table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'service_availability' 
ORDER BY ordinal_position;

-- 3. Check sample data from service_availability table
SELECT * FROM service_availability LIMIT 10;

-- 4. Check if there are any records for a specific service (use one of the service_ids from query 5)
-- First, get a service_id from the table, then use it in the query below
-- Example: SELECT * FROM service_availability WHERE service_id = 'actual-uuid-here' LIMIT 10;

-- 5. Check all unique service_ids in the table
SELECT DISTINCT service_id FROM service_availability LIMIT 20;

-- 5b. Get a sample service_id with some availability data
SELECT service_id, COUNT(*) as record_count 
FROM service_availability 
GROUP BY service_id 
ORDER BY record_count DESC 
LIMIT 5;

-- 6. Check availability patterns
SELECT 
  COUNT(*) as total_records,
  COUNT(CASE WHEN morning_available = true THEN 1 END) as morning_available_count,
  COUNT(CASE WHEN afternoon_available = true THEN 1 END) as afternoon_available_count,
  COUNT(CASE WHEN evening_available = true THEN 1 END) as evening_available_count,
  COUNT(CASE WHEN night_available = true THEN 1 END) as night_available_count,
  COUNT(CASE WHEN custom_start IS NOT NULL THEN 1 END) as custom_slots_count
FROM service_availability;

-- 7. Check date format and availability data in the table
SELECT date, morning_available, afternoon_available, evening_available, night_available, custom_start, custom_end
FROM service_availability 
LIMIT 5;

-- 8. Check if there are any records for the current month
SELECT * FROM service_availability 
WHERE date >= date_trunc('month', CURRENT_DATE)
AND date < date_trunc('month', CURRENT_DATE) + interval '1 month'
LIMIT 10;

-- 9. Check services that don't have any availability data
SELECT s.id, s.name, s.vendor_id 
FROM services s 
LEFT JOIN service_availability sa ON s.id = sa.service_id 
WHERE sa.service_id IS NULL 
LIMIT 10;

-- 10. Check services that DO have availability data
SELECT s.id, s.name, s.vendor_id, COUNT(sa.service_id) as availability_count
FROM services s 
INNER JOIN service_availability sa ON s.id = sa.service_id 
GROUP BY s.id, s.name, s.vendor_id
ORDER BY availability_count DESC
LIMIT 10;

-- 11. Check if a specific service has availability data (replace with actual service ID from app logs)
-- SELECT * FROM service_availability WHERE service_id = 'your-service-id-from-app-logs';

-- 11b. Check which services have availability data vs which don't
SELECT 
  s.id,
  s.name,
  s.vendor_id,
  CASE 
    WHEN sa.service_id IS NOT NULL THEN 'HAS AVAILABILITY'
    ELSE 'NO AVAILABILITY'
  END as availability_status,
  COUNT(sa.service_id) as availability_count
FROM services s
LEFT JOIN service_availability sa ON s.id = sa.service_id
GROUP BY s.id, s.name, s.vendor_id, sa.service_id
ORDER BY availability_status, s.name;

-- 12. Compare service IDs between services table and availability table
SELECT 
  'Services Table' as source,
  COUNT(*) as count,
  STRING_AGG(DISTINCT id::text, ', ') as sample_ids
FROM services
UNION ALL
SELECT 
  'Availability Table' as source,
  COUNT(*) as count,
  STRING_AGG(DISTINCT service_id::text, ', ') as sample_ids
FROM service_availability;

-- 13. Get all availability data for September 2025 (to match the vendor app image)
SELECT 
  sa.service_id,
  sa.date,
  sa.morning_available,
  sa.afternoon_available,
  sa.evening_available,
  sa.night_available,
  s.name as service_name
FROM service_availability sa
LEFT JOIN services s ON sa.service_id = s.id
WHERE sa.date >= '2025-09-01' AND sa.date < '2025-10-01'
ORDER BY sa.date;
