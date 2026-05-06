-- ==========================================
-- BLISSFRUITZ FULL DATABASE SETUP
-- ==========================================

-- 1. SETTINGS & CONFIGURATION TABLES
CREATE TABLE IF NOT EXISTS settings_general (id BIGINT PRIMARY KEY DEFAULT 1, site_name TEXT DEFAULT 'BlissFruitz', logo TEXT, favicon TEXT, email TEXT, phone TEXT, address TEXT, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_payment (id BIGINT PRIMARY KEY DEFAULT 1, currency TEXT DEFAULT 'INR', cod_enabled BOOLEAN DEFAULT TRUE, razorpay_enabled BOOLEAN DEFAULT FALSE, razorpay_key_id TEXT, razorpay_key_secret TEXT, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_shipping (id BIGINT PRIMARY KEY DEFAULT 1, flat_rate NUMERIC DEFAULT 50, free_shipping_min NUMERIC DEFAULT 500, delivery_eta_note TEXT DEFAULT 'Delivered within 24-48 hours', updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_maintenance (id BIGINT PRIMARY KEY DEFAULT 1, enabled BOOLEAN DEFAULT FALSE, message TEXT DEFAULT 'Under maintenance', updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_app_update (id BIGINT PRIMARY KEY DEFAULT 1, latest_version TEXT DEFAULT '1.0.0', apk_url TEXT, force_update BOOLEAN DEFAULT FALSE, update_notes TEXT, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_product_catalog (id BIGINT PRIMARY KEY DEFAULT 1, show_out_of_stock BOOLEAN DEFAULT TRUE, low_stock_threshold INTEGER DEFAULT 5, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_ui_theme (id BIGINT PRIMARY KEY DEFAULT 1, primary_color TEXT DEFAULT '#4CAF50', dark_mode_enabled BOOLEAN DEFAULT FALSE, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_security (id BIGINT PRIMARY KEY DEFAULT 1, max_login_attempts INTEGER DEFAULT 5, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_analytics (id BIGINT PRIMARY KEY DEFAULT 1, google_analytics_id TEXT, updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS settings_coupon_defaults (id BIGINT PRIMARY KEY DEFAULT 1, default_expiry_days INTEGER DEFAULT 30, updated_at TIMESTAMPTZ DEFAULT NOW());

-- Seed initial settings
INSERT INTO settings_general (id, site_name) VALUES (1, 'BlissFruitz') ON CONFLICT (id) DO NOTHING;
INSERT INTO settings_payment (id, cod_enabled, razorpay_enabled) VALUES (1, TRUE, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO settings_shipping (id, flat_rate, free_shipping_min) VALUES (1, 50, 500) ON CONFLICT (id) DO NOTHING;
INSERT INTO settings_maintenance (id, enabled) VALUES (1, FALSE) ON CONFLICT (id) DO NOTHING;

-- 2. CORE BUSINESS ENTITIES
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    image TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL,
    old_price NUMERIC,
    image_main TEXT,
    images TEXT[],
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    stock_quantity INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT DEFAULT 'percentage',
    discount_value NUMERIC NOT NULL,
    min_order NUMERIC DEFAULT 0,
    max_discount NUMERIC,
    is_active BOOLEAN DEFAULT TRUE,
    expiry_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. USERS & PROFILES
CREATE TABLE IF NOT EXISTS "User" (
    "id" SERIAL PRIMARY KEY,
    "supabaseId" UUID UNIQUE NOT NULL,
    "email" TEXT UNIQUE NOT NULL,
    "fullName" TEXT,
    "username" TEXT,
    "avatarUrl" TEXT,
    "role" TEXT DEFAULT 'customer',
    "isActive" BOOLEAN DEFAULT TRUE,
    "createdAt" TIMESTAMPTZ DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "User"("supabaseId") ON DELETE CASCADE,
    label TEXT DEFAULT 'Home',
    full_name TEXT,
    phone TEXT,
    address_line TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    latitude NUMERIC,
    longitude NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ORDER SYSTEM
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number SERIAL,
    user_id UUID REFERENCES "User"("supabaseId") ON DELETE SET NULL,
    customer_name TEXT,
    customer_phone TEXT,
    customer_email TEXT,
    shipping_address TEXT,
    subtotal NUMERIC,
    shipping_fee NUMERIC,
    discount_amount NUMERIC,
    total_amount NUMERIC,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'pending',
    order_status TEXT DEFAULT 'placed',
    order_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name TEXT,
    price NUMERIC,
    quantity INTEGER,
    total_price NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. RIDER APP TABLES
CREATE TABLE IF NOT EXISTS riders (
    id UUID PRIMARY KEY, -- Maps to Supabase Auth ID
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    vehicle_number TEXT,
    is_available BOOLEAN DEFAULT FALSE,
    current_latitude NUMERIC,
    current_longitude NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. PROMOTIONS & SOCIAL
CREATE TABLE IF NOT EXISTS banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url TEXT NOT NULL,
    link_to TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    highlight BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES "User"("supabaseId") ON DELETE SET NULL,
    user_name TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
