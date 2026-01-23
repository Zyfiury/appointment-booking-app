// PostgreSQL migrations - not used with JSON database
// import { Pool } from 'pg';

export async function initializeDatabase(pool: any): Promise<void> {
  const client = await pool.connect();
  try {
    // Create customers table (separate from providers)
    await client.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id VARCHAR(255) PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(50),
        profile_picture TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create providers table (separate from customers)
    await client.query(`
      CREATE TABLE IF NOT EXISTS providers (
        id VARCHAR(255) PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(50),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        address TEXT,
        profile_picture TEXT,
        stripe_account_id VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Migrate existing users data to customers/providers if users table exists
    await client.query(`
      DO $$ 
      BEGIN
        -- Check if users table exists and has data
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='users') THEN
          -- Migrate customers
          INSERT INTO customers (id, email, password, name, phone, profile_picture, created_at)
          SELECT id, email, password, name, phone, profile_picture, created_at
          FROM users
          WHERE role = 'customer'
          ON CONFLICT (id) DO NOTHING;

          -- Migrate providers
          INSERT INTO providers (id, email, password, name, phone, latitude, longitude, address, profile_picture, stripe_account_id, created_at)
          SELECT id, email, password, name, phone, latitude, longitude, address, profile_picture, stripe_account_id, created_at
          FROM users
          WHERE role = 'provider'
          ON CONFLICT (id) DO NOTHING;
        END IF;
      END $$;
    `);

    // Create services table (references providers)
    await client.query(`
      CREATE TABLE IF NOT EXISTS services (
        id VARCHAR(255) PRIMARY KEY,
        provider_id VARCHAR(255) NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        duration INTEGER NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        category VARCHAR(100) NOT NULL,
        capacity INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Add capacity column to existing services table if it doesn't exist
    await client.query(`
      DO $$ 
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name='services' AND column_name='capacity') THEN
          ALTER TABLE services ADD COLUMN capacity INTEGER NOT NULL DEFAULT 1;
        END IF;
      END $$;
    `);

    // Create availability table for provider schedules
    await client.query(`
      CREATE TABLE IF NOT EXISTS availability (
        id VARCHAR(255) PRIMARY KEY,
        provider_id VARCHAR(255) NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
        day_of_week VARCHAR(20) NOT NULL CHECK (day_of_week IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        breaks TEXT[], -- Array of break time ranges like ['12:00-13:00']
        is_available BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(provider_id, day_of_week)
      )
    `);

    // Create index for availability queries
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_availability_provider_id ON availability(provider_id);
    `);

    // Create availability exceptions table (date-specific overrides)
    await client.query(`
      CREATE TABLE IF NOT EXISTS availability_exceptions (
        id VARCHAR(255) PRIMARY KEY,
        provider_id VARCHAR(255) NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        start_time TIME,
        end_time TIME,
        breaks TEXT[],
        is_available BOOLEAN NOT NULL DEFAULT true,
        note TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(provider_id, date)
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_availability_exceptions_provider_date 
        ON availability_exceptions(provider_id, date);
    `);

    // Create appointments table (references customers and providers separately)
    await client.query(`
      CREATE TABLE IF NOT EXISTS appointments (
        id VARCHAR(255) PRIMARY KEY,
        customer_id VARCHAR(255) NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
        provider_id VARCHAR(255) NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
        service_id VARCHAR(255) NOT NULL REFERENCES services(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        time TIME NOT NULL,
        status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create payments table
    await client.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id VARCHAR(255) PRIMARY KEY,
        appointment_id VARCHAR(255) NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
        amount DECIMAL(10, 2) NOT NULL,
        currency VARCHAR(10) NOT NULL DEFAULT 'USD',
        status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
        payment_method VARCHAR(100) NOT NULL,
        transaction_id VARCHAR(255),
        platform_commission DECIMAL(10, 2) NOT NULL DEFAULT 0,
        provider_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
        commission_rate DECIMAL(5, 2) NOT NULL DEFAULT 15.00,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Add commission columns to existing payments table if they don't exist (for existing databases)
    await client.query(`
      DO $$ 
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name='payments' AND column_name='platform_commission') THEN
          ALTER TABLE payments ADD COLUMN platform_commission DECIMAL(10, 2) NOT NULL DEFAULT 0;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name='payments' AND column_name='provider_amount') THEN
          ALTER TABLE payments ADD COLUMN provider_amount DECIMAL(10, 2) NOT NULL DEFAULT 0;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name='payments' AND column_name='commission_rate') THEN
          ALTER TABLE payments ADD COLUMN commission_rate DECIMAL(5, 2) NOT NULL DEFAULT 15.00;
        END IF;
      END $$;
    `);

    // Create reviews table (references customers and providers separately)
    await client.query(`
      CREATE TABLE IF NOT EXISTS reviews (
        id VARCHAR(255) PRIMARY KEY,
        appointment_id VARCHAR(255) NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
        provider_id VARCHAR(255) NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
        customer_id VARCHAR(255) NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
        rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        photos TEXT[],
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Update foreign keys if they still reference users table (for existing databases)
    await client.query(`
      DO $$ 
      BEGIN
        -- Drop old foreign keys if they exist and update to new tables
        IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='services_provider_id_fkey' 
                   AND table_name='services') THEN
          ALTER TABLE services DROP CONSTRAINT services_provider_id_fkey;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='appointments_customer_id_fkey' 
                   AND table_name='appointments') THEN
          ALTER TABLE appointments DROP CONSTRAINT appointments_customer_id_fkey;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='appointments_provider_id_fkey' 
                   AND table_name='appointments') THEN
          ALTER TABLE appointments DROP CONSTRAINT appointments_provider_id_fkey;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='reviews_provider_id_fkey' 
                   AND table_name='reviews') THEN
          ALTER TABLE reviews DROP CONSTRAINT reviews_provider_id_fkey;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='reviews_customer_id_fkey' 
                   AND table_name='reviews') THEN
          ALTER TABLE reviews DROP CONSTRAINT reviews_customer_id_fkey;
        END IF;

        -- Add new foreign keys
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name='services_provider_id_fkey' 
                       AND table_name='services') THEN
          ALTER TABLE services ADD CONSTRAINT services_provider_id_fkey 
            FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name='appointments_customer_id_fkey' 
                       AND table_name='appointments') THEN
          ALTER TABLE appointments ADD CONSTRAINT appointments_customer_id_fkey 
            FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name='appointments_provider_id_fkey' 
                       AND table_name='appointments') THEN
          ALTER TABLE appointments ADD CONSTRAINT appointments_provider_id_fkey 
            FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name='reviews_provider_id_fkey' 
                       AND table_name='reviews') THEN
          ALTER TABLE reviews ADD CONSTRAINT reviews_provider_id_fkey 
            FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name='reviews_customer_id_fkey' 
                       AND table_name='reviews') THEN
          ALTER TABLE reviews ADD CONSTRAINT reviews_customer_id_fkey 
            FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;
        END IF;
      END $$;
    `);

    // Create indexes for better query performance
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
      CREATE INDEX IF NOT EXISTS idx_providers_email ON providers(email);
      CREATE INDEX IF NOT EXISTS idx_services_provider_id ON services(provider_id);
      CREATE INDEX IF NOT EXISTS idx_appointments_customer_id ON appointments(customer_id);
      CREATE INDEX IF NOT EXISTS idx_appointments_provider_id ON appointments(provider_id);
      CREATE INDEX IF NOT EXISTS idx_payments_appointment_id ON payments(appointment_id);
      CREATE INDEX IF NOT EXISTS idx_reviews_provider_id ON reviews(provider_id);
      CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON reviews(customer_id);
    `);

    console.log('✅ Database tables initialized successfully');
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    throw error;
  } finally {
    client.release();
  }
}
