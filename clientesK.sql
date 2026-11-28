USE DW_AndinaRetail;

SELECT
    c.ClienteID,
    c.Segmento,
    c.Region,
    ISNULL(v.MontoTotal, 0)         AS MontoTotal,
    ISNULL(v.FrecuenciaOrdenes, 0)  AS FrecuenciaOrdenes,
    ISNULL(v.TicketPromedio, 0)     AS TicketPromedio,
    ISNULL(w.VisitasWeb, 0)         AS VisitasWeb,
    ISNULL(w.ConversionesWeb, 0)    AS ConversionesWeb
FROM dw.Dim_Cliente c
LEFT JOIN (
    SELECT
        ClienteKey,
        SUM(VentaTotal) AS MontoTotal,
        COUNT(DISTINCT OrdenID) AS FrecuenciaOrdenes,
        CAST(SUM(VentaTotal) / NULLIF(COUNT(DISTINCT OrdenID), 0) AS DECIMAL(12,2)) AS TicketPromedio
    FROM dw.Fact_Ventas
    GROUP BY ClienteKey
) v ON c.ClienteKey = v.ClienteKey
LEFT JOIN dw.Fact_Web_Cliente w ON c.ClienteKey = w.ClienteKey
WHERE c.EsActual = 1
ORDER BY c.ClienteID;