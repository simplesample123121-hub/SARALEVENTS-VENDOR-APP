"use client"
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'

type UserRow = {
  id: string
  email?: string | null
  created_at?: string | null
  user_profiles?: { first_name?: string | null; last_name?: string | null; phone?: string | null } | null
}

export default function UsersPage() {
  const supabase = createClient()
  const [rows, setRows] = useState<UserRow[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const load = async () => {
      setLoading(true)
      // Try joining user_profiles; fallback to auth.users if RLS restricts
      const { data, error } = await supabase
        .from('user_profiles')
        .select('user_id:id, first_name, last_name, phone, created_at')
        .order('created_at', { ascending: false })
        .limit(500)
      if (!error && data) {
        setRows(data.map((u:any)=>({ id: u.user_id, email: null, created_at: u.created_at, user_profiles: { first_name: u.first_name, last_name: u.last_name, phone: u.phone } })))
      } else {
        // Fallback minimal list from auth users via rpc or exposed view (requires configuration)
        setRows([])
      }
      setLoading(false)
    }
    load()
  }, [supabase])

  return (
    <main className="p-6">
      <h1 className="text-xl font-semibold mb-4">Users</h1>
      <div className="bg-white rounded-xl border overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 text-left">
            <tr>
              <th className="p-3">Name</th>
              <th className="p-3">Phone</th>
              <th className="p-3">Joined</th>
              <th className="p-3">User ID</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td className="p-3" colSpan={4}>Loading...</td></tr>
            ) : rows.length === 0 ? (
              <tr><td className="p-3" colSpan={4}>No users</td></tr>
            ) : rows.map(u => (
              <tr key={u.id} className="border-t">
                <td className="p-3">{u.user_profiles ? `${u.user_profiles.first_name ?? ''} ${u.user_profiles.last_name ?? ''}`.trim() : '-'}</td>
                <td className="p-3">{u.user_profiles?.phone ?? '-'}</td>
                <td className="p-3">{u.created_at ?? '-'}</td>
                <td className="p-3 font-mono text-xs">{u.id.slice(0,8)}...</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  )
}


