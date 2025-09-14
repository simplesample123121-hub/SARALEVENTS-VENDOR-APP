"use client"
import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import Image from 'next/image'

interface Banner {
  id: string
  asset_name: string
  asset_path: string
  bucket_name: string
  description: string
  is_active: boolean
  created_at: string
  file_size?: number
  mime_type?: string
}

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[]>([])
  const [loading, setLoading] = useState(true)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const supabase = createClient()

  useEffect(() => {
    loadBanners()
  }, [])

  const loadBanners = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('app_assets')
        .select('*')
        .eq('app_type', 'user')
        .eq('asset_type', 'banner')
        .order('created_at', { ascending: false })

      if (error) throw error
      setBanners(data || [])
    } catch (err) {
      console.error('Error loading banners:', err)
      setError('Failed to load banners')
    } finally {
      setLoading(false)
    }
  }

  const uploadBanner = async (file: File) => {
    try {
      setUploading(true)
      setError(null)

      // Validate file
      if (!file.type.startsWith('image/')) {
        throw new Error('Please select an image file')
      }

      if (file.size > 5 * 1024 * 1024) { // 5MB limit
        throw new Error('File size must be less than 5MB')
      }

      // Generate unique filename
      const fileExt = file.name.split('.').pop()
      const fileName = `banner_${Date.now()}.${fileExt}`
      const filePath = `banners/${fileName}`

      // Upload to Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from('user-app-assets')
        .upload(filePath, file)

      if (uploadError) throw uploadError

      // Create database record
      const { error: dbError } = await supabase
        .from('app_assets')
        .insert({
          app_type: 'user',
          asset_type: 'banner',
          asset_name: fileName.replace(/\.[^/.]+$/, ""), // Remove extension
          asset_path: filePath,
          bucket_name: 'user-app-assets',
          file_size: file.size,
          mime_type: file.type,
          description: `Banner uploaded on ${new Date().toLocaleDateString()}`,
          is_active: true
        })

      if (dbError) throw dbError

      // Reload banners
      await loadBanners()
      setSuccess('Banner uploaded successfully! Changes will appear in the user app within seconds.')
      
      // Clear success message after 5 seconds
      setTimeout(() => setSuccess(null), 5000)
    } catch (err) {
      console.error('Error uploading banner:', err)
      setError(err instanceof Error ? err.message : 'Failed to upload banner')
    } finally {
      setUploading(false)
    }
  }

  const toggleBannerStatus = async (bannerId: string, currentStatus: boolean) => {
    try {
      const { error } = await supabase
        .from('app_assets')
        .update({ is_active: !currentStatus })
        .eq('id', bannerId)

      if (error) throw error
      await loadBanners()
      setSuccess(`Banner ${!currentStatus ? 'activated' : 'deactivated'} successfully!`)
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      console.error('Error updating banner status:', err)
      setError('Failed to update banner status')
    }
  }

  const deleteBanner = async (banner: Banner) => {
    if (!confirm('Are you sure you want to delete this banner?')) return

    try {
      // Delete from storage
      const { error: storageError } = await supabase.storage
        .from(banner.bucket_name)
        .remove([banner.asset_path])

      if (storageError) console.warn('Storage deletion error:', storageError)

      // Delete from database
      const { error: dbError } = await supabase
        .from('app_assets')
        .delete()
        .eq('id', banner.id)

      if (dbError) throw dbError
      await loadBanners()
    } catch (err) {
      console.error('Error deleting banner:', err)
      setError('Failed to delete banner')
    }
  }

  const getBannerUrl = (banner: Banner) => {
    return supabase.storage
      .from(banner.bucket_name)
      .getPublicUrl(banner.asset_path).data.publicUrl
  }

  return (
    <div className="min-h-screen p-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold">Banner Management</h1>
            <p className="text-gray-600">
              Manage banners displayed in the user app • 
              <span className="font-medium text-blue-600"> {banners.filter(b => b.is_active).length} active</span> • 
              <span className="text-gray-500">{banners.length} total</span>
            </p>
            {banners.length > 1 && (
              <p className="text-sm text-green-600 mt-1">
                📱 Multiple banners will display as a carousel in the user app
              </p>
            )}
          </div>
          
          <label className="px-4 py-2 bg-blue-600 text-white rounded-lg cursor-pointer hover:bg-blue-700 transition">
            {uploading ? 'Uploading...' : 'Upload Banner'}
            <input
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0]
                if (file) uploadBanner(file)
              }}
              disabled={uploading}
            />
          </label>
        </div>

        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-600">{error}</p>
            <button 
              onClick={() => setError(null)}
              className="mt-2 text-sm text-red-500 hover:text-red-700"
            >
              Dismiss
            </button>
          </div>
        )}

        {success && (
          <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
            <p className="text-green-600">{success}</p>
            <button 
              onClick={() => setSuccess(null)}
              className="mt-2 text-sm text-green-500 hover:text-green-700"
            >
              Dismiss
            </button>
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {banners.map((banner) => (
              <div key={banner.id} className="bg-white rounded-lg shadow-sm border overflow-hidden">
                <div className="aspect-video relative">
                  <Image
                    src={getBannerUrl(banner)}
                    alt={banner.asset_name}
                    fill
                    className="object-cover"
                  />
                  <div className={`absolute top-2 right-2 px-2 py-1 rounded text-xs font-medium ${
                    banner.is_active 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-gray-100 text-gray-800'
                  }`}>
                    {banner.is_active ? 'Active' : 'Inactive'}
                  </div>
                </div>
                
                <div className="p-4">
                  <h3 className="font-medium text-gray-900 mb-1">{banner.asset_name}</h3>
                  <p className="text-sm text-gray-600 mb-2">{banner.description}</p>
                  
                  <div className="text-xs text-gray-500 mb-3">
                    <div>Size: {banner.file_size ? `${(banner.file_size / 1024).toFixed(1)} KB` : 'Unknown'}</div>
                    <div>Uploaded: {new Date(banner.created_at).toLocaleDateString()}</div>
                  </div>
                  
                  <div className="flex gap-2">
                    <button
                      onClick={() => toggleBannerStatus(banner.id, banner.is_active)}
                      className={`flex-1 px-3 py-1.5 text-sm rounded transition ${
                        banner.is_active
                          ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                          : 'bg-green-100 text-green-700 hover:bg-green-200'
                      }`}
                    >
                      {banner.is_active ? 'Deactivate' : 'Activate'}
                    </button>
                    
                    <button
                      onClick={() => deleteBanner(banner)}
                      className="px-3 py-1.5 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 transition"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            ))}
            
            {banners.length === 0 && (
              <div className="col-span-full text-center py-12">
                <div className="text-gray-400 mb-2">
                  <svg className="mx-auto h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-1">No banners uploaded</h3>
                <p className="text-gray-600">Upload your first banner to get started</p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}