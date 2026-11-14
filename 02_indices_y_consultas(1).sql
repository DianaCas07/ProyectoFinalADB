/* ============================================================================
   PROYECTO DE CÁTEDRA - Administración de Bases de Datos (SQL Server 2025)
   ARCHIVO 2 : Índices + consultas avanzadas con funciones ventana
   Requisito : haber ejecutado antes 01_estructura_y_datos.sql

   FLUJO PARA GENERAR LA EVIDENCIA DEL INFORME (antes vs. después):
     Paso A) Ejecutar el BLOQUE 0 (elimina los índices propios, deja solo PK/UNIQUE).
     Paso B) Activar "Incluir plan de ejecución real" (Ctrl+M) y ejecutar el BLOQUE 1.
             Capturar: plan de ejecución + pestaña Messages (lecturas lógicas).
     Paso C) Ejecutar el BLOQUE 2 (crea los índices).
     Paso D) Volver a ejecutar el BLOQUE 1 y capturar plan + lecturas lógicas.
     Paso E) Ejecutar el BLOQUE 3 (tamaño de los índices; sirve para el
             "factor por índices" del dimensionamiento).

   Nota: con ~200 filas por tabla el optimizador puede seguir eligiendo
   escaneos aunque el índice exista (la tabla cabe en pocas páginas). Lo que se
   debe mostrar es la reducción de lecturas lógicas, el cambio de operador
   (Clustered Index Scan -> Index Seek) y la eliminación de Sort. Si se quiere
   un contraste más marcado, se puede cargar más volumen de prueba.
   ========================================================================== */
USE biblioteca;
GO

-- ============================================================
-- BLOQUE 0. LIMPIEZA (línea base sin índices propios)
-- ============================================================
DROP INDEX IF EXISTS IX_libros_editorial       ON catalogo.libros;
DROP INDEX IF EXISTS IX_libros_categoria       ON catalogo.libros;
DROP INDEX IF EXISTS IX_libro_autor_autor      ON catalogo.libro_autor;
DROP INDEX IF EXISTS IX_ejemplares_isbn_estado ON inventario.ejemplares;
DROP INDEX IF EXISTS IX_prestamos_fecha        ON circulacion.prestamos;
DROP INDEX IF EXISTS IX_prestamos_socio_fecha  ON circulacion.prestamos;
DROP INDEX IF EXISTS IX_prestamos_ejemplar     ON circulacion.prestamos;
DROP INDEX IF EXISTS IX_prestamos_empleado     ON circulacion.prestamos;
DROP INDEX IF EXISTS IX_devoluciones_prestamo  ON circulacion.devoluciones;
DROP INDEX IF EXISTS IX_multas_socio           ON finanzas.multas;
DROP INDEX IF EXISTS IX_multas_prestamo        ON finanzas.multas;
DROP INDEX IF EXISTS IX_multas_pendientes      ON finanzas.multas;
GO

-- ============================================================
-- BLOQUE 1. CONSULTAS AVANZADAS (3 con funciones ventana)
-- ============================================================
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ------------------------------------------------------------
-- Q1. Top 3 libros más prestados por categoría desde 2025
--     Ventana: DENSE_RANK() OVER (PARTITION BY categoría ORDER BY total DESC)
--     Índice clave: IX_prestamos_fecha (rango por fecha, cubre id_ejemplar)
-- ------------------------------------------------------------
WITH prestamos_libro AS (
    SELECT  l.id_categoria,
            l.isbn,
            l.titulo,
            COUNT(*) AS total_prestamos
    FROM circulacion.prestamos p
    JOIN inventario.ejemplares e ON e.id_ejemplar = p.id_ejemplar
    JOIN catalogo.libros       l ON l.isbn        = e.isbn
    WHERE p.fecha_salida >= '2025-01-01'
    GROUP BY l.id_categoria, l.isbn, l.titulo
),
ranking AS (
    SELECT  pl.*,
            DENSE_RANK() OVER (PARTITION BY pl.id_categoria
                               ORDER BY pl.total_prestamos DESC) AS posicion
    FROM prestamos_libro pl
)
SELECT  ISNULL(c.nombre_categoria, N'(Sin categoría)') AS categoria,
        r.titulo,
        r.total_prestamos,
        r.posicion
FROM ranking r
LEFT JOIN catalogo.categorias c ON c.id_categoria = r.id_categoria
WHERE r.posicion <= 3
ORDER BY categoria, r.posicion, r.titulo;
GO

-- ------------------------------------------------------------
-- Q2. Deuda pendiente por socio: acumulado, total y % de cada multa
--     Ventanas: SUM() OVER (... ROWS UNBOUNDED PRECEDING) y SUM() OVER (PARTITION BY)
--     Índice clave: IX_multas_pendientes (filtrado WHERE estado_pago = 0,
--                   ordenado por id_socio, id_multa => evita el Sort)
-- ------------------------------------------------------------
SELECT  s.nombre                                   AS socio,
        m.id_multa,
        m.monto,
        SUM(m.monto) OVER (PARTITION BY m.id_socio
                           ORDER BY m.id_multa
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS deuda_acumulada,
        SUM(m.monto) OVER (PARTITION BY m.id_socio)                          AS deuda_total_socio,
        CAST(100.0 * m.monto
             / SUM(m.monto) OVER (PARTITION BY m.id_socio) AS DECIMAL(5,2))  AS pct_de_su_deuda
FROM finanzas.multas m
JOIN personas.socios s ON s.id_socio = m.id_socio
WHERE m.estado_pago = 0
ORDER BY s.nombre, m.id_multa;
GO

-- ------------------------------------------------------------
-- Q3. Historial de cada socio: retraso en la entrega y días desde su
--     préstamo anterior. Ventanas: LAG() y AVG() OVER (PARTITION BY)
--     Índices clave: IX_prestamos_socio_fecha e IX_devoluciones_prestamo
--     (dias_retraso > 0 = entregó tarde; negativo = entregó antes del límite)
-- ------------------------------------------------------------
WITH historial AS (
    SELECT  p.id_socio,
            p.id_prestamo,
            p.fecha_salida,
            p.fecha_limite,
            d.fecha_entrega_real,
            DATEDIFF(DAY, p.fecha_limite, d.fecha_entrega_real) AS dias_retraso,
            LAG(p.fecha_salida) OVER (PARTITION BY p.id_socio
                                      ORDER BY p.fecha_salida, p.id_prestamo) AS prestamo_anterior
    FROM circulacion.prestamos p
    LEFT JOIN circulacion.devoluciones d ON d.id_prestamo = p.id_prestamo
)
SELECT  s.nombre AS socio,
        h.id_prestamo,
        h.fecha_salida,
        h.fecha_limite,
        h.fecha_entrega_real,
        h.dias_retraso,
        DATEDIFF(DAY, h.prestamo_anterior, h.fecha_salida) AS dias_desde_prestamo_anterior,
        CAST(AVG(CAST(h.dias_retraso AS DECIMAL(10,2)))
             OVER (PARTITION BY h.id_socio) AS DECIMAL(10,2)) AS retraso_promedio_socio
FROM historial h
JOIN personas.socios s ON s.id_socio = h.id_socio
ORDER BY s.nombre, h.fecha_salida, h.id_prestamo;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ============================================================
-- BLOQUE 2. CREACIÓN DE ÍNDICES
-- ============================================================

-- ---- Índices para las consultas Q1, Q2 y Q3 ----
-- Q1: rango por fecha; INCLUDE evita volver a la tabla (índice cubriente)
CREATE NONCLUSTERED INDEX IX_prestamos_fecha
    ON circulacion.prestamos (fecha_salida) INCLUDE (id_ejemplar);

-- Q3: agrupa por socio y ordena por fecha (alimenta LAG sin Sort)
CREATE NONCLUSTERED INDEX IX_prestamos_socio_fecha
    ON circulacion.prestamos (id_socio, fecha_salida) INCLUDE (fecha_limite);

-- Q3: búsqueda de la devolución de cada préstamo
CREATE NONCLUSTERED INDEX IX_devoluciones_prestamo
    ON circulacion.devoluciones (id_prestamo) INCLUDE (fecha_entrega_real);

-- Q2: índice FILTRADO, solo guarda las multas pendientes (más pequeño y rápido)
CREATE NONCLUSTERED INDEX IX_multas_pendientes
    ON finanzas.multas (id_socio, id_multa) INCLUDE (monto)
    WHERE estado_pago = 0;

-- ---- Índices sobre llaves foráneas (SQL Server no los crea solo) ----
-- Aceleran los JOIN y los ON DELETE/UPDATE CASCADE
CREATE NONCLUSTERED INDEX IX_libros_editorial
    ON catalogo.libros (id_editorial);

CREATE NONCLUSTERED INDEX IX_libros_categoria
    ON catalogo.libros (id_categoria) INCLUDE (titulo);

CREATE NONCLUSTERED INDEX IX_libro_autor_autor
    ON catalogo.libro_autor (id_autor);

CREATE NONCLUSTERED INDEX IX_ejemplares_isbn_estado
    ON inventario.ejemplares (isbn, estado);

CREATE NONCLUSTERED INDEX IX_prestamos_ejemplar
    ON circulacion.prestamos (id_ejemplar);

CREATE NONCLUSTERED INDEX IX_prestamos_empleado
    ON circulacion.prestamos (id_empleado);

CREATE NONCLUSTERED INDEX IX_multas_socio
    ON finanzas.multas (id_socio);

CREATE NONCLUSTERED INDEX IX_multas_prestamo
    ON finanzas.multas (id_prestamo);
GO

-- >>> Paso D: volver a ejecutar el BLOQUE 1 y comparar con la línea base <<<

-- ============================================================
-- BLOQUE 3. TAMAÑO DE LOS ÍNDICES (insumo para el dimensionamiento)
-- ============================================================
SELECT  s.name + '.' + t.name                        AS tabla,
        i.name                                       AS indice,
        i.type_desc                                  AS tipo,
        i.is_primary_key                             AS es_pk,
        SUM(ps.row_count)                            AS filas,
        SUM(ps.used_page_count) * 8                  AS usado_kb,
        SUM(ps.reserved_page_count) * 8              AS reservado_kb
FROM sys.indexes i
JOIN sys.tables  t  ON t.object_id = i.object_id
JOIN sys.schemas s  ON s.schema_id = t.schema_id
JOIN sys.dm_db_partition_stats ps ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.index_id > 0
GROUP BY s.name, t.name, i.name, i.type_desc, i.is_primary_key
ORDER BY tabla, i.type_desc, i.name;
GO

-- Resumen: datos (clustered) vs. índices adicionales => factor por índices
SELECT  SUM(CASE WHEN i.index_id = 1 THEN ps.used_page_count ELSE 0 END) * 8 AS datos_kb,
        SUM(CASE WHEN i.index_id > 1 THEN ps.used_page_count ELSE 0 END) * 8 AS indices_kb,
        CAST(1.0 * SUM(CASE WHEN i.index_id > 1 THEN ps.used_page_count ELSE 0 END)
             / NULLIF(SUM(CASE WHEN i.index_id = 1 THEN ps.used_page_count ELSE 0 END), 0)
             AS DECIMAL(6,2))                                                AS factor_indices
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
JOIN sys.dm_db_partition_stats ps ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE i.index_id >= 1;
GO

-- ============================================================
-- BLOQUE 4 (opcional). ¿Se están usando los índices?
-- ============================================================
SELECT  OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS tabla,
        i.name AS indice,
        us.user_seeks, us.user_scans, us.user_lookups, us.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats us
       ON us.object_id = i.object_id AND us.index_id = i.index_id AND us.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1 AND i.index_id > 0
ORDER BY tabla, i.name;
GO
