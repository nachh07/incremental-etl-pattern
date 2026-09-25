-- ========================================
-- MERGE: Sincronización completa origen → destino
-- ========================================
/*
  Compatible con: PostgreSQL 15 y 16
  NOTA: En PG16, MERGE no soporta "WHEN NOT MATCHED BY SOURCE" (es sintaxis de PG17+).
        Por eso el soft delete se hace en un paso separado con UPDATE + NOT EXISTS.

  Columnas de hash:
    PK_HASH → MD5 de la clave primaria (product_id)
              Uso: lookup y joins por hash en lugar de por valor
    R_HASH  → MD5 de todos los atributos de origen (excluye PK y columnas de control ETL)
              Uso: detectar si un registro cambió comparando un solo valor

  Qué hace:
    PASO 1 → MERGE:  INSERT de productos nuevos + UPDATE de productos modificados
    PASO 2 → UPDATE: Soft delete de productos que ya no están en origen
*/

-- Helper: expresión reutilizable para calcular R_HASH desde origen
-- MD5( col1 | col2 | col3 | ... )  usando '|' como separador
-- CONCAT_WS ignora NULLs, COALESCE garantiza que NULL no rompa el hash


-- ---------------------------------------------------------
-- PASO 1: INSERT + UPDATE via MERGE
-- ---------------------------------------------------------
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
    FROM origen_products
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

-- ---------------------------------------------------------
-- PASO 2: SOFT DELETE
-- Marca como inactivos los registros que ya no están en origen
-- (equivalente a WHEN NOT MATCHED BY SOURCE de PostgreSQL 17+)
-- ---------------------------------------------------------
UPDATE destino_products AS t
SET
    is_active   = FALSE,
    inactive_at = NOW()
WHERE
    t.is_active = TRUE
    AND NOT EXISTS (
        SELECT 1
        FROM origen_products AS s
        WHERE s.product_id = t.product_id
    );

-- ---------------------------------------------------------
-- Verificación post-merge
-- ---------------------------------------------------------
SELECT
    product_id,
    product_name,
    price,
	created_at,
    updated_at,
    is_active,
    inactive_at,
    pk_hash,
    r_hash,
    CASE
        WHEN is_active THEN 'Activo ✔'
        ELSE 'Inactivo (soft delete) ✘'
    END AS estado
FROM destino_products
ORDER BY product_id;