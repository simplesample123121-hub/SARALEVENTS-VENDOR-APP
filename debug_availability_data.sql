-- Debug availability data format and content
-- Check the actual data format in service_availability table

-- 1. Check table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'service_availability' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check sample data (first 5 records)
SELECT 
  service_id,
  date,
  date::date as date_only,
  morning_available,
  afternoon_available,
  evening_available,
  night_available,
  custom_start,
  custom_end
FROM public.service_availability 
ORDER BY date DESC 
LIMIT 5;

-- 3. Check if there's any data for September 2025
SELECT 
  service_id,
  date,
  date::date as date_only,
  morning_available,
  afternoon_available,
  evening_available,
  night_available
FROM public.service_availability 
WHERE date >= '2025-09-01'::timestamptz 
  AND date < '2025-10-01'::timestamptz
ORDER BY date;

-- 4. Check all services that have availability data
SELECT DISTINCT 
  s.id as service_id,
  s.name as service_name,
  s.vendor_id,
  COUNT(sa.date) as availability_records
FROM public.services s
LEFT JOIN public.service_availability sa ON s.id = sa.service_id
GROUP BY s.id, s.name, s.vendor_id
HAVING COUNT(sa.date) > 0
ORDER BY availability_records DESC;