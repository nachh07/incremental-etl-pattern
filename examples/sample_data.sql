/*
==============================================================================
SAMPLE DATA: Datos de ejemplo adicionales
DESCRIPTION: Datasets adicionales para pruebas y demostraciones
CUANDO USAR: Para experimentar con diferentes escenarios
==============================================================================
*/

-- ========================================
-- ESCENARIO 1: Actualización masiva de precios
-- ========================================
-- Simula un ajuste de precios por inflación o promoción

UPDATE origen_products
SET 
    price = price * 1.10,  -- Incremento del 10%
    updated_at = '2025-03-01 09:00:00'
WHERE 
    product_id BETWEEN 1 AND 10;

-- ========================================
-- ESCENARIO 2: Nuevos productos por categoría
-- ========================================
-- Gaming
INSERT INTO origen_products VALUES
(34, 'Silla Gamer Pro', 299.00, '2025-03-15 10:00', '2025-03-15 10:00'),
(35, 'Escritorio Gaming RGB', 450.00, '2025-03-15 10:30', '2025-03-15 10:30'),
(36, 'Alfombrilla XXL', 35.00, '2025-03-15 11:00', '2025-03-15 11:00');

-- Networking
INSERT INTO origen_products VALUES
(37, 'Router WiFi 6', 120.00, '2025-03-16 09:00', '2025-03-16 09:00'),
(38, 'Access Point Mesh', 85.00, '2025-03-16 09:30', '2025-03-16 09:30'),
(39, 'Cable Cat6 50m', 25.00, '2025-03-16 10:00', '2025-03-16 10:00');

-- Audio
INSERT INTO origen_products VALUES
(40, 'Parlantes 2.1', 65.00, '2025-03-17 14:00', '2025-03-17 14:00'),
(41, 'Soundbar TV', 150.00, '2025-03-17 14:30', '2025-03-17 14:30'),
(42, 'Auriculares Bluetooth', 89.00, '2025-03-17 15:00', '2025-03-17 15:00');

-- ========================================
-- ESCENARIO 3: Descontinuación de productos viejos
-- ========================================
DELETE FROM origen_products WHERE product_id IN (
    7,  -- Disco HDD 1TB (tecnología obsoleta)
    8,  -- Memoria USB 32GB (reemplazado por modelos más grandes)
    15  -- Mouse Pad Gaming (fuera de catálogo)
);

-- ========================================
-- ESCENARIO 4: Reactivación de productos
-- ========================================
-- Simula productos que vuelven al stock después de haber sido descontinuados
INSERT INTO origen_products VALUES
(3, 'Monitor LED 24" Renovado', 180.00, '2025-04-01 10:00', '2025-04-01 10:00');

-- ========================================
-- ESCENARIO 5: Cambios de nombre/rebranding
-- ========================================
UPDATE origen_products
SET 
    product_name = CASE
        WHEN product_id = 1 THEN 'Mouse Wireless Pro'
        WHEN product_id = 2 THEN 'Keyboard Mechanical RGB'
        WHEN product_id = 4 THEN 'Webcam Full HD 1080p'
        ELSE product_name
    END,
    updated_at = '2025-04-15 12:00:00'
WHERE 
    product_id IN (1, 2, 4);

-- ========================================
-- QUERIES DE ANÁLISIS
-- ========================================

-- Ver distribución de precios
SELECT 
    CASE 
        WHEN price < 20 THEN '< $20'
        WHEN price < 50 THEN '$20-$50'
        WHEN price < 100 THEN '$50-$100'
        WHEN price < 200 THEN '$100-$200'
        ELSE '> $200'
    END AS rango_precio,
    COUNT(*) AS cantidad_productos,
    ROUND(AVG(price), 2) AS precio_promedio
FROM origen_products
GROUP BY 1
ORDER BY 2 DESC;

-- Ver productos más recientes
SELECT 
    product_id,
    product_name,
    price,
    created_at
FROM origen_products
ORDER BY created_at DESC
LIMIT 10;

-- Ver historial de actualizaciones
SELECT 
    product_id,
    product_name,
    price,
    updated_at,
    EXTRACT(DAY FROM NOW() - updated_at) AS dias_sin_actualizar
FROM origen_products
ORDER BY updated_at DESC;

-- Comparar origen vs destino (productos faltantes)
SELECT 
    o.product_id,
    o.product_name,
    'Falta en destino' AS status
FROM origen_products o
LEFT JOIN destino_products d ON o.product_id = d.product_id
WHERE d.product_id IS NULL

UNION ALL

SELECT 
    d.product_id,
    d.product_name,
    'Falta en origen' AS status
FROM destino_products d
LEFT JOIN origen_products o ON d.product_id = o.product_id
WHERE o.product_id IS NULL AND d.is_active = TRUE
ORDER BY product_id;

