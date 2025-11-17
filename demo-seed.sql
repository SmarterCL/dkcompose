-- Demo Data Seeder - Fake products and sample data

-- Fake Products (Chilean e-commerce style)
INSERT INTO demo.products (name, description, price, currency, category, stock, is_featured, image_url) VALUES
  -- Electronics
  ('Smartphone Galaxy Pro', 'Último modelo con cámara de 108MP y 5G', 599990, 'CLP', 'Electrónica', 50, true, 'https://picsum.photos/seed/phone/400/400'),
  ('Notebook Gamer RGB', 'Intel i7, 16GB RAM, RTX 4060', 1299990, 'CLP', 'Electrónica', 25, true, 'https://picsum.photos/seed/laptop/400/400'),
  ('Auriculares Bluetooth Premium', 'Cancelación de ruido activa, 30hrs batería', 89990, 'CLP', 'Electrónica', 100, false, 'https://picsum.photos/seed/headphones/400/400'),
  ('Smartwatch Deportivo', 'Monitor cardíaco, GPS, resistente al agua', 149990, 'CLP', 'Electrónica', 75, true, 'https://picsum.photos/seed/watch/400/400'),
  
  -- Home & Living
  ('Cafetera Automática Espresso', 'Presión 19 bares, molinillo integrado', 299990, 'CLP', 'Hogar', 30, false, 'https://picsum.photos/seed/coffee/400/400'),
  ('Aspiradora Robot Inteligente', 'Mapeo láser, control por app', 249990, 'CLP', 'Hogar', 40, true, 'https://picsum.photos/seed/robot/400/400'),
  ('Smart TV 55" 4K HDR', 'Android TV, 120Hz, Dolby Atmos', 499990, 'CLP', 'Hogar', 20, true, 'https://picsum.photos/seed/tv/400/400'),
  
  -- Fashion
  ('Zapatillas Running Pro', 'Tecnología de amortiguación avanzada', 89990, 'CLP', 'Moda', 150, false, 'https://picsum.photos/seed/shoes/400/400'),
  ('Mochila Outdoor 40L', 'Impermeable, sistema anti-robo', 59990, 'CLP', 'Moda', 80, false, 'https://picsum.photos/seed/backpack/400/400'),
  ('Chaqueta Térmica Tech', 'Aislamiento térmico inteligente', 129990, 'CLP', 'Moda', 60, false, 'https://picsum.photos/seed/jacket/400/400'),
  
  -- Sports
  ('Bicicleta MTB Carbono', '21 velocidades, frenos hidráulicos', 899990, 'CLP', 'Deportes', 15, true, 'https://picsum.photos/seed/bike/400/400'),
  ('Kit Yoga Completo', 'Mat premium + bloques + correa', 49990, 'CLP', 'Deportes', 100, false, 'https://picsum.photos/seed/yoga/400/400'),
  
  -- Gaming
  ('Consola NextGen 1TB', 'Ray tracing, 120fps, SSD ultra rápido', 699990, 'CLP', 'Gaming', 35, true, 'https://picsum.photos/seed/console/400/400'),
  ('Silla Gamer Ergonómica', 'Reclinable 180°, reposabrazos 4D', 249990, 'CLP', 'Gaming', 45, false, 'https://picsum.photos/seed/chair/400/400'),
  ('Mouse Gaming RGB 16000 DPI', 'Sensor óptico profesional', 39990, 'CLP', 'Gaming', 120, false, 'https://picsum.photos/seed/mouse/400/400')
ON CONFLICT DO NOTHING;

-- Fake Sample Orders
DO $$
DECLARE
  demo_user_id UUID;
  product_ids UUID[];
BEGIN
  -- Get demo user
  SELECT id INTO demo_user_id FROM demo.users WHERE email = 'demo@smarterbot.cl' LIMIT 1;
  
  IF demo_user_id IS NOT NULL THEN
    -- Get some product IDs
    SELECT array_agg(id) INTO product_ids FROM demo.products LIMIT 5;
    
    -- Create sample orders
    INSERT INTO demo.orders (user_id, total, status, items) VALUES
      (demo_user_id, 599990, 'completed', jsonb_build_array(
        jsonb_build_object('product_id', product_ids[1], 'quantity', 1, 'price', 599990)
      )),
      (demo_user_id, 189980, 'shipped', jsonb_build_array(
        jsonb_build_object('product_id', product_ids[2], 'quantity', 2, 'price', 89990)
      )),
      (demo_user_id, 449990, 'pending', jsonb_build_array(
        jsonb_build_object('product_id', product_ids[3], 'quantity', 1, 'price', 299990),
        jsonb_build_object('product_id', product_ids[4], 'quantity', 1, 'price', 149990)
      ));
  END IF;
END $$;

-- Fake Conversations (Bot interactions)
DO $$
DECLARE
  demo_user_id UUID;
BEGIN
  SELECT id INTO demo_user_id FROM demo.users WHERE email = 'demo@smarterbot.cl' LIMIT 1;
  
  IF demo_user_id IS NOT NULL THEN
    INSERT INTO demo.conversations (user_id, message, sender, sentiment) VALUES
      (demo_user_id, 'Hola! Busco un smartphone con buena cámara', 'user', 'neutral'),
      (demo_user_id, '¡Hola! Te recomiendo el Smartphone Galaxy Pro con cámara de 108MP. ¿Te gustaría conocer más detalles?', 'bot', 'positive'),
      (demo_user_id, 'Sí, cuéntame sobre la batería', 'user', 'positive'),
      (demo_user_id, 'Tiene una batería de 5000mAh con carga rápida de 65W. Autonomía de hasta 2 días con uso normal.', 'bot', 'positive'),
      (demo_user_id, 'Perfecto! Lo quiero', 'user', 'positive'),
      (demo_user_id, '¡Excelente elección! Te ayudo con la compra. ¿Prefieres retiro en tienda o envío a domicilio?', 'bot', 'positive');
  END IF;
END $$;

-- Fake Analytics Events
DO $$
DECLARE
  demo_user_id UUID;
BEGIN
  SELECT id INTO demo_user_id FROM demo.users WHERE email = 'demo@smarterbot.cl' LIMIT 1;
  
  IF demo_user_id IS NOT NULL THEN
    INSERT INTO demo.analytics (user_id, event_type, event_data) VALUES
      (demo_user_id, 'page_view', '{"page": "home", "duration_seconds": 45}'::jsonb),
      (demo_user_id, 'product_view', '{"product_id": "smartphone-galaxy", "time_spent": 120}'::jsonb),
      (demo_user_id, 'add_to_cart', '{"product_id": "smartphone-galaxy", "price": 599990}'::jsonb),
      (demo_user_id, 'checkout_started', '{"cart_total": 599990, "items_count": 1}'::jsonb),
      (demo_user_id, 'purchase_completed', '{"order_id": "demo-001", "total": 599990, "payment_method": "credit_card"}'::jsonb),
      (demo_user_id, 'bot_interaction', '{"conversation_id": "conv-001", "satisfaction": 5, "resolved": true}'::jsonb);
  END IF;
END $$;

-- Summary
DO $$
DECLARE
  products_count INTEGER;
  orders_count INTEGER;
  conversations_count INTEGER;
  analytics_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO products_count FROM demo.products;
  SELECT COUNT(*) INTO orders_count FROM demo.orders;
  SELECT COUNT(*) INTO conversations_count FROM demo.conversations;
  SELECT COUNT(*) INTO analytics_count FROM demo.analytics;
  
  RAISE NOTICE '✅ Demo data seeded successfully:';
  RAISE NOTICE '   - Products: %', products_count;
  RAISE NOTICE '   - Orders: %', orders_count;
  RAISE NOTICE '   - Conversations: %', conversations_count;
  RAISE NOTICE '   - Analytics: %', analytics_count;
END $$;
