-- Test script to check availability data and create sample data if needed

-- 1. Check if there's any availability data
SELECT 
  'Total availability records' as metric,
  COUNT(*) as count
FROM public.service_availability;

-- 2. Check services that have availability data
SELECT 
  s.id as service_id,
  s.name as service_name,
  s.vendor_id,
  COUNT(sa.date) as availability_records
FROM public.services s
LEFT JOIN public.service_availability sa ON s.id = sa.service_id
GROUP BY s.id, s.name, s.vendor_id
HAVING COUNT(sa.date) > 0
ORDER BY availability_records DESC;

-- 3. Check recent availability data (last 30 days)
SELECT 
  service_id,
  date,
  date::date as date_only,
  morning_available,
  afternoon_available,
  evening_available,
  night_available
FROM public.service_availability 
WHERE date >= NOW() - INTERVAL '30 days'
ORDER BY date DESC
LIMIT 10;

-- 4. If no data exists, create sample availability data for testing
-- (Only run this if you want to create test data)
/*
INSERT INTO public.service_availability (
  service_id, 
  date, 
  morning_available, 
  afternoon_available, 
  evening_available, 
  night_available
)
SELECT 
  s.id as service_id,
  CURRENT_DATE + INTERVAL '1 day' * generate_series(0, 6) as date,
  true as morning_available,
  true as afternoon_available,
  true as evening_available,
  true as night_available
FROM public.services s
WHERE s.id IS NOT NULL
LIMIT 1;
*/
