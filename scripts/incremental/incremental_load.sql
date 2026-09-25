/*
==============================================================================
SCRIPT: Incremental Load (SIN considerar borrados)
DESCRIPTION: Carga incremental basada en fecha de actualización
CUANDO USAR: Ejecuciones regulares para cargar solo nuevos/actualizados
NOTA: NO maneja registros borrados en origen (soft delete)
==============================================================================
*/

-- Simular nuevos datos en ORIGEN
-- ACTUALIZAR productos existentes (7 actualizaciones)
UPDATE origen_products
SET 
    price = CASE 
        WHEN product_id = 1 THEN 12.00
        WHEN product_id = 2 THEN 22.50
        WHEN product_id = 3 THEN 180.00
        WHEN product_id = 5 THEN 70.00
        WHEN product_id = 6 THEN 50.00
        WHEN product_id = 10 THEN 320.00
        WHEN product_id = 24 THEN 95.00
        ELSE price 
    END,
    updated_at = NOW()
WHERE 
    product_id IN (1, 2, 3, 5, 6, 10, 24); 

INSERT INTO origen_products VALUES
(26, 'Teclado Ergonómico', 45.00, NOW(), NOW()),
(27, 'Mouse Vertical', 35.00, NOW(), NOW()),
(28, 'Monitor Curvo 27"', 280.00, NOW(), NOW()),
(29, 'Micrófono USB', 55.00, NOW(), NOW()),
(30, 'Silla Gaming', 199.00, NOW(), NOW()),
(31, 'Escritorio Ajustable', 350.00, NOW(), NOW()),
(32, 'Cooler RGB', 28.00, NOW(), NOW()),
(33, 'Switch Ethernet 8 puertos', 42.00, NOW(), NOW());

CREATE TEMP TABLE stg_products AS
SELECT *
FROM origen_products
WHERE updated_at > (
    SELECT COALESCE(MAX(updated_at), '1900-01-01')
    FROM destino_products
);

-- Ver qué se va a cargar
SELECT * FROM stg_products;

MERGE INTO destino_products AS t
USING (
    -- Precalculamos los hashes en el origen para reutilizarlos
    SELECT
        product_id,
        product_name,
        price,
        created_at,
        updated_at,
        MD5(product_id::TEXT) AS pk_hash,
        MD5(CONCAT_WS('|',
            COALESCE(product_name, ''),
            COALESCE(price::TEXT, ''),
            COALESCE(created_at::TEXT, ''),
            COALESCE(updated_at::TEXT, '')
        )) AS r_hash
    FROM stg_products AS s
) AS s
    ON t.product_id = s.product_id

-- ► INSERT: producto nuevo en origen, no existe en destino
WHEN NOT MATCHED THEN
    INSERT (
        product_id,
        product_name,
        price,
        created_at,
        updated_at,
        is_active,
        inactive_at,
        pk_hash,
        r_hash
    )
    VALUES (
        s.product_id,
        s.product_name,
        s.price,
        s.created_at,
        s.updated_at,
        TRUE,
        NULL,
        s.pk_hash,
        s.r_hash
    )

-- ► UPDATE: se detecta el cambio comparando R_HASH (más eficiente en tablas grandes)
WHEN MATCHED AND t.r_hash IS DISTINCT FROM s.r_hash THEN
    UPDATE SET
        product_name = s.product_name,
        price        = s.price,
        updated_at   = NOW(),
        is_active    = TRUE,   -- Reactiva si estaba inactivo
        inactive_at  = NULL,   -- Limpia fecha de baja
        pk_hash      = s.pk_hash,
        r_hash       = s.r_hash;

DROP TABLE IF EXISTS stg_products;

SELECT * FROM destino_products ORDER BY product_id;