"use client"
import { useEffect, useMemo, useState } from 'react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { ChevronRight, Search as SearchIcon, X as XIcon, ArrowUpDown } from 'lucide-react'

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
  vendor_profiles?: { id: string; business_name: string } | null
}

export default function ServicesPage() {
  const supabase = createClient()
  const [rows, setRows] = useState<ServiceRow[]>([])
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState<string | null>(null)
  const [savingId, setSavingId] = useState<string | null>(null)

  // UI state
  const [search, setSearch] = useState('')
  const [groupByVendor, setGroupByVendor] = useState(true)
  const [sortBy, setSortBy] = useState<'vendor' | 'service' | 'price'>('vendor')
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc')

  const load = async () => {
    setLoading(true)
    setErr(null)
    let { data, error } = await supabase
      .from('services')
      .select('id, name, price, is_active, is_visible_to_users, category, media_urls, vendor_id, is_featured, vendor_profiles(id,business_name)')
      .order('created_at', { ascending: false })
      .limit(500)
    if (error) {
      // Fallback if is_featured column does not exist yet
      const fb = await supabase
        .from('services')
        .select('id, name, price, is_active, is_visible_to_users, category, media_urls, vendor_id, vendor_profiles(id,business_name)')
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
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={load} disabled={loading}>{loading ? 'Refreshing...' : 'Refresh'}</Button>
        </div>
      </div>
      {err && (
        <div className="mb-3 text-sm text-red-600">{err}</div>
      )}

      {/* Controls */}
      <div className="bg-white rounded-xl border p-4 md:p-5 mb-4 shadow-sm">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-end">
          {/* Search */}
          <div className="md:col-span-6">
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                <SearchIcon className="h-4 w-4" />
              </span>
              <Input
                placeholder="Search by vendor or service name"
                value={search}
                onChange={(e) => { setSearch(e.target.value) }}
                className="pl-9 pr-9"
                aria-label="Search services"
              />
              {search && (
                <button
                  type="button"
                  onClick={() => setSearch('')}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                  aria-label="Clear search"
                >
                  <XIcon className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>

          {/* View mode */}
          <div className="md:col-span-3">
            <label className="block mb-1 text-xs font-medium text-gray-600">View</label>
            <select
              className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
              value={groupByVendor ? 'group' : 'list'}
              onChange={(e) => setGroupByVendor(e.target.value === 'group')}
              aria-label="View mode"
            >
              <option value="group">Group by Vendor</option>
              <option value="list">Flat List</option>
            </select>
          </div>

          {/* Sort */}
          <div className="md:col-span-3">
            <label className="block mb-1 text-xs font-medium text-gray-600">Sort</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                <ArrowUpDown className="h-4 w-4" />
              </span>
              <select
                className="w-full h-10 rounded-md border border-input bg-background pl-9 pr-3 text-sm"
                value={`${sortBy}:${sortDir}`}
                onChange={(e) => {
                  const [k, d] = e.target.value.split(':') as [any, any]
                  setSortBy(k)
                  setSortDir(d)
                }}
                aria-label="Sort services"
              >
                <option value="vendor:asc">Vendor A-Z</option>
                <option value="vendor:desc">Vendor Z-A</option>
                <option value="service:asc">Service A-Z</option>
                <option value="service:desc">Service Z-A</option>
                <option value="price:asc">Price ↑</option>
                <option value="price:desc">Price ↓</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {groupByVendor ? (
        <VendorsGrouped
          rows={rows}
          search={search}
          sortBy={sortBy}
          sortDir={sortDir}
          toggleFeatured={toggleFeatured}
          savingId={savingId}
        />
      ) : (
        <FlatList
          rows={rows}
          search={search}
          sortBy={sortBy}
          sortDir={sortDir}
          toggleFeatured={toggleFeatured}
          savingId={savingId}
        />
      )}
    </main>
  )
}


function VendorsGrouped({
  rows,
  search,
  sortBy,
  sortDir,
  toggleFeatured,
  savingId,
}: {
  rows: ServiceRow[]
  search: string
  sortBy: 'vendor' | 'service' | 'price'
  sortDir: 'asc' | 'desc'
  toggleFeatured: (id: string, next: boolean) => Promise<void>
  savingId: string | null
}) {
  const filtered = useMemo(() => {
    let list = rows
    const q = search.trim().toLowerCase()
    if (q) {
      list = list.filter(r =>
        (r.vendor_profiles?.business_name || '').toLowerCase().includes(q) ||
        (r.name || '').toLowerCase().includes(q)
      )
    }
    return list
  }, [rows, search])

  const groups = useMemo(() => {
    const map = new Map<string, ServiceRow[]>()
    filtered.forEach(r => {
      const key = r.vendor_profiles?.business_name || r.vendor_id || 'Unknown Vendor'
      const arr = map.get(key) || []
      arr.push(r)
      map.set(key, arr)
    })
    const sortedVendors = Array.from(map.entries()).sort((a, b) => {
      const dir = sortDir === 'asc' ? 1 : -1
      return a[0].localeCompare(b[0]) * (sortBy === 'vendor' ? dir : 1)
    })
    return sortedVendors
  }, [filtered, sortBy, sortDir])

  // Collapse/expand state per vendor
  const [openVendors, setOpenVendors] = useState<Record<string, boolean>>({})
  useEffect(() => {
    // When vendor list changes, ensure keys exist; default to open
    setOpenVendors(prev => {
      const next: Record<string, boolean> = { ...prev }
      for (const [vendorName] of groups) {
        if (next[vendorName] == null) next[vendorName] = true
      }
      // Remove stale keys
      Object.keys(next).forEach(k => {
        if (!groups.find(([v]) => v === k)) delete next[k]
      })
      return next
    })
  }, [groups])

  const setAll = (open: boolean) => {
    const next: Record<string, boolean> = {}
    for (const [vendorName] of groups) next[vendorName] = open
    setOpenVendors(next)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-end gap-2">
        <Button variant="outline" onClick={() => setAll(true)}>Expand all</Button>
        <Button variant="outline" onClick={() => setAll(false)}>Collapse all</Button>
      </div>
      
      {groups.map(([vendorName, services]) => (
        <div key={vendorName} className="bg-white rounded-xl border">
          <button
            className="w-full text-left px-4 py-3 flex items-center justify-between hover:bg-gray-50 transition-colors"
            onClick={() => setOpenVendors(prev => ({ ...prev, [vendorName]: !prev[vendorName] }))}
          >
            <div className="flex items-center gap-3">
              <span className={`inline-flex h-5 w-5 items-center justify-center rounded-full border transition-transform duration-300 ${openVendors[vendorName] ? 'rotate-90' : 'rotate-0'}`}>
                <ChevronRight className="h-3.5 w-3.5" />
              </span>
              <div>
                <div className="text-base font-semibold">{vendorName}</div>
                <div className="text-xs text-gray-500">{services.length} service(s)</div>
              </div>
            </div>
            <div className="text-sm text-gray-500">{openVendors[vendorName] ? 'Hide' : 'Show'}</div>
          </button>
          <div className={`grid transition-all duration-300 ${openVendors[vendorName] ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0'}`}>
            <div className="overflow-hidden">
              <div className="overflow-x-auto">
                <table className="min-w-full text-sm">
                  <thead className="bg-gray-50 text-left">
                    <tr>
                      <th className="p-3">Media</th>
                      <th className="p-3">Service</th>
                      <th className="p-3">Category</th>
                      <th className="p-3">Price</th>
                      <th className="p-3">Active</th>
                      <th className="p-3">Visible</th>
                      <th className="p-3">Featured</th>
                    </tr>
                  </thead>
                  <tbody>
                    {services
                      .slice()
                      .sort((a, b) => {
                        const dir = sortDir === 'asc' ? 1 : -1
                        if (sortBy === 'service') return a.name.localeCompare(b.name) * dir
                        if (sortBy === 'price') return (Number(a.price || 0) - Number(b.price || 0)) * dir
                        return 0
                      })
                      .map(s => (
                      <tr key={s.id} className="border-t">
                        <td className="p-3">
                          {s.media_urls && s.media_urls.length > 0 ? (
                            <Image src={s.media_urls[0]} alt={s.name} width={56} height={40} className="rounded object-cover" />
                          ) : (
                            <div className="w-14 h-10 bg-gray-100 rounded" />
                          )}
                        </td>
                        <td className="p-3 font-medium">{s.name}</td>
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
            </div>
          </div>
        </div>
      ))}
      {groups.length === 0 && (
        <div className="text-sm text-gray-600">No services</div>
      )}
    </div>
  )
}

function FlatList({
  rows,
  search,
  sortBy,
  sortDir,
  toggleFeatured,
  savingId,
}: {
  rows: ServiceRow[]
  search: string
  sortBy: 'vendor' | 'service' | 'price'
  sortDir: 'asc' | 'desc'
  toggleFeatured: (id: string, next: boolean) => Promise<void>
  savingId: string | null
}) {
  const filtered = useMemo(() => {
    let list = rows
    const q = search.trim().toLowerCase()
    if (q) {
      list = list.filter(r =>
        (r.vendor_profiles?.business_name || '').toLowerCase().includes(q) ||
        (r.name || '').toLowerCase().includes(q)
      )
    }
    list = list.slice().sort((a, b) => {
      const dir = sortDir === 'asc' ? 1 : -1
      if (sortBy === 'vendor') return (a.vendor_profiles?.business_name || '').localeCompare(b.vendor_profiles?.business_name || '') * dir
      if (sortBy === 'service') return a.name.localeCompare(b.name) * dir
      if (sortBy === 'price') return (Number(a.price || 0) - Number(b.price || 0)) * dir
      return 0
    })
    return list
  }, [rows, search, sortBy, sortDir])

  return (
    <div className="bg-white rounded-xl border overflow-x-auto">
      <table className="min-w-full text-sm">
        <thead className="bg-gray-50 text-left">
          <tr>
            <th className="p-3">Media</th>
            <th className="p-3">Service</th>
            <th className="p-3">Vendor</th>
            <th className="p-3">Category</th>
            <th className="p-3">Price</th>
            <th className="p-3">Active</th>
            <th className="p-3">Visible</th>
            <th className="p-3">Featured</th>
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 ? (
            <tr><td className="p-3" colSpan={8}>No services</td></tr>
          ) : filtered.map(s => (
            <tr key={s.id} className="border-t">
              <td className="p-3">
                {s.media_urls && s.media_urls.length > 0 ? (
                  <Image src={s.media_urls[0]} alt={s.name} width={56} height={40} className="rounded object-cover" />
                ) : (
                  <div className="w-14 h-10 bg-gray-100 rounded" />
                )}
              </td>
              <td className="p-3 font-medium">{s.name}</td>
              <td className="p-3">{s.vendor_profiles?.business_name || s.vendor_id || '-'}</td>
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
  )
}


