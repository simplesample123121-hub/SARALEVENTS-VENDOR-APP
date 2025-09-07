"use client"
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'

type Vendor = {
  id: string
  business_name: string
  address?: string | null
  category?: string | null
  phone_number?: string | null
}

export default function VendorsPage() {
  const supabase = createClient()
  const [rows, setRows] = useState<Vendor[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const load = async () => {
      setLoading(true)
      const { data, error } = await supabase
        .from('vendor_profiles')
        .select('id, business_name, address, category, phone_number')
        .order('business_name')
        .limit(500)
      if (!error && data) setRows(data as any)
      setLoading(false)
    }
    load()
  }, [supabase])

  return (
    <main className="p-6">
      <h1 className="text-xl font-semibold mb-4">Vendors</h1>
      <div className="bg-white rounded-xl border overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 text-left">
            <tr>
              <th className="p-3">Business</th>
              <th className="p-3">Category</th>
              <th className="p-3">Phone</th>
              <th className="p-3">Address</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td className="p-3" colSpan={4}>Loading...</td></tr>
            ) : rows.length === 0 ? (
              <tr><td className="p-3" colSpan={4}>No vendors</td></tr>
            ) : rows.map(v => (
              <tr key={v.id} className="border-t">
                <td className="p-3 font-medium">{v.business_name}</td>
                <td className="p-3">{v.category ?? '-'}</td>
                <td className="p-3">{v.phone_number ?? '-'}</td>
                <td className="p-3">{v.address ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  )
}


