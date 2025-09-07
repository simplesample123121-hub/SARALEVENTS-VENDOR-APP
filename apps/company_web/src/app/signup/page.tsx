"use client"
import { useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase'

export default function SignUpPage() {
  const supabase = createClient()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setMessage(null)
    const { error } = await supabase.auth.signUp({ email, password })
    setLoading(false)
    if (error) setError(error.message)
    else setMessage('Check your email for a confirmation link to complete sign up.')
  }

  return (
    <main className="min-h-screen flex items-center justify-center p-6">
      <form onSubmit={onSubmit} className="max-w-sm w-full bg-white rounded-xl p-6 shadow">
        <h1 className="text-xl font-bold mb-4">Create account</h1>
        <div className="space-y-3">
          <input value={email} onChange={e=>setEmail(e.target.value)} type="email" placeholder="Email" required className="w-full border rounded-md p-2" />
          <input value={password} onChange={e=>setPassword(e.target.value)} type="password" placeholder="Password" required className="w-full border rounded-md p-2" />
          {error && <p className="text-red-600 text-sm">{error}</p>}
          {message && <p className="text-green-700 text-sm">{message}</p>}
          <button disabled={loading} className="w-full bg-black text-white rounded-md py-2">{loading ? 'Signing up...' : 'Sign up'}</button>
        </div>
        <div className="mt-4 text-sm text-gray-600 flex justify-between">
          <Link href="/signin" className="hover:underline">Already have an account?</Link>
          <Link href="/forgot-password" className="hover:underline">Forgot password</Link>
        </div>
      </form>
    </main>
  )
}


