-- Demo Database Initialization
-- Creates isolated schema with RLS policies

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Demo schema
CREATE SCHEMA IF NOT EXISTS demo;

-- Demo users table (isolated from production)
CREATE TABLE IF NOT EXISTS demo.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  company_name VARCHAR(255),
  demo_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '7 days',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Demo products table (fake products)
CREATE TABLE IF NOT EXISTS demo.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'CLP',
  image_url TEXT,
  category VARCHAR(100),
  stock INTEGER DEFAULT 100,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Demo orders table
CREATE TABLE IF NOT EXISTS demo.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES demo.users(id) ON DELETE CASCADE,
  total DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  items JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Demo conversations table (fake chat history)
CREATE TABLE IF NOT EXISTS demo.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES demo.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  sender VARCHAR(50) NOT NULL, -- 'user' or 'bot'
  sentiment VARCHAR(20), -- 'positive', 'neutral', 'negative'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Demo analytics table
CREATE TABLE IF NOT EXISTS demo.analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES demo.users(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security policies
ALTER TABLE demo.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE demo.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE demo.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE demo.analytics ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data
CREATE POLICY "users_isolation" ON demo.users
  FOR ALL USING (id = current_setting('app.current_user_id', TRUE)::UUID);

CREATE POLICY "orders_isolation" ON demo.orders
  FOR ALL USING (user_id = current_setting('app.current_user_id', TRUE)::UUID);

CREATE POLICY "conversations_isolation" ON demo.conversations
  FOR ALL USING (user_id = current_setting('app.current_user_id', TRUE)::UUID);

CREATE POLICY "analytics_isolation" ON demo.analytics
  FOR ALL USING (user_id = current_setting('app.current_user_id', TRUE)::UUID);

-- Products are public (no isolation needed)
CREATE POLICY "products_public" ON demo.products FOR SELECT USING (true);

-- Indexes for performance
CREATE INDEX idx_users_email ON demo.users(email);
CREATE INDEX idx_users_demo_expires ON demo.users(demo_expires_at);
CREATE INDEX idx_orders_user_id ON demo.orders(user_id);
CREATE INDEX idx_orders_created_at ON demo.orders(created_at);
CREATE INDEX idx_conversations_user_id ON demo.conversations(user_id);
CREATE INDEX idx_analytics_user_id ON demo.analytics(user_id);
CREATE INDEX idx_analytics_event_type ON demo.analytics(event_type);

-- Demo user for testing (password: demo123)
INSERT INTO demo.users (email, full_name, company_name) VALUES
  ('demo@smarterbot.cl', 'Usuario Demo', 'Demo Company')
ON CONFLICT (email) DO NOTHING;

COMMENT ON SCHEMA demo IS 'Isolated demo environment - Auto-cleanup after 7 days';
