-- ============================================================
-- PROYECTO 1 - Seminario de Sistemas 2
-- Data Warehouse: DW_SGFood
-- Empresa: SG-Food
-- Descripción: Script DDL completo para crear la base de datos
--              del Data Warehouse con modelo constelación.
-- ============================================================

-- ============================================================
-- 1. CREAR BASE DE DATOS
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_SGFood')
BEGIN
    CREATE DATABASE DW_SGFood;
END
GO

USE DW_SGFood;
GO

-- ============================================================
-- 2. ELIMINAR TABLAS SI EXISTEN (orden: facts primero, luego dims)
-- ============================================================
IF OBJECT_ID('dbo.FactCompras', 'U') IS NOT NULL DROP TABLE dbo.FactCompras;
IF OBJECT_ID('dbo.FactVentas',  'U') IS NOT NULL DROP TABLE dbo.FactVentas;
IF OBJECT_ID('dbo.DimProveedor','U') IS NOT NULL DROP TABLE dbo.DimProveedor;
IF OBJECT_ID('dbo.DimCliente',  'U') IS NOT NULL DROP TABLE dbo.DimCliente;
IF OBJECT_ID('dbo.DimVendedor', 'U') IS NOT NULL DROP TABLE dbo.DimVendedor;
IF OBJECT_ID('dbo.DimProducto', 'U') IS NOT NULL DROP TABLE dbo.DimProducto;
IF OBJECT_ID('dbo.DimSucursal', 'U') IS NOT NULL DROP TABLE dbo.DimSucursal;
IF OBJECT_ID('dbo.DimTiempo',   'U') IS NOT NULL DROP TABLE dbo.DimTiempo;
GO

-- ============================================================
-- 3. DIMENSIONES COMPARTIDAS
-- ============================================================

-- ------------------------------------------------------------
-- DimTiempo
-- TiempoKey: entero con formato YYYYMMDD (ej. 20191111)
-- Permite JOIN directo calculando la key desde cualquier fecha
-- ------------------------------------------------------------
CREATE TABLE dbo.DimTiempo (
    TiempoKey    INT          NOT NULL,   -- YYYYMMDD
    FechaCompleta DATE        NOT NULL,
    Dia           TINYINT     NOT NULL,
    Mes           TINYINT     NOT NULL,
    NombreMes     VARCHAR(20) NOT NULL,
    Trimestre     TINYINT     NOT NULL,
    Anio          SMALLINT    NOT NULL,
    CONSTRAINT PK_DimTiempo PRIMARY KEY (TiempoKey)
);
GO

-- ------------------------------------------------------------
-- DimProducto
-- Jerarquía SSAS: Categoria > Marca > Producto
-- ------------------------------------------------------------
CREATE TABLE dbo.DimProducto (
    ProductoKey    INT          NOT NULL IDENTITY(1,1),
    CodProducto    VARCHAR(10)  NOT NULL,
    NombreProducto VARCHAR(50)  NOT NULL,
    MarcaProducto  VARCHAR(20)  NOT NULL,
    Categoria      VARCHAR(30)  NOT NULL,
    CONSTRAINT PK_DimProducto PRIMARY KEY (ProductoKey),
    CONSTRAINT UQ_DimProducto_Cod UNIQUE (CodProducto)
);
GO

-- ------------------------------------------------------------
-- DimSucursal
-- Jerarquía SSAS: Region > Departamento > Sucursal
-- ------------------------------------------------------------
CREATE TABLE dbo.DimSucursal (
    SucursalKey    INT         NOT NULL IDENTITY(1,1),
    CodSucursal    VARCHAR(10) NOT NULL,
    NombreSucursal VARCHAR(30) NOT NULL,
    Departamento   VARCHAR(30) NOT NULL,
    Region         VARCHAR(30) NOT NULL,
    CONSTRAINT PK_DimSucursal PRIMARY KEY (SucursalKey),
    CONSTRAINT UQ_DimSucursal_Cod UNIQUE (CodSucursal)
);
GO

-- ============================================================
-- 4. DIMENSIONES ESPECÍFICAS
-- ============================================================

-- ------------------------------------------------------------
-- DimProveedor  (solo para FactCompras)
-- ------------------------------------------------------------
CREATE TABLE dbo.DimProveedor (
    ProveedorKey    INT         NOT NULL IDENTITY(1,1),
    CodProveedor    VARCHAR(10) NOT NULL,
    NombreProveedor VARCHAR(50) NOT NULL,
    CONSTRAINT PK_DimProveedor PRIMARY KEY (ProveedorKey),
    CONSTRAINT UQ_DimProveedor_Cod UNIQUE (CodProveedor)
);
GO

-- ------------------------------------------------------------
-- DimCliente  (solo para FactVentas)
-- Jerarquía SSAS opcional: TipoCliente > Cliente
-- ------------------------------------------------------------
CREATE TABLE dbo.DimCliente (
    ClienteKey    INT         NOT NULL IDENTITY(1,1),
    CodCliente    VARCHAR(10) NOT NULL,
    NombreCliente VARCHAR(50) NOT NULL,
    TipoCliente   VARCHAR(20) NOT NULL,
    CONSTRAINT PK_DimCliente PRIMARY KEY (ClienteKey),
    CONSTRAINT UQ_DimCliente_Cod UNIQUE (CodCliente)
);
GO

-- ------------------------------------------------------------
-- DimVendedor  (solo para FactVentas)
-- ------------------------------------------------------------
CREATE TABLE dbo.DimVendedor (
    VendedorKey    INT         NOT NULL IDENTITY(1,1),
    CodVendedor    VARCHAR(10) NOT NULL,
    NombreVendedor VARCHAR(50) NOT NULL,
    CONSTRAINT PK_DimVendedor PRIMARY KEY (VendedorKey),
    CONSTRAINT UQ_DimVendedor_Cod UNIQUE (CodVendedor)
);
GO

-- ============================================================
-- 5. TABLAS DE HECHOS
-- ============================================================

-- ------------------------------------------------------------
-- FactCompras
-- Granularidad: una fila = una compra de un producto
--              en una fecha, a un proveedor, en una sucursal
-- PrecioUnitario: almacenado para calcular margen vs ventas
-- ------------------------------------------------------------
CREATE TABLE dbo.FactCompras (
    CompraKey         INT            NOT NULL IDENTITY(1,1),
    TiempoKey         INT            NOT NULL,
    ProductoKey       INT            NOT NULL,
    SucursalKey       INT            NOT NULL,
    ProveedorKey      INT            NOT NULL,
    UnidadesCompradas INT            NOT NULL,
    CostoUnitario     DECIMAL(10,2)  NOT NULL,
    PrecioUnitario    DECIMAL(10,2)  NULL,        -- para análisis de margen
    MontoCompra       DECIMAL(14,2)  NOT NULL,    -- = Unidades * CostoUnitario
    CONSTRAINT PK_FactCompras    PRIMARY KEY (CompraKey),
    CONSTRAINT FK_FC_Tiempo      FOREIGN KEY (TiempoKey)    REFERENCES dbo.DimTiempo(TiempoKey),
    CONSTRAINT FK_FC_Producto    FOREIGN KEY (ProductoKey)  REFERENCES dbo.DimProducto(ProductoKey),
    CONSTRAINT FK_FC_Sucursal    FOREIGN KEY (SucursalKey)  REFERENCES dbo.DimSucursal(SucursalKey),
    CONSTRAINT FK_FC_Proveedor   FOREIGN KEY (ProveedorKey) REFERENCES dbo.DimProveedor(ProveedorKey)
);
GO

-- ------------------------------------------------------------
-- FactVentas
-- Granularidad: una fila = una venta de un producto
--              en una fecha, a un cliente, por un vendedor,
--              en una sucursal
-- ------------------------------------------------------------
CREATE TABLE dbo.FactVentas (
    VentaKey         INT            NOT NULL IDENTITY(1,1),
    TiempoKey        INT            NOT NULL,
    ProductoKey      INT            NOT NULL,
    SucursalKey      INT            NOT NULL,
    ClienteKey       INT            NOT NULL,
    VendedorKey      INT            NOT NULL,
    UnidadesVendidas INT            NOT NULL,
    PrecioUnitario   DECIMAL(10,2)  NOT NULL,
    MontoVenta       DECIMAL(14,2)  NOT NULL,    -- = Unidades * PrecioUnitario
    CONSTRAINT PK_FactVentas     PRIMARY KEY (VentaKey),
    CONSTRAINT FK_FV_Tiempo      FOREIGN KEY (TiempoKey)   REFERENCES dbo.DimTiempo(TiempoKey),
    CONSTRAINT FK_FV_Producto    FOREIGN KEY (ProductoKey) REFERENCES dbo.DimProducto(ProductoKey),
    CONSTRAINT FK_FV_Sucursal    FOREIGN KEY (SucursalKey) REFERENCES dbo.DimSucursal(SucursalKey),
    CONSTRAINT FK_FV_Cliente     FOREIGN KEY (ClienteKey)  REFERENCES dbo.DimCliente(ClienteKey),
    CONSTRAINT FK_FV_Vendedor    FOREIGN KEY (VendedorKey) REFERENCES dbo.DimVendedor(VendedorKey)
);
GO

-- ============================================================
-- 6. POBLAR DimTiempo (2015 - 2030)
-- No viene de los CSV, se genera por rango de fechas.
-- El rango cubre todos los años presentes en los datos.
-- ============================================================
WITH Fechas AS (
    SELECT CAST('2015-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha)
    FROM   Fechas
    WHERE  Fecha < '2030-12-31'
)
INSERT INTO dbo.DimTiempo (TiempoKey, FechaCompleta, Dia, Mes, NombreMes, Trimestre, Anio)
SELECT
    YEAR(Fecha) * 10000 + MONTH(Fecha) * 100 + DAY(Fecha),
    Fecha,
    DAY(Fecha),
    MONTH(Fecha),
    DATENAME(MONTH, Fecha),
    DATEPART(QUARTER, Fecha),
    YEAR(Fecha)
FROM Fechas
OPTION (MAXRECURSION 0);
GO

-- ============================================================
-- 7. VERIFICACIÓN RÁPIDA
-- ============================================================
SELECT 'DimTiempo'   AS Tabla, COUNT(*) AS Filas FROM dbo.DimTiempo
UNION ALL
SELECT 'DimProducto',  COUNT(*) FROM dbo.DimProducto
UNION ALL
SELECT 'DimSucursal',  COUNT(*) FROM dbo.DimSucursal
UNION ALL
SELECT 'DimProveedor', COUNT(*) FROM dbo.DimProveedor
UNION ALL
SELECT 'DimCliente',   COUNT(*) FROM dbo.DimCliente
UNION ALL
SELECT 'DimVendedor',  COUNT(*) FROM dbo.DimVendedor
UNION ALL
SELECT 'FactCompras',  COUNT(*) FROM dbo.FactCompras
UNION ALL
SELECT 'FactVentas',   COUNT(*) FROM dbo.FactVentas;
GO