import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Saral Events - Admin',
  description: 'Company admin portal',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-gray-50 text-gray-900">{children}</body>
    </html>
  )
}


