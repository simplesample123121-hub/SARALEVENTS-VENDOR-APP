"use client"
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'

type Booking = {
  id: string
  booking_date: string
  booking_time: string | null
  status: string
  amount: number
  created_at: string
  services?: { name: string } | null
  vendor_profiles?: { business_name: string } | null
}

export default function OrdersPage() {
  const supabase = createClient()
  const [rows, setRows] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const load = async () => {
      setLoading(true)
      const { data, error } = await supabase
        .from('bookings')
        .select('id, booking_date, booking_time, status, amount, created_at, services(name), vendor_profiles(business_name)')
        .order('created_at', { ascending: false })
        .limit(200)
      if (!error && data) setRows(data as any)
      setLoading(false)
    }
    load()
  }, [supabase])

  return (
    <main className="p-6">
      <h1 className="text-xl font-semibold mb-4">Orders</h1>
      <div className="bg-white rounded-xl border overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 text-left">
            <tr>
              <th className="p-3">ID</th>
              <th className="p-3">Service</th>
              <th className="p-3">Vendor</th>
              <th className="p-3">Date</th>
              <th className="p-3">Time</th>
              <th className="p-3">Amount</th>
              <th className="p-3">Status</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td className="p-3" colSpan={7}>Loading...</td></tr>
            ) : rows.length === 0 ? (
              <tr><td className="p-3" colSpan={7}>No orders</td></tr>
            ) : rows.map(b => (
              <tr key={b.id} className="border-t">
                <td className="p-3 font-mono text-xs">{b.id.slice(0,8)}...</td>
                <td className="p-3">{b.services?.name ?? '-'}</td>
                <td className="p-3">{b.vendor_profiles?.business_name ?? '-'}</td>
                <td className="p-3">{b.booking_date}</td>
                <td className="p-3">{b.booking_time ?? '-'}</td>
                <td className="p-3">₹{b.amount?.toFixed?.(2) ?? b.amount}</td>
                <td className="p-3">
                  <span className="px-2 py-1 rounded text-xs bg-gray-100">{b.status}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  )
}


