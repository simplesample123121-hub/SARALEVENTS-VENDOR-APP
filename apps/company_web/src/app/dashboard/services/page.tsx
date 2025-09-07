"use client"
import { useEffect, useState } from 'react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase'

type ServiceRow = {
  id: string
  name: string
  price: number | null
  is_active: boolean
  is_visible_to_users: boolean | null
  category?: string | null
  media_urls?: string[] | null
  vendor_id?: string | null
  is_featured?: boolean | null
}

export default function ServicesPage() {
  const supabase = createClient()
  const [rows, setRows] = useState<ServiceRow[]>([])
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState<string | null>(null)
  const [savingId, setSavingId] = useState<string | null>(null)

  const load = async () => {
    setLoading(true)
    setErr(null)
    let { data, error } = await supabase
      .from('services')
      .select('id, name, price, is_active, is_visible_to_users, category, media_urls, vendor_id, is_featured')
      .order('created_at', { ascending: false })
      .limit(500)
    if (error) {
      // Fallback if is_featured column does not exist yet
      const fb = await supabase
        .from('services')
        .select('id, name, price, is_active, is_visible_to_users, category, media_urls, vendor_id')
        .order('created_at', { ascending: false })
        .limit(500)
      if (fb.error) setErr(`${error.message} | Fallback: ${fb.error.message}`)
      data = fb.data as any
    }
    if (data) setRows(data as any)
    setLoading(false)
  }
  useEffect(() => { load() }, [])

  const toggleFeatured = async (id: string, next: boolean) => {
    setSavingId(id)
    const { error } = await supabase.from('services').update({ is_featured: next }).eq('id', id)
    setSavingId(null)
    if (error) setErr(error.message)
    else setRows(prev => prev.map(r => r.id === id ? { ...r, is_featured: next } : r))
  }

  return (
    <main className="p-6">
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-xl font-semibold">Services</h1>
        <button onClick={load} className="px-3 py-1.5 border rounded-md">Refresh</button>
      </div>
      {err && (
        <div className="mb-3 text-sm text-red-600">{err}</div>
      )}
      <div className="bg-white rounded-xl border overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 text-left">
            <tr>
              <th className="p-3">Media</th>
              <th className="p-3">Service</th>
              <th className="p-3">Vendor ID</th>
              <th className="p-3">Category</th>
              <th className="p-3">Price</th>
              <th className="p-3">Active</th>
              <th className="p-3">Visible</th>
              <th className="p-3">Featured</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td className="p-3" colSpan={7}>Loading...</td></tr>
            ) : rows.length === 0 ? (
              <tr><td className="p-3" colSpan={7}>No services</td></tr>
            ) : rows.map(s => (
              <tr key={s.id} className="border-t">
                <td className="p-3">
                  {s.media_urls && s.media_urls.length > 0 ? (
                    <Image src={s.media_urls[0]} alt={s.name} width={56} height={40} className="rounded object-cover" />
                  ) : (
                    <div className="w-14 h-10 bg-gray-100 rounded" />
                  )}
                </td>
                <td className="p-3 font-medium">{s.name}</td>
                <td className="p-3">{s.vendor_id ?? '-'}</td>
                <td className="p-3">{s.category ?? '-'}</td>
                <td className="p-3">{s.price != null ? `₹${Number(s.price).toFixed(0)}` : '-'}</td>
                <td className="p-3">{s.is_active ? 'Yes' : 'No'}</td>
                <td className="p-3">{s.is_visible_to_users ? 'Yes' : 'No'}</td>
                <td className="p-3">
                  {typeof s.is_featured === 'boolean' ? (
                    <label className="inline-flex items-center gap-2">
                      <input type="checkbox" checked={!!s.is_featured} onChange={e=>toggleFeatured(s.id, e.target.checked)} disabled={savingId===s.id} />
                      {savingId===s.id && <span className="text-xs text-gray-500">Saving...</span>}
                    </label>
                  ) : (
                    <span className="text-xs text-gray-400">Add column is_featured to enable</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  )
}


