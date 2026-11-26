
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_AndinaRetail')
BEGIN
    CREATE DATABASE DW_AndinaRetail;
END;
GO

USE DW_AndinaRetail;
GO


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg') EXEC('CREATE SCHEMA stg;');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw')  EXEC('CREATE SCHEMA dw;');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl') EXEC('CREATE SCHEMA etl;');
GO


IF OBJECT_ID('stg.stg_Ventas', 'U') IS NOT NULL DROP TABLE stg.stg_Ventas;
CREATE TABLE stg.stg_Ventas (
    OrdenID VARCHAR(50) NULL,
    Fecha  VARCHAR(50) NULL,
    ClienteID VARCHAR(50) NULL,
    Categoria VARCHAR(50) NULL,
    Producto VARCHAR(100) NULL,
    Canal VARCHAR(50) NULL,
    Cantidad INT NULL,
    PrecioUnitario DECIMAL(12,2)  NULL,
    Total DECIMAL(12,2)  NULL,
    Vendedor VARCHAR(80) NULL,
    Region  VARCHAR(50) NULL,
    FechaCarga DATETIME NOT NULL DEFAULT GETDATE()
);

IF OBJECT_ID('stg.stg_Clientes', 'U') IS NOT NULL DROP TABLE stg.stg_Clientes;

CREATE TABLE stg.stg_Clientes (
    ClienteID           VARCHAR(50)  NULL,
    Nombre              VARCHAR(100) NULL,
    Segmento            VARCHAR(50)  NULL,
    Region              VARCHAR(50)  NULL,
    FechaRegistro       VARCHAR(50)  NULL,
    VisitasWeb2024      INT          NULL,
    ConversionesWeb2024 INT          NULL,
    FechaCarga          DATETIME     NOT NULL DEFAULT GETDATE()
);

IF OBJECT_ID('stg.stg_Finanzas', 'U') IS NOT NULL DROP TABLE stg.stg_Finanzas;
CREATE TABLE stg.stg_Finanzas (
    Mes                   VARCHAR(50)   NULL,
    Ingresos              DECIMAL(14,2) NULL,
    CostoVentas           DECIMAL(14,2) NULL,
    GastosOperativos      DECIMAL(14,2) NULL,
    UtilidadNeta          DECIMAL(14,2) NULL,
    FlujoCaja             DECIMAL(14,2) NULL,
    InversionesRealizadas DECIMAL(14,2) NULL,
    RetornoInversion      DECIMAL(10,4) NULL,
    FechaCarga            DATETIME      NOT NULL DEFAULT GETDATE()
);
GO


IF OBJECT_ID('dw.Fact_Ventas', 'U')      IS NOT NULL DROP TABLE dw.Fact_Ventas;
IF OBJECT_ID('dw.Fact_Finanzas', 'U')    IS NOT NULL DROP TABLE dw.Fact_Finanzas;
IF OBJECT_ID('dw.Fact_Web_Cliente', 'U') IS NOT NULL DROP TABLE dw.Fact_Web_Cliente;

IF OBJECT_ID('dw.Dim_Tiempo', 'U')   IS NOT NULL DROP TABLE dw.Dim_Tiempo;
IF OBJECT_ID('dw.Dim_Cliente', 'U')  IS NOT NULL DROP TABLE dw.Dim_Cliente;
IF OBJECT_ID('dw.Dim_Producto', 'U') IS NOT NULL DROP TABLE dw.Dim_Producto;
IF OBJECT_ID('dw.Dim_Canal', 'U')    IS NOT NULL DROP TABLE dw.Dim_Canal;
IF OBJECT_ID('dw.Dim_Region', 'U')   IS NOT NULL DROP TABLE dw.Dim_Region;
IF OBJECT_ID('dw.Dim_Vendedor', 'U') IS NOT NULL DROP TABLE dw.Dim_Vendedor;
GO

CREATE TABLE dw.Dim_Tiempo (
    TiempoKey       INT         NOT NULL PRIMARY KEY, 
    Fecha           DATE        NOT NULL UNIQUE,
    Dia             INT         NOT NULL,
    Mes             INT         NOT NULL,
    NombreMes       VARCHAR(20) NOT NULL,
    Trimestre       INT         NOT NULL,
    Semestre        INT         NOT NULL,
    Anio            INT         NOT NULL,
    AnioMes         INT         NOT NULL,             
    DiaSemana       VARCHAR(15) NOT NULL,
    EsFinDeSemana   BIT         NOT NULL,
    EsTemporadaAlta BIT         NOT NULL              
);

CREATE TABLE dw.Dim_Cliente (
    ClienteKey          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClienteID           VARCHAR(10)       NOT NULL,
    Nombre              VARCHAR(80)       NOT NULL,
    Segmento            VARCHAR(20)       NOT NULL,
    Region              VARCHAR(30)       NOT NULL,
    FechaRegistro       DATE              NOT NULL,
    AntiguedadMeses     INT               NOT NULL,
    SegmentoAnalitico   VARCHAR(30)       NULL,       
    FechaInicioVigencia DATE              NULL,
    FechaFinVigencia    DATE              NULL,
    EsActual            BIT               NOT NULL 
);


CREATE TABLE dw.Dim_Producto (
    ProductoKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Producto    VARCHAR(50)       NOT NULL,
    Categoria   VARCHAR(30)       NOT NULL,
    CONSTRAINT UQ_Dim_Producto UNIQUE (Producto, Categoria)
);

CREATE TABLE dw.Dim_Canal (
    CanalKey    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreCanal VARCHAR(20)       NOT NULL UNIQUE,
    TipoCanal   VARCHAR(15)       NOT NULL
);

CREATE TABLE dw.Dim_Region (
    RegionKey    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreRegion VARCHAR(30)       NOT NULL UNIQUE,
    Pais         VARCHAR(30)       NOT NULL DEFAULT 'El Salvador'
);

CREATE TABLE dw.Dim_Vendedor (
    VendedorKey    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreVendedor VARCHAR(40)       NOT NULL UNIQUE,
    Sede           VARCHAR(30)       NOT NULL
);
GO

CREATE TABLE dw.Fact_Ventas (
    VentaKey       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrdenID        VARCHAR(10)       NOT NULL UNIQUE,
    TiempoKey      INT               NOT NULL,
    ClienteKey     INT               NOT NULL,
    ProductoKey    INT               NOT NULL,
    CanalKey       INT               NOT NULL,
    RegionKey      INT               NOT NULL,
    VendedorKey    INT               NOT NULL,
    Cantidad       INT               NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2)     NOT NULL CHECK (PrecioUnitario > 0),
    VentaTotal     DECIMAL(12,2)     NOT NULL CHECK (VentaTotal > 0),
    CONSTRAINT FK_FactVentas_Tiempo   FOREIGN KEY (TiempoKey)   REFERENCES dw.Dim_Tiempo(TiempoKey),
    CONSTRAINT FK_FactVentas_Cliente  FOREIGN KEY (ClienteKey)  REFERENCES dw.Dim_Cliente(ClienteKey),
    CONSTRAINT FK_FactVentas_Producto FOREIGN KEY (ProductoKey) REFERENCES dw.Dim_Producto(ProductoKey),
    CONSTRAINT FK_FactVentas_Canal    FOREIGN KEY (CanalKey)    REFERENCES dw.Dim_Canal(CanalKey),
    CONSTRAINT FK_FactVentas_Region   FOREIGN KEY (RegionKey)   REFERENCES dw.Dim_Region(RegionKey),
    CONSTRAINT FK_FactVentas_Vendedor FOREIGN KEY (VendedorKey) REFERENCES dw.Dim_Vendedor(VendedorKey)
);


CREATE TABLE dw.Fact_Finanzas (
    FinanzasKey           INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TiempoKey             INT               NOT NULL UNIQUE,
    Ingresos              DECIMAL(14,2)     NOT NULL CHECK (Ingresos > 0),
    CostoVentas           DECIMAL(14,2)     NOT NULL CHECK (CostoVentas >= 0),
    GastosOperativos      DECIMAL(14,2)     NOT NULL CHECK (GastosOperativos >= 0),
    UtilidadNeta          DECIMAL(14,2)     NOT NULL,
    FlujoCaja             DECIMAL(14,2)     NOT NULL,
    InversionesRealizadas DECIMAL(14,2)     NOT NULL CHECK (InversionesRealizadas >= 0),
    RetornoInversion      DECIMAL(8,4)      NOT NULL,
    CONSTRAINT FK_FactFinanzas_Tiempo FOREIGN KEY (TiempoKey) REFERENCES dw.Dim_Tiempo(TiempoKey)
);


CREATE TABLE dw.Fact_Web_Cliente (
    WebKey          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClienteKey      INT               NOT NULL,
    TiempoKey       INT               NOT NULL, 
    VisitasWeb      INT               NOT NULL CHECK (VisitasWeb >= 0),
    ConversionesWeb INT               NOT NULL CHECK (ConversionesWeb >= 0),
    CONSTRAINT UQ_FactWeb_ClienteTiempo UNIQUE (ClienteKey, TiempoKey),
    CONSTRAINT CK_FactWeb_ConvMenorVis  CHECK (ConversionesWeb <= VisitasWeb),
    CONSTRAINT FK_FactWeb_Cliente FOREIGN KEY (ClienteKey) REFERENCES dw.Dim_Cliente(ClienteKey),
    CONSTRAINT FK_FactWeb_Tiempo  FOREIGN KEY (TiempoKey)  REFERENCES dw.Dim_Tiempo(TiempoKey)
);
GO


IF OBJECT_ID('etl.BitacoraCarga', 'U') IS NOT NULL DROP TABLE etl.BitacoraCarga;
CREATE TABLE etl.BitacoraCarga (
    BitacoraID      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Proceso         VARCHAR(60)       NOT NULL,
    FechaInicio     DATETIME          NOT NULL DEFAULT GETDATE(),
    FechaFin        DATETIME          NULL,
    FilasLeidas     INT               NOT NULL DEFAULT 0,
    FilasCargadas   INT               NOT NULL DEFAULT 0,
    FilasRechazadas INT               NOT NULL DEFAULT 0,
    Estado          VARCHAR(20)       NOT NULL,
    Observaciones   VARCHAR(250)      NULL
);

IF OBJECT_ID('etl.Rechazos', 'U') IS NOT NULL DROP TABLE etl.Rechazos;
CREATE TABLE etl.Rechazos (
    RechazoID     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Proceso       VARCHAR(60)       NOT NULL,
    TablaOrigen   VARCHAR(50)       NOT NULL,
    ClaveRegistro VARCHAR(50)       NULL,
    MotivoRechazo VARCHAR(250)      NOT NULL,
    FechaRechazo  DATETIME          NOT NULL DEFAULT GETDATE()
);
GO

CREATE OR ALTER VIEW etl.vw_Conciliacion_Finanzas_Ventas AS
SELECT
    t.AnioMes,
    t.NombreMes,
    f.Ingresos AS Ingresos_Finanzas,
    ISNULL(v.Ventas_Detalle, 0) AS Ventas_Detalle,
    ISNULL(v.Cantidad_Ordenes, 0) AS Cantidad_Ordenes,
    f.Ingresos - ISNULL(v.Ventas_Detalle, 0) AS Brecha_USD,
    CAST(
        CASE WHEN f.Ingresos > 0
             THEN (ISNULL(v.Ventas_Detalle, 0) / f.Ingresos) * 100.0
             ELSE 0
        END AS DECIMAL(6,2)
    ) AS Porcentaje_Cobertura
FROM dw.Fact_Finanzas f
INNER JOIN dw.Dim_Tiempo t ON f.TiempoKey = t.TiempoKey
LEFT JOIN (
    SELECT
        dt.AnioMes,
        SUM(fv.VentaTotal) AS Ventas_Detalle,
        COUNT(fv.OrdenID) AS Cantidad_Ordenes
    FROM dw.Fact_Ventas fv
    INNER JOIN dw.Dim_Tiempo dt ON fv.TiempoKey = dt.TiempoKey
    GROUP BY dt.AnioMes
) v ON t.AnioMes = v.AnioMes;
GO


SET DATEFIRST 1; 
DECLARE @Fecha DATE = '2024-01-01';

WHILE @Fecha <= '2024-12-31'
BEGIN
    INSERT INTO dw.Dim_Tiempo (
        TiempoKey, Fecha, Dia, Mes, NombreMes,
        Trimestre, Semestre, Anio, AnioMes,
        DiaSemana, EsFinDeSemana, EsTemporadaAlta
    )
    VALUES (
        YEAR(@Fecha) * 10000 + MONTH(@Fecha) * 100 + DAY(@Fecha),
        @Fecha,
        DAY(@Fecha),
        MONTH(@Fecha),
        CASE MONTH(@Fecha)
            WHEN 1 THEN 'Enero'       WHEN 2 THEN 'Febrero'    WHEN 3 THEN 'Marzo'
            WHEN 4 THEN 'Abril'       WHEN 5 THEN 'Mayo'       WHEN 6 THEN 'Junio'
            WHEN 7 THEN 'Julio'       WHEN 8 THEN 'Agosto'     WHEN 9 THEN 'Septiembre'
            WHEN 10 THEN 'Octubre'    WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
        END,
        DATEPART(QUARTER, @Fecha),
        CASE WHEN MONTH(@Fecha) <= 6 THEN 1 ELSE 2 END,
        YEAR(@Fecha),
        YEAR(@Fecha) * 100 + MONTH(@Fecha),
        CASE DATEPART(WEEKDAY, @Fecha)
            WHEN 1 THEN 'Lunes'     WHEN 2 THEN 'Martes'    WHEN 3 THEN 'Miércoles'
            WHEN 4 THEN 'Jueves'    WHEN 5 THEN 'Viernes'   WHEN 6 THEN 'Sábado'
            WHEN 7 THEN 'Domingo'
        END,
        CASE WHEN DATEPART(WEEKDAY, @Fecha) IN (6, 7) THEN 1 ELSE 0 END,
        CASE WHEN MONTH(@Fecha) IN (11, 12) THEN 1 ELSE 0 END
    );

    SET @Fecha = DATEADD(DAY, 1, @Fecha);
END;
GO



SELECT s.name AS Esquema, t.name AS Tabla
FROM sys.tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;

SELECT COUNT(*) AS Total_Dias_2024, MIN(TiempoKey) AS PrimerDia, MAX(TiempoKey) AS UltimoDia
FROM dw.Dim_Tiempo;


USE DW_AndinaRetail;

-- 1. Conteo de filas de todas las tablas del Datawarehouse
SELECT 'Dim_Tiempo'       AS Tabla, COUNT(*) AS Filas FROM dw.Dim_Tiempo       UNION ALL
SELECT 'Dim_Cliente',               COUNT(*)          FROM dw.Dim_Cliente      UNION ALL
SELECT 'Dim_Producto',              COUNT(*)          FROM dw.Dim_Producto     UNION ALL
SELECT 'Dim_Canal',                 COUNT(*)          FROM dw.Dim_Canal        UNION ALL
SELECT 'Dim_Region',                COUNT(*)          FROM dw.Dim_Region       UNION ALL
SELECT 'Dim_Vendedor',              COUNT(*)          FROM dw.Dim_Vendedor     UNION ALL
SELECT 'Fact_Ventas',               COUNT(*)          FROM dw.Fact_Ventas      UNION ALL
SELECT 'Fact_Finanzas',             COUNT(*)          FROM dw.Fact_Finanzas    UNION ALL
SELECT 'Fact_Web_Cliente',          COUNT(*)          FROM dw.Fact_Web_Cliente;

-- 2. Totales clave para verificar exactitud contra el Excel
SELECT SUM(VentaTotal) AS Total_Ventas_USD FROM dw.Fact_Ventas;
SELECT SUM(Ingresos) AS Total_Ingresos_Finanzas_USD FROM dw.Fact_Finanzas;
SELECT SUM(ConversionesWeb) AS Total_Conversiones_Web FROM dw.Fact_Web_Cliente;

-- 3. Revisar bitácora, rechazos y conciliación mensual
SELECT * FROM etl.BitacoraCarga;
SELECT * FROM etl.Rechazos;
SELECT * FROM etl.vw_Conciliacion_Finanzas_Ventas ORDER BY AnioMes;