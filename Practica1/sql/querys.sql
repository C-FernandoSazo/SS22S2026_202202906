-- 1 Conteo de hechos
SELECT COUNT(*) AS fact_rows
FROM dbo.FactTicketFlight;

-- 2 Conteo por dimensión
SELECT 'DimPassenger' AS dim, COUNT(*) total FROM dbo.DimPassenger
UNION ALL SELECT 'DimAirline', COUNT(*) FROM dbo.DimAirline
UNION ALL SELECT 'DimAirport', COUNT(*) FROM dbo.DimAirport
UNION ALL SELECT 'DimDateTime', COUNT(*) FROM dbo.DimDateTime;