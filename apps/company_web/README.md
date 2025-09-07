Company Web (Next.js 14)

Setup
1) Copy .env.example to .env.local and fill:
   - NEXT_PUBLIC_SUPABASE_URL
   - NEXT_PUBLIC_SUPABASE_ANON_KEY
2) Install deps and run:
   npm install
   npm run dev

Pages
- /           Landing with links
- /signin     Email/password auth (Supabase)
- /dashboard  Protected dashboard shell with links to Orders, Chats, Services, Vendors, Users

Next steps
- Add RLS policies for admin role; gate access by role in Supabase
- Build data tables for each dashboard section (orders, chats, services, vendors, users)
- Add server-side fetching with @supabase/ssr if needed

