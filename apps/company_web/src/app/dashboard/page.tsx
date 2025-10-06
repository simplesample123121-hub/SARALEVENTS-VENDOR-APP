import Link from 'next/link'
import { 
  ShoppingBag, 
  MessageSquare, 
  Settings, 
  Store, 
  Users, 
  Image,
  BarChart3,
  TrendingUp,
  DollarSign,
  Activity
} from 'lucide-react'

export default function Dashboard() {
  return (
    <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
          <p className="text-gray-600">Welcome to your admin dashboard</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard
            title="Total Orders"
            value="1,234"
            change="+12%"
            icon={ShoppingBag}
            color="blue"
          />
          <StatCard
            title="Active Vendors"
            value="89"
            change="+5%"
            icon={Store}
            color="green"
          />
          <StatCard
            title="Total Users"
            value="2,456"
            change="+8%"
            icon={Users}
            color="purple"
          />
          <StatCard
            title="Revenue"
            value="₹1,23,456"
            change="+15%"
            icon={DollarSign}
            color="yellow"
          />
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <QuickActionCard
            title="Orders"
            href="/dashboard/orders"
            subtitle="View and manage orders"
            icon={ShoppingBag}
          />
          <QuickActionCard
            title="Chats"
            href="/dashboard/chats"
            subtitle="Conversations with users/vendors"
            icon={MessageSquare}
          />
          <QuickActionCard
            title="Services"
            href="/dashboard/services"
            subtitle="All catalog services"
            icon={Settings}
          />
          <QuickActionCard
            title="Vendors"
            href="/dashboard/vendors"
            subtitle="Vendor profiles and status"
            icon={Store}
          />
          <QuickActionCard
            title="Users"
            href="/dashboard/users"
            subtitle="User profiles and activity"
            icon={Users}
          />
          <QuickActionCard
            title="Banners"
            href="/dashboard/banners"
            subtitle="Manage user app banners"
            icon={Image}
          />
        </div>
      </div>
  )
}

function StatCard({ 
  title, 
  value, 
  change, 
  icon: Icon, 
  color 
}: { 
  title: string
  value: string
  change: string
  icon: any
  color: 'blue' | 'green' | 'purple' | 'yellow'
}) {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
    yellow: 'bg-yellow-50 text-yellow-600',
  }

  return (
    <div className="bg-white p-6 rounded-lg border border-gray-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
        </div>
        <div className={`p-3 rounded-full ${colorClasses[color]}`}>
          <Icon className="h-6 w-6" />
        </div>
      </div>
      <div className="mt-4 flex items-center">
        <TrendingUp className="h-4 w-4 text-green-500 mr-1" />
        <span className="text-sm text-green-600 font-medium">{change}</span>
        <span className="text-sm text-gray-500 ml-1">from last month</span>
      </div>
    </div>
  )
}

function QuickActionCard({ 
  title, 
  subtitle, 
  href, 
  icon: Icon 
}: { 
  title: string
  subtitle: string
  href: string
  icon: any
}) {
  return (
    <Link href={href} className="block">
      <div className="bg-white p-6 rounded-lg border border-gray-200 hover:shadow-md transition-shadow">
        <div className="flex items-center">
          <div className="p-3 bg-gray-50 rounded-lg">
            <Icon className="h-6 w-6 text-gray-600" />
          </div>
          <div className="ml-4">
            <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
            <p className="text-sm text-gray-600">{subtitle}</p>
          </div>
        </div>
      </div>
    </Link>
  )
}


