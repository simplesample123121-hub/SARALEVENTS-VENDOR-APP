-- Event Planning Database Schema for Supabase
-- This file contains all the necessary tables, indexes, and policies for the event planning app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE event_type AS ENUM (
  'wedding', 'birthday', 'houseParty', 'corporate', 
  'anniversary', 'graduation', 'babyShower', 'engagement', 'other'
);

CREATE TYPE payment_status AS ENUM (
  'paid', 'pending', 'overdue', 'cancelled'
);

CREATE TYPE task_priority AS ENUM (
  'high', 'medium', 'low'
);

CREATE TYPE collaborator_role AS ENUM (
  'owner', 'editor', 'viewer'
);

CREATE TYPE activity_type AS ENUM (
  'eventCreated', 'eventUpdated', 'taskAdded', 'taskCompleted', 
  'guestAdded', 'noteAdded', 'budgetUpdated', 'collaboratorAdded'
);

-- Events table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  event_type event_type NOT NULL,
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  image_url TEXT,
  description TEXT,
  venue VARCHAR(255),
  venue_address TEXT,
  venue_latitude DECIMAL(10, 8),
  venue_longitude DECIMAL(11, 8),
  payment_status payment_status NOT NULL DEFAULT 'pending',
  budget DECIMAL(12, 2),
  spent_amount DECIMAL(12, 2) DEFAULT 0,
  expected_guests INTEGER,
  actual_guests INTEGER,
  is_public BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  shared_with UUID[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Checklist tasks table
CREATE TABLE checklist_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  priority task_priority NOT NULL DEFAULT 'medium',
  due_date TIMESTAMP WITH TIME ZONE,
  assigned_to VARCHAR(255),
  category VARCHAR(100) DEFAULT 'general',
  estimated_cost DECIMAL(10, 2),
  actual_cost DECIMAL(10, 2),
  attachments TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Budget items table
CREATE TABLE budget_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  item_name VARCHAR(255) NOT NULL,
  estimated_cost DECIMAL(10, 2) NOT NULL,
  actual_cost DECIMAL(10, 2),
  vendor_name VARCHAR(255),
  vendor_contact VARCHAR(50),
  payment_status payment_status DEFAULT 'pending',
  payment_date TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event timeline table
CREATE TABLE event_timeline (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  location VARCHAR(255),
  responsible_person VARCHAR(255),
  is_milestone BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event notes table
CREATE TABLE event_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  category VARCHAR(100) DEFAULT 'general',
  is_pinned BOOLEAN DEFAULT FALSE,
  attachments TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guest categories table
CREATE TABLE guest_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  guest_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guests table
CREATE TABLE guests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID NOT NULL REFERENCES guest_categories(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  is_invited BOOLEAN DEFAULT FALSE,
  has_responded BOOLEAN DEFAULT FALSE,
  is_attending BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event activity log table
CREATE TABLE event_activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action activity_type NOT NULL,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event statistics view (computed)
CREATE TABLE event_statistics (
  event_id UUID PRIMARY KEY REFERENCES events(id) ON DELETE CASCADE,
  total_tasks INTEGER DEFAULT 0,
  completed_tasks INTEGER DEFAULT 0,
  task_completion_percentage DECIMAL(5, 2) DEFAULT 0,
  total_guests INTEGER DEFAULT 0,
  attending_guests INTEGER DEFAULT 0,
  total_budget DECIMAL(12, 2) DEFAULT 0,
  total_spent DECIMAL(12, 2) DEFAULT 0,
  budget_used_percentage DECIMAL(5, 2) DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_event_date ON events(event_date);
CREATE INDEX idx_events_is_archived ON events(is_archived);
CREATE INDEX idx_events_shared_with ON events USING GIN(shared_with);

CREATE INDEX idx_checklist_tasks_event_id ON checklist_tasks(event_id);
CREATE INDEX idx_checklist_tasks_due_date ON checklist_tasks(due_date);
CREATE INDEX idx_checklist_tasks_is_completed ON checklist_tasks(is_completed);

CREATE INDEX idx_budget_items_event_id ON budget_items(event_id);
CREATE INDEX idx_budget_items_category ON budget_items(category);

CREATE INDEX idx_event_timeline_event_id ON event_timeline(event_id);
CREATE INDEX idx_event_timeline_start_time ON event_timeline(start_time);

CREATE INDEX idx_event_notes_event_id ON event_notes(event_id);
CREATE INDEX idx_event_notes_user_id ON event_notes(user_id);

CREATE INDEX idx_guest_categories_event_id ON guest_categories(event_id);

CREATE INDEX idx_guests_category_id ON guests(category_id);
CREATE INDEX idx_guests_is_attending ON guests(is_attending);

CREATE INDEX idx_event_activity_log_event_id ON event_activity_log(event_id);
CREATE INDEX idx_event_activity_log_user_id ON event_activity_log(user_id);
CREATE INDEX idx_event_activity_log_created_at ON event_activity_log(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_checklist_tasks_updated_at BEFORE UPDATE ON checklist_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budget_items_updated_at BEFORE UPDATE ON budget_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_timeline_updated_at BEFORE UPDATE ON event_timeline
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_notes_updated_at BEFORE UPDATE ON event_notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guest_categories_updated_at BEFORE UPDATE ON guest_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guests_updated_at BEFORE UPDATE ON guests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update event statistics
CREATE OR REPLACE FUNCTION update_event_statistics(event_uuid UUID)
RETURNS VOID AS $$
DECLARE
  task_stats RECORD;
  guest_stats RECORD;
  budget_stats RECORD;
BEGIN
  -- Get task statistics
  SELECT 
    COUNT(*) as total_tasks,
    COUNT(*) FILTER (WHERE is_completed = true) as completed_tasks
  INTO task_stats
  FROM checklist_tasks 
  WHERE event_id = event_uuid;

  -- Get guest statistics
  SELECT 
    COALESCE(SUM(guest_count), 0) as total_guests,
    COALESCE(SUM(guest_count) FILTER (WHERE EXISTS (
      SELECT 1 FROM guests g 
      WHERE g.category_id = gc.id AND g.is_attending = true
    )), 0) as attending_guests
  INTO guest_stats
  FROM guest_categories gc
  WHERE event_id = event_uuid;

  -- Get budget statistics
  SELECT 
    COALESCE(budget, 0) as total_budget,
    COALESCE(spent_amount, 0) as total_spent
  INTO budget_stats
  FROM events 
  WHERE id = event_uuid;

  -- Update or insert statistics
  INSERT INTO event_statistics (
    event_id, total_tasks, completed_tasks, task_completion_percentage,
    total_guests, attending_guests, total_budget, total_spent, 
    budget_used_percentage, last_updated
  ) VALUES (
    event_uuid,
    task_stats.total_tasks,
    task_stats.completed_tasks,
    CASE 
      WHEN task_stats.total_tasks > 0 
      THEN (task_stats.completed_tasks::DECIMAL / task_stats.total_tasks) * 100 
      ELSE 0 
    END,
    guest_stats.total_guests,
    guest_stats.attending_guests,
    budget_stats.total_budget,
    budget_stats.total_spent,
    CASE 
      WHEN budget_stats.total_budget > 0 
      THEN (budget_stats.total_spent / budget_stats.total_budget) * 100 
      ELSE 0 
    END,
    NOW()
  )
  ON CONFLICT (event_id) DO UPDATE SET
    total_tasks = EXCLUDED.total_tasks,
    completed_tasks = EXCLUDED.completed_tasks,
    task_completion_percentage = EXCLUDED.task_completion_percentage,
    total_guests = EXCLUDED.total_guests,
    attending_guests = EXCLUDED.attending_guests,
    total_budget = EXCLUDED.total_budget,
    total_spent = EXCLUDED.total_spent,
    budget_used_percentage = EXCLUDED.budget_used_percentage,
    last_updated = NOW();
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update statistics
CREATE OR REPLACE FUNCTION trigger_update_event_statistics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update statistics for the affected event
  IF TG_TABLE_NAME = 'events' THEN
    PERFORM update_event_statistics(NEW.id);
  ELSIF TG_TABLE_NAME = 'checklist_tasks' THEN
    PERFORM update_event_statistics(NEW.event_id);
  ELSIF TG_TABLE_NAME = 'budget_items' THEN
    PERFORM update_event_statistics(NEW.event_id);
  ELSIF TG_TABLE_NAME = 'guest_categories' THEN
    PERFORM update_event_statistics(NEW.event_id);
  ELSIF TG_TABLE_NAME = 'guests' THEN
    -- Get event_id from category
    PERFORM update_event_statistics((
      SELECT gc.event_id 
      FROM guest_categories gc 
      WHERE gc.id = NEW.category_id
    ));
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Add triggers for statistics updates
CREATE TRIGGER trigger_events_stats_update
  AFTER INSERT OR UPDATE OR DELETE ON events
  FOR EACH ROW EXECUTE FUNCTION trigger_update_event_statistics();

CREATE TRIGGER trigger_checklist_tasks_stats_update
  AFTER INSERT OR UPDATE OR DELETE ON checklist_tasks
  FOR EACH ROW EXECUTE FUNCTION trigger_update_event_statistics();

CREATE TRIGGER trigger_budget_items_stats_update
  AFTER INSERT OR UPDATE OR DELETE ON budget_items
  FOR EACH ROW EXECUTE FUNCTION trigger_update_event_statistics();

CREATE TRIGGER trigger_guest_categories_stats_update
  AFTER INSERT OR UPDATE OR DELETE ON guest_categories
  FOR EACH ROW EXECUTE FUNCTION trigger_update_event_statistics();

CREATE TRIGGER trigger_guests_stats_update
  AFTER INSERT OR UPDATE OR DELETE ON guests
  FOR EACH ROW EXECUTE FUNCTION trigger_update_event_statistics();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_statistics ENABLE ROW LEVEL SECURITY;

-- Events policies
CREATE POLICY "Users can view their own events and shared events" ON events
  FOR SELECT USING (
    auth.uid() = user_id OR 
    auth.uid() = ANY(shared_with)
  );

CREATE POLICY "Users can insert their own events" ON events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own events" ON events
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own events" ON events
  FOR DELETE USING (auth.uid() = user_id);

-- Checklist tasks policies
CREATE POLICY "Users can view tasks for their events" ON checklist_tasks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can manage tasks for their events" ON checklist_tasks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Budget items policies
CREATE POLICY "Users can view budget items for their events" ON budget_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can manage budget items for their events" ON budget_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Event timeline policies
CREATE POLICY "Users can view timeline for their events" ON event_timeline
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can manage timeline for their events" ON event_timeline
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Event notes policies
CREATE POLICY "Users can view notes for their events" ON event_notes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can manage their own notes" ON event_notes
  FOR ALL USING (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Guest categories policies
CREATE POLICY "Users can view guest categories for their events" ON guest_categories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can manage guest categories for their events" ON guest_categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Guests policies
CREATE POLICY "Users can view guests for their events" ON guests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM guest_categories gc
      JOIN events e ON e.id = gc.event_id
      WHERE gc.id = category_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can manage guests for their events" ON guests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM guest_categories gc
      JOIN events e ON e.id = gc.event_id
      WHERE gc.id = category_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Event activity log policies
CREATE POLICY "Users can view activity for their events" ON event_activity_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

CREATE POLICY "Users can insert activity for their events" ON event_activity_log
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Event statistics policies
CREATE POLICY "Users can view statistics for their events" ON event_statistics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM events e 
      WHERE e.id = event_id 
      AND (e.user_id = auth.uid() OR auth.uid() = ANY(e.shared_with))
    )
  );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Create a function to initialize sample data (for development)
CREATE OR REPLACE FUNCTION initialize_sample_data(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
  event1_id UUID;
  event2_id UUID;
  cat1_id UUID;
  cat2_id UUID;
BEGIN
  -- Insert sample events
  INSERT INTO events (id, user_id, name, event_type, event_date, description, venue, venue_address, payment_status, budget, spent_amount, expected_guests)
  VALUES 
    (uuid_generate_v4(), user_uuid, 'Sample Wedding', 'wedding', NOW() + INTERVAL '30 days', 'A beautiful wedding celebration', 'Grand Palace Hotel', 'Banjara Hills, Hyderabad', 'pending', 500000, 150000, 150),
    (uuid_generate_v4(), user_uuid, 'Sample Birthday', 'birthday', NOW() + INTERVAL '15 days', 'Birthday party celebration', 'Rooftop Garden', 'Jubilee Hills, Hyderabad', 'paid', 50000, 45000, 50)
  RETURNING id INTO event1_id;
  
  -- Get the second event ID
  SELECT id INTO event2_id FROM events WHERE user_id = user_uuid AND name = 'Sample Birthday' LIMIT 1;
  
  -- Insert sample checklist tasks
  INSERT INTO checklist_tasks (event_id, title, description, is_completed, priority, due_date, category, estimated_cost, actual_cost)
  VALUES 
    (event1_id, 'Book Wedding Venue', 'Reserve the Grand Palace Hotel', true, 'high', NOW() + INTERVAL '25 days', 'venue', 200000, 200000),
    (event1_id, 'Book Photographer', 'Hire professional wedding photographer', false, 'high', NOW() + INTERVAL '20 days', 'photography', 50000, NULL),
    (event2_id, 'Order Birthday Cake', 'Chocolate cake with candles', true, 'high', NOW() + INTERVAL '5 days', 'catering', 3000, 2800);
  
  -- Insert sample budget items
  INSERT INTO budget_items (event_id, category, item_name, estimated_cost, actual_cost, vendor_name, payment_status)
  VALUES 
    (event1_id, 'Venue', 'Grand Palace Hotel Booking', 200000, 200000, 'Grand Palace Hotel', 'paid'),
    (event1_id, 'Photography', 'Wedding Photography Package', 50000, NULL, 'Perfect Moments Studio', 'pending'),
    (event2_id, 'Catering', 'Birthday Cake', 3000, 2800, 'Sweet Dreams Bakery', 'paid');
  
  -- Insert sample guest categories
  INSERT INTO guest_categories (event_id, name, guest_count)
  VALUES 
    (event1_id, 'Family', 50),
    (event1_id, 'Friends', 75),
    (event2_id, 'Close Friends', 30)
  RETURNING id INTO cat1_id;
  
  -- Get the second category ID
  SELECT id INTO cat2_id FROM guest_categories WHERE event_id = event1_id AND name = 'Friends' LIMIT 1;
  
  -- Insert sample guests
  INSERT INTO guests (category_id, name, email, is_invited, has_responded, is_attending)
  VALUES 
    (cat1_id, 'John Doe', 'john@example.com', true, true, true),
    (cat2_id, 'Jane Smith', 'jane@example.com', true, false, false);
  
  -- Insert sample timeline items
  INSERT INTO event_timeline (event_id, title, description, start_time, end_time, location, responsible_person, is_milestone)
  VALUES 
    (event1_id, 'Guest Arrival', 'Guests arrive and registration', NOW() + INTERVAL '30 days' + INTERVAL '16 hours', NOW() + INTERVAL '30 days' + INTERVAL '17 hours', 'Main Entrance', 'Reception Team', false),
    (event1_id, 'Wedding Ceremony', 'Main wedding ceremony', NOW() + INTERVAL '30 days' + INTERVAL '17 hours', NOW() + INTERVAL '30 days' + INTERVAL '18 hours 30 minutes', 'Main Hall', 'Wedding Coordinator', true);
  
  -- Insert sample notes
  INSERT INTO event_notes (event_id, user_id, title, content, category)
  VALUES 
    (event1_id, user_uuid, 'Important Notes', 'Remember to confirm with the photographer', 'general'),
    (event2_id, user_uuid, 'Birthday Ideas', 'Consider adding a photo booth', 'ideas');
END;
$$ LANGUAGE plpgsql;
