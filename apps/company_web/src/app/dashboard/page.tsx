"use client"
import Link from 'next/link'
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'

export default function Dashboard() {
  const supabase = createClient()
  const [user, setUser] = useState<any>(null)

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => setUser(data.user))
  }, [supabase])

  return (
    <main className="min-h-screen p-6">
      <div className="max-w-6xl mx-auto">
        <header className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-600">{user?.email}</span>
            <button className="px-3 py-1.5 border rounded-md"
              onClick={async ()=>{ await supabase.auth.signOut(); location.href='/' }}>Sign out</button>
          </div>
        </header>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card title="Orders" href="/dashboard/orders" subtitle="View and manage orders" />
          <Card title="Chats" href="/dashboard/chats" subtitle="Conversations with users/vendors" />
          <Card title="Services" href="/dashboard/services" subtitle="All catalog services" />
          <Card title="Vendors" href="/dashboard/vendors" subtitle="Vendor profiles and status" />
          <Card title="Users" href="/dashboard/users" subtitle="User profiles and activity" />
        </div>
      </div>
    </main>
  )
}

function Card({ title, subtitle, href }: { title: string; subtitle: string; href: string }) {
  return (
    <Link href={href} className="block p-5 bg-white rounded-xl border shadow-sm hover:shadow transition">
      <div className="font-semibold">{title}</div>
      <div className="text-sm text-gray-600">{subtitle}</div>
    </Link>
  )
}


