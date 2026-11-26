USE DW_AndinaRetail;


SELECT
    SUM(Ingresos) AS Ingresos_Totales_USD,
    CAST(((SUM(Ingresos) - SUM(CostoVentas)) / NULLIF(SUM(Ingresos), 0)) * 100.0 AS DECIMAL(6,2)) AS Margen_Bruto_Pct,
    CAST((SUM(UtilidadNeta) / NULLIF(SUM(Ingresos), 0)) * 100.0 AS DECIMAL(6,2)) AS Margen_Utilidad_Neta_Pct,
    CAST(SUM(UtilidadNeta) / NULLIF(SUM(InversionesRealizadas), 0) AS DECIMAL(6,2)) AS ROI_Global,
    SUM(FlujoCaja) AS Flujo_Caja_Neto_USD,
    CAST(SUM(FlujoCaja) / NULLIF(SUM(GastosOperativos), 0) AS DECIMAL(6,2)) AS Cobertura_Flujo_Veces
FROM dw.Fact_Finanzas;


SELECT
    SUM(VentaTotal) AS Ventas_Totales_USD,
    COUNT(DISTINCT OrdenID) AS Total_Ordenes,
    CAST(SUM(VentaTotal) / NULLIF(COUNT(DISTINCT OrdenID), 0) AS DECIMAL(10,2)) AS Ticket_Promedio_USD,
    COUNT(DISTINCT ClienteKey) AS Clientes_Con_Compra,
    CAST(SUM(VentaTotal) / NULLIF(COUNT(DISTINCT ClienteKey), 0) AS DECIMAL(10,2)) AS Ventas_Promedio_Cliente_USD
FROM dw.Fact_Ventas;

SELECT
    SUM(VisitasWeb) AS Total_Visitas_Web,
    SUM(ConversionesWeb) AS Total_Conversiones_Web,
    CAST((CAST(SUM(ConversionesWeb) AS DECIMAL(12,2)) / NULLIF(SUM(VisitasWeb), 0)) * 100.0 AS DECIMAL(6,2)) AS Tasa_Conversion_Web_Pct
FROM dw.Fact_Web_Cliente;


SELECT
    c.NombreCanal,
    SUM(fv.VentaTotal) AS Ventas_Canal_USD,
    CAST((SUM(fv.VentaTotal) / SUM(SUM(fv.VentaTotal)) OVER ()) * 100.0 AS DECIMAL(6,2)) AS Participacion_Pct
FROM dw.Fact_Ventas fv
INNER JOIN dw.Dim_Canal c ON fv.CanalKey = c.CanalKey
GROUP BY c.NombreCanal;


WITH VentasMes AS (
    SELECT
        t.AnioMes,
        t.NombreMes,
        SUM(fv.VentaTotal) AS Ventas_Mes
    FROM dw.Fact_Ventas fv
    INNER JOIN dw.Dim_Tiempo t ON fv.TiempoKey = t.TiempoKey
    GROUP BY t.AnioMes, t.NombreMes
)
SELECT
    AnioMes,
    NombreMes,
    Ventas_Mes,
    LAG(Ventas_Mes) OVER (ORDER BY AnioMes) AS Ventas_Mes_Anterior,
    CAST(
        ((Ventas_Mes - LAG(Ventas_Mes) OVER (ORDER BY AnioMes))
         / NULLIF(LAG(Ventas_Mes) OVER (ORDER BY AnioMes), 0)) * 100.0
    AS DECIMAL(6,2)) AS Crecimiento_Mensual_Pct
FROM VentasMes
ORDER BY AnioMes;