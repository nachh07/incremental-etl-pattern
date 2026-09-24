/*
==============================================================================
SCRIPT: Initial Full Load
DESCRIPTION: Primera carga completa desde origen a destino
CUANDO USAR: Solo la primera vez que se carga la tabla destino
==============================================================================
*/

DROP TABLE IF EXISTS origen_products;
CREATE TABLE origen_products (
    product_id   INT PRIMARY KEY,
    product_name TEXT,
    price        NUMERIC(10,2),
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP
);

DROP TABLE IF EXISTS destino_products;
CREATE TABLE destino_products (
    product_id   INT PRIMARY KEY,
    product_name TEXT,
    price        NUMERIC(10,2),
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP,
    is_active    BOOLEAN DEFAULT TRUE,
    inactive_at  TIMESTAMP,
    -- Columnas de hash para detección de cambios y lookup eficiente
    pk_hash      TEXT,   -- MD5 de la clave primaria (product_id)
    r_hash       TEXT    -- MD5 del resto de columnas de origen (detección de cambios)
);

INSERT INTO origen_products VALUES
(1, 'Mouse Inalámbrico', 10.00, '2025-01-01 10:00', '2025-01-01 10:00'),
(2, 'Teclado Mecánico', 20.00, '2025-01-02 11:00', '2025-01-02 11:00'),
(3, 'Monitor LED 24"', 200.00, '2025-01-03 12:00', '2025-01-03 12:00'),
(4, 'Webcam HD', 45.00, '2025-01-04 09:00', '2025-01-04 09:00'),
(5, 'Auriculares Gaming', 75.00, '2025-01-05 10:30', '2025-01-05 10:30'),
(6, 'Disco SSD 256GB', 55.00, '2025-01-06 08:00', '2025-01-06 08:00'),
(7, 'Disco HDD 1TB', 40.00, '2025-01-07 14:20', '2025-01-07 14:20'),
(8, 'Memoria USB 32GB', 8.00, '2025-01-08 16:45', '2025-01-08 16:45'),
(9, 'Tarjeta SD 64GB', 12.00, '2025-01-09 11:15', '2025-01-09 11:15'),
(10, 'Tarjeta Gráfica GTX', 350.00, '2025-01-10 09:30', '2025-01-10 09:30'),
(11, 'Procesador i5', 220.00, '2025-01-11 13:00', '2025-01-11 13:00'),
(12, 'Placa Madre ATX', 150.00, '2025-01-12 10:45', '2025-01-12 10:45'),
(13, 'Memoria RAM 8GB', 35.00, '2025-01-13 15:20', '2025-01-13 15:20'),
(14, 'Fuente de Poder 600W', 65.00, '2025-01-14 12:00', '2025-01-14 12:00'),
(15, 'Mouse Pad Gaming', 15.00, '2025-01-15 09:00', '2025-01-15 09:00'),
(16, 'Cable HDMI 2m', 7.00, '2025-01-16 10:30', '2025-01-16 10:30'),
(17, 'Hub USB 4 puertos', 18.00, '2025-01-17 14:00', '2025-01-17 14:00'),
(18, 'Soporte para Monitor', 25.00, '2025-01-18 11:30', '2025-01-18 11:30'),
(19, 'Lámpara LED Escritorio', 22.00, '2025-01-19 16:00', '2025-01-19 16:00'),
(20, 'Laptop Core i7 16GB', 850.00, '2025-01-20 10:00', '2025-01-20 10:00'),
(21, 'Tablet 10" 64GB', 180.00, '2025-01-21 13:30', '2025-01-21 13:30'),
(22, 'Chromebook', 280.00, '2025-01-22 09:15', '2025-01-22 09:15'),
(23, 'Antivirus 1 año', 30.00, '2025-01-23 08:45', '2025-01-23 08:45'),
(24, 'Microsoft Office', 99.00, '2025-01-24 14:20', '2025-01-24 14:20'),
(25, 'Adobe Creative Cloud 1 mes', 54.99, '2025-01-25 11:00', '2025-01-25 11:00');

INSERT INTO destino_products (
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
SELECT
    product_id,
    product_name,
    price,
    created_at,
    updated_at,
    TRUE,
    NULL,
    -- PK_HASH: hash de la clave primaria
    MD5(product_id::TEXT),
    -- R_HASH: hash de todos los atributos de origen (sin PK ni columnas de control ETL)
    MD5(CONCAT_WS('|',
        COALESCE(product_name, ''),
        COALESCE(price::TEXT, ''),
        COALESCE(created_at::TEXT, ''),
        COALESCE(updated_at::TEXT, '')
    ))
FROM origen_products;

SELECT
    product_id,
    product_name,
    pk_hash,
    r_hash
FROM destino_products
ORDER BY product_id;