import { createBrowserClient } from '@supabase/ssr'

// HARD-CODED Supabase credentials (replace with your actual project values)
const SUPABASE_URL = 'https://hucsihwqsuvqvbnyapdn.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1Y3NpaHdxc3V2cXZibnlhcGRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI0Nzk0ODYsImV4cCI6MjA2ODA1NTQ4Nn0.gSu1HE7eZ4n3biaM338wDF0L2m4Yc3xYyt2GtuPOr1w'

export function createClient() {
  return createBrowserClient(SUPABASE_URL, SUPABASE_ANON_KEY)
}


