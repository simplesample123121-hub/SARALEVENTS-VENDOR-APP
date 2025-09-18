-- Event Planning Database Schema for Saral Events
-- This schema supports comprehensive event planning with real-time collaboration

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret-here';

-- Events table
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('wedding', 'birthday', 'houseParty', 'corporate', 'anniversary', 'graduation', 'babyShower', 'engagement', 'other')),
    event_date TIMESTAMPTZ NOT NULL,
    image_url TEXT,
    description TEXT,
    venue TEXT,
    venue_address TEXT,
    venue_latitude DECIMAL(10, 8),
    venue_longitude DECIMAL(11, 8),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('paid', 'pending', 'overdue', 'cancelled')),
    budget DECIMAL(12, 2),
    spent_amount DECIMAL(12, 2) DEFAULT 0,
    expected_guests INTEGER,
    actual_guests INTEGER,
    is_public BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    shared_with UUID[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Checklist tasks table
CREATE TABLE IF NOT EXISTS public.checklist_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT false,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
    due_date TIMESTAMPTZ,
    assigned_to UUID REFERENCES auth.users(id),
    category TEXT DEFAULT 'general',
    estimated_cost DECIMAL(10, 2),
    actual_cost DECIMAL(10, 2),
    attachments JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Guest categories table
CREATE TABLE IF NOT EXISTS public.guest_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#2196F3',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Guests table
CREATE TABLE IF NOT EXISTS public.guests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES public.guest_categories(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    is_invited BOOLEAN DEFAULT false,
    invitation_sent_at TIMESTAMPTZ,
    has_responded BOOLEAN DEFAULT false,
    is_attending BOOLEAN DEFAULT false,
    response_date TIMESTAMPTZ,
    plus_one_count INTEGER DEFAULT 0,
    dietary_restrictions TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event notes table
CREATE TABLE IF NOT EXISTS public.event_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    is_pinned BOOLEAN DEFAULT false,
    attachments JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Budget items table
CREATE TABLE IF NOT EXISTS public.budget_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    item_name TEXT NOT NULL,
    estimated_cost DECIMAL(10, 2) NOT NULL,
    actual_cost DECIMAL(10, 2),
    vendor_name TEXT,
    vendor_contact TEXT,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('paid', 'pending', 'overdue', 'cancelled')),
    payment_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event timeline/schedule table
CREATE TABLE IF NOT EXISTS public.event_timeline (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    location TEXT,
    responsible_person TEXT,
    is_milestone BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event collaborators table
CREATE TABLE IF NOT EXISTS public.event_collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('owner', 'editor', 'viewer')),
    invited_by UUID REFERENCES auth.users(id),
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    UNIQUE(event_id, user_id)
);

-- Event activity log table
CREATE TABLE IF NOT EXISTS public.event_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_events_user_id ON public.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_event_date ON public.events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON public.events(event_type);
CREATE INDEX IF NOT EXISTS idx_checklist_tasks_event_id ON public.checklist_tasks(event_id);
CREATE INDEX IF NOT EXISTS idx_checklist_tasks_due_date ON public.checklist_tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_guests_event_id ON public.guests(event_id);
CREATE INDEX IF NOT EXISTS idx_guests_category_id ON public.guests(category_id);
CREATE INDEX IF NOT EXISTS idx_event_notes_event_id ON public.event_notes(event_id);
CREATE INDEX IF NOT EXISTS idx_budget_items_event_id ON public.budget_items(event_id);
CREATE INDEX IF NOT EXISTS idx_event_timeline_event_id ON public.event_timeline(event_id);
CREATE INDEX IF NOT EXISTS idx_event_collaborators_event_id ON public.event_collaborators(event_id);
CREATE INDEX IF NOT EXISTS idx_event_activity_log_event_id ON public.event_activity_log(event_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_checklist_tasks_updated_at BEFORE UPDATE ON public.checklist_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_guest_categories_updated_at BEFORE UPDATE ON public.guest_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_guests_updated_at BEFORE UPDATE ON public.guests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_event_notes_updated_at BEFORE UPDATE ON public.event_notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budget_items_updated_at BEFORE UPDATE ON public.budget_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_event_timeline_updated_at BEFORE UPDATE ON public.event_timeline FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security Policies

-- Events policies
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own events" ON public.events
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = ANY(shared_with));

CREATE POLICY "Users can insert their own events" ON public.events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own events" ON public.events
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = ANY(shared_with));

CREATE POLICY "Users can delete their own events" ON public.events
    FOR DELETE USING (auth.uid() = user_id);

-- Checklist tasks policies
ALTER TABLE public.checklist_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tasks for their events" ON public.checklist_tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = checklist_tasks.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

CREATE POLICY "Users can insert tasks for their events" ON public.checklist_tasks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = checklist_tasks.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

CREATE POLICY "Users can update tasks for their events" ON public.checklist_tasks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = checklist_tasks.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

CREATE POLICY "Users can delete tasks for their events" ON public.checklist_tasks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = checklist_tasks.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Similar policies for other tables
ALTER TABLE public.guest_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_activity_log ENABLE ROW LEVEL SECURITY;

-- Guest categories policies
CREATE POLICY "Users can manage guest categories for their events" ON public.guest_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = guest_categories.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Guests policies
CREATE POLICY "Users can manage guests for their events" ON public.guests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = guests.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Event notes policies
CREATE POLICY "Users can manage notes for their events" ON public.event_notes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = event_notes.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Budget items policies
CREATE POLICY "Users can manage budget items for their events" ON public.budget_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = budget_items.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Event timeline policies
CREATE POLICY "Users can manage timeline for their events" ON public.event_timeline
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = event_timeline.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Event collaborators policies
CREATE POLICY "Users can view collaborators for their events" ON public.event_collaborators
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = event_collaborators.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

CREATE POLICY "Event owners can manage collaborators" ON public.event_collaborators
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = event_collaborators.event_id 
            AND events.user_id = auth.uid()
        )
    );

-- Event activity log policies
CREATE POLICY "Users can view activity for their events" ON public.event_activity_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = event_activity_log.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

CREATE POLICY "Users can insert activity for their events" ON public.event_activity_log
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE events.id = event_activity_log.event_id 
            AND (events.user_id = auth.uid() OR auth.uid() = ANY(events.shared_with))
        )
    );

-- Enable real-time for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.checklist_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.guest_categories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.guests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_notes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.budget_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_timeline;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_collaborators;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_activity_log;

-- Create views for better data access
CREATE OR REPLACE VIEW public.event_statistics AS
SELECT 
    e.id as event_id,
    e.name as event_name,
    e.user_id,
    COUNT(DISTINCT ct.id) as total_tasks,
    COUNT(DISTINCT CASE WHEN ct.is_completed THEN ct.id END) as completed_tasks,
    COALESCE(ROUND((COUNT(DISTINCT CASE WHEN ct.is_completed THEN ct.id END)::DECIMAL / NULLIF(COUNT(DISTINCT ct.id), 0)) * 100, 2), 0) as task_completion_percentage,
    COUNT(DISTINCT g.id) as total_guests,
    COUNT(DISTINCT CASE WHEN g.is_attending THEN g.id END) as attending_guests,
    COALESCE(SUM(bi.estimated_cost), 0) as total_budget,
    COALESCE(SUM(bi.actual_cost), 0) as total_spent,
    COALESCE(ROUND((SUM(bi.actual_cost) / NULLIF(SUM(bi.estimated_cost), 0)) * 100, 2), 0) as budget_used_percentage
FROM public.events e
LEFT JOIN public.checklist_tasks ct ON e.id = ct.event_id
LEFT JOIN public.guests g ON e.id = g.event_id
LEFT JOIN public.budget_items bi ON e.id = bi.event_id
GROUP BY e.id, e.name, e.user_id;

-- Grant permissions on the view
GRANT SELECT ON public.event_statistics TO authenticated;

-- Create function to log activity
CREATE OR REPLACE FUNCTION log_event_activity(
    p_event_id UUID,
    p_action TEXT,
    p_details JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.event_activity_log (event_id, user_id, action, details)
    VALUES (p_event_id, auth.uid(), p_action, p_details);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get event dashboard data
CREATE OR REPLACE FUNCTION get_event_dashboard(p_event_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'event', to_jsonb(e.*),
        'statistics', to_jsonb(es.*),
        'recent_activity', (
            SELECT jsonb_agg(to_jsonb(eal.*))
            FROM public.event_activity_log eal
            WHERE eal.event_id = p_event_id
            ORDER BY eal.created_at DESC
            LIMIT 10
        ),
        'upcoming_tasks', (
            SELECT jsonb_agg(to_jsonb(ct.*))
            FROM public.checklist_tasks ct
            WHERE ct.event_id = p_event_id
            AND ct.is_completed = false
            AND ct.due_date IS NOT NULL
            ORDER BY ct.due_date ASC
            LIMIT 5
        )
    ) INTO result
    FROM public.events e
    LEFT JOIN public.event_statistics es ON e.id = es.event_id
    WHERE e.id = p_event_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample data insertion (for development)
-- This will be handled by the Flutter app initialization