import Link from 'next/link'

export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center p-6">
      <div className="max-w-md w-full space-y-6 bg-white shadow-sm rounded-xl p-8">
        <h1 className="text-2xl font-bold">Saral Events Admin</h1>
        <p className="text-gray-600">Sign in to access Orders, Chats, Services, Vendors, and Users.</p>
        <div className="flex gap-3">
          <Link href="/signin" className="px-4 py-2 bg-black text-white rounded-md">Sign in</Link>
          <Link href="/dashboard" className="px-4 py-2 border rounded-md">Go to Dashboard</Link>
        </div>
      </div>
    </main>
  )
}


