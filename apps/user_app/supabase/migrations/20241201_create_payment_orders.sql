-- Create payment_orders table to track Razorpay orders
CREATE TABLE IF NOT EXISTS payment_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  razorpay_order_id TEXT UNIQUE NOT NULL,
  amount BIGINT NOT NULL, -- Amount in paise
  currency TEXT NOT NULL DEFAULT 'INR',
  receipt TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'created',
  notes JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_payment_orders_razorpay_id ON payment_orders(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_status ON payment_orders(status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_created_at ON payment_orders(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_payment_orders_updated_at 
    BEFORE UPDATE ON payment_orders 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS (Row Level Security)
ALTER TABLE payment_orders ENABLE ROW LEVEL SECURITY;

-- Create policy to allow authenticated users to read their own orders
CREATE POLICY "Users can view their own payment orders" ON payment_orders
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Create policy to allow service role to insert orders (for the Edge Function)
CREATE POLICY "Service role can insert payment orders" ON payment_orders
    FOR INSERT WITH CHECK (true);

-- Create policy to allow service role to update orders
CREATE POLICY "Service role can update payment orders" ON payment_orders
    FOR UPDATE USING (true);

-- Grant necessary permissions
GRANT SELECT ON payment_orders TO authenticated;
GRANT INSERT, UPDATE ON payment_orders TO service_role;
