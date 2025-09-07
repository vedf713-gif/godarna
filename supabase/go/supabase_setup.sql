-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role AS ENUM ('tenant', 'host', 'admin');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed');
CREATE TYPE payment_method AS ENUM ('cash_on_delivery', 'online');

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    avatar TEXT,
    role user_role DEFAULT 'tenant',
    is_email_verified BOOLEAN DEFAULT FALSE,
    language VARCHAR(5) DEFAULT 'ar',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create properties table
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    property_type VARCHAR(50) NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL,
    price_per_month DECIMAL(10,2),
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    area VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    bedrooms INTEGER DEFAULT 0,
    bathrooms INTEGER DEFAULT 0,
    max_guests INTEGER DEFAULT 1,
    amenities TEXT[],
    photos TEXT[],
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create bookings table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    host_id UUID REFERENCES users(id) ON DELETE CASCADE,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    nights INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status booking_status DEFAULT 'pending',
    payment_method payment_method DEFAULT 'cash_on_delivery',
    payment_status payment_status DEFAULT 'pending',
    notes TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    review_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_properties_host_id ON properties(host_id);
CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_property_type ON properties(property_type);
CREATE INDEX idx_properties_price ON properties(price_per_night);
CREATE INDEX idx_properties_location ON properties(latitude, longitude);
CREATE INDEX idx_bookings_property_id ON bookings(property_id);
CREATE INDEX idx_bookings_tenant_id ON bookings(tenant_id);
CREATE INDEX idx_bookings_host_id ON bookings(host_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Create functions for automatic timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamps
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_properties_updated_at BEFORE UPDATE ON properties
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update property rating
CREATE OR REPLACE FUNCTION update_property_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE properties 
    SET 
        rating = (
            SELECT AVG(rating)::DECIMAL(3,2)
            FROM bookings 
            WHERE property_id = NEW.property_id 
            AND rating IS NOT NULL
        ),
        review_count = (
            SELECT COUNT(*)
            FROM bookings 
            WHERE property_id = NEW.property_id 
            AND rating IS NOT NULL
        )
    WHERE id = NEW.property_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update property rating when review is added
CREATE TRIGGER update_property_rating_trigger
    AFTER UPDATE OF rating ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_property_rating();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Properties policies
CREATE POLICY "Anyone can view active properties" ON properties
    FOR SELECT USING (is_active = true);

CREATE POLICY "Hosts can manage their own properties" ON properties
    FOR ALL USING (
        host_id = auth.uid() AND 
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role IN ('host', 'admin')
        )
    );

CREATE POLICY "Admins can manage all properties" ON properties
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Bookings policies
CREATE POLICY "Users can view their own bookings" ON bookings
    FOR SELECT USING (
        tenant_id = auth.uid() OR 
        host_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Tenants can create bookings" ON bookings
    FOR INSERT WITH CHECK (
        tenant_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'tenant'
        )
    );

CREATE POLICY "Hosts can update their property bookings" ON bookings
    FOR UPDATE USING (
        host_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role IN ('host', 'admin')
        )
    );

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- Insert sample data for testing
INSERT INTO users (id, email, first_name, last_name, role, is_email_verified, language) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'admin@godarna.ma', 'مدير', 'النظام', 'admin', true, 'ar'),
    ('550e8400-e29b-41d4-a716-446655440001', 'host@godarna.ma', 'أحمد', 'المالك', 'host', true, 'ar'),
    ('550e8400-e29b-41d4-a716-446655440002', 'tenant@godarna.ma', 'فاطمة', 'المستأجرة', 'tenant', true, 'ar');

-- Insert sample properties
INSERT INTO properties (host_id, title, description, property_type, price_per_night, city, address, bedrooms, bathrooms, max_guests, amenities) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'شقة جميلة في قلب الدار البيضاء', 'شقة حديثة ومريحة في منطقة هادئة', 'apartment', 300.00, 'الدار البيضاء', 'شارع محمد الخامس، الدار البيضاء', 2, 1, 4, ARRAY['مكيف هواء', 'واي فاي', 'مطبخ']),
    ('550e8400-e29b-41d4-a716-446655440001', 'فيلا فاخرة في مراكش', 'فيلا خاصة مع حديقة وبركة سباحة', 'villa', 800.00, 'مراكش', 'حي النخيل، مراكش', 3, 2, 6, ARRAY['بركة سباحة', 'حديقة', 'موقف سيارات', 'مكيف هواء']);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;