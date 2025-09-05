-- Revert Triggers - Drop all triggers created by database_schema_updates.sql

-- Drop triggers from all category tables
DROP TRIGGER IF EXISTS update_photographyServices_updated_at ON public."photographyServices";
DROP TRIGGER IF EXISTS update_decorServices_updated_at ON public."decorServices";
DROP TRIGGER IF EXISTS update_cateringServices_updated_at ON public."cateringServices";
DROP TRIGGER IF EXISTS update_farmhouseServices_updated_at ON public."farmhouseServices";
DROP TRIGGER IF EXISTS update_musicDjServices_updated_at ON public."musicDjServices";
DROP TRIGGER IF EXISTS update_venueservice_updated_at ON public."venueservice";
DROP TRIGGER IF EXISTS update_eventEssentials_updated_at ON public."eventEssentials";

-- Drop trigger from allServicesFull table (if it exists)
DROP TRIGGER IF EXISTS update_allServicesFull_updated_at ON public."allServicesFull";

-- Drop the trigger function (optional - only if you want to remove it completely)
-- DROP FUNCTION IF EXISTS update_updated_at_column();
