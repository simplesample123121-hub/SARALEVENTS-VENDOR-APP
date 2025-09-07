"use client"
import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function SignInPage() {
  const router = useRouter()
  const supabase = createClient()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    setLoading(false)
    if (error) return setError(error.message)
    router.push('/dashboard')
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-6">
      <form onSubmit={onSubmit} className="max-w-sm w-full bg-white rounded-xl p-6 shadow">
        <h1 className="text-xl font-bold mb-4">Sign in</h1>
        <div className="space-y-3">
          <input value={email} onChange={e=>setEmail(e.target.value)} type="email" placeholder="Email" required className="w-full border rounded-md p-2" />
          <input value={password} onChange={e=>setPassword(e.target.value)} type="password" placeholder="Password" required className="w-full border rounded-md p-2" />
          {error && <p className="text-red-600 text-sm">{error}</p>}
          <button disabled={loading} className="w-full bg-black text-white rounded-md py-2">{loading ? 'Signing in...' : 'Sign in'}</button>
        </div>
      </form>
    </main>
  )
}


