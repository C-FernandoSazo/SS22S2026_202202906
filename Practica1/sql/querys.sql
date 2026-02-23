-- 1 Conteo de hechos
SELECT COUNT(*) AS fact_rows
FROM dbo.FactTicketFlight;

-- 2 Conteo por dimensión
SELECT 'DimPassenger' AS dim, COUNT(*) total FROM dbo.DimPassenger
UNION ALL SELECT 'DimAirline', COUNT(*) FROM dbo.DimAirline
UNION ALL SELECT 'DimAirport', COUNT(*) FROM dbo.DimAirport
UNION ALL SELECT 'DimDateTime', COUNT(*) FROM dbo.DimDateTime;

-- A) Top 5 destinos
SELECT TOP 5 da.airport_code AS destination, COUNT(*) AS total_tickets
FROM dbo.FactTicketFlight f
JOIN dbo.DimAirport da ON da.AirportKey = f.DestinationAirportKey
GROUP BY da.airport_code
ORDER BY total_tickets DESC;

-- B) Top 5 rutas (origen -> destino)
SELECT TOP 5 
    ao.airport_code AS origin,
    ad.airport_code AS destination,
    COUNT(*) AS total
FROM dbo.FactTicketFlight f
JOIN dbo.DimAirport ao ON ao.AirportKey = f.OriginAirportKey
JOIN dbo.DimAirport ad ON ad.AirportKey = f.DestinationAirportKey
GROUP BY ao.airport_code, ad.airport_code
ORDER BY total DESC;

-- C) Distribución por género
SELECT p.passenger_gender, COUNT(*) AS total
FROM dbo.FactTicketFlight f
JOIN dbo.DimPassenger p ON p.PassengerKey = f.PassengerKey
GROUP BY p.passenger_gender
ORDER BY total DESC;

-- D) Promedio de delay por aerolínea (top 10 con más delay)
SELECT TOP 10 a.airline_name, AVG(CAST(f.delay_min AS FLOAT)) AS avg_delay
FROM dbo.FactTicketFlight f
JOIN dbo.DimAirline a ON a.AirlineKey = f.AirlineKey
GROUP BY a.airline_name
ORDER BY avg_delay DESC;

-- E) % cancelados vs on_time (status en fact)
SELECT status, COUNT(*) AS total
FROM dbo.FactTicketFlight
GROUP BY status
ORDER BY total DESC;

-- F) Ingreso estimado por canal de venta
SELECT sc.sales_channel, SUM(f.ticket_price_usd_est) AS revenue_usd
FROM dbo.FactTicketFlight f
JOIN dbo.DimSalesChannel sc ON sc.SalesChannelKey = f.SalesChannelKey
GROUP BY sc.sales_channel
ORDER BY revenue_usd DESC;

-- G) Ingreso por método de pago
SELECT pm.payment_method, SUM(f.ticket_price_usd_est) AS revenue_usd
FROM dbo.FactTicketFlight f
JOIN dbo.DimPaymentMethod pm ON pm.PaymentMethodKey = f.PaymentMethodKey
GROUP BY pm.payment_method
ORDER BY revenue_usd DESC;

-- H) Tickets por mes de compra (booking)
SELECT dt.[year], dt.[month], COUNT(*) AS total_tickets
FROM dbo.FactTicketFlight f
JOIN dbo.DimDateTime dt ON dt.DateTimeKey = f.BookingDateKey
GROUP BY dt.[year], dt.[month]
ORDER BY dt.[year], dt.[month];

-- I) Equipaje promedio por cabina
SELECT c.cabin_class, AVG(CAST(f.bags_total AS FLOAT)) AS avg_bags
FROM dbo.FactTicketFlight f
JOIN dbo.DimCabin c ON c.CabinKey = f.CabinKey
GROUP BY c.cabin_class
ORDER BY avg_bags DESC;

-- J) Duración promedio por aerolínea
SELECT TOP 10 a.airline_name, AVG(CAST(f.duration_min AS FLOAT)) AS avg_duration
FROM dbo.FactTicketFlight f
JOIN dbo.DimAirline a ON a.AirlineKey = f.AirlineKey
GROUP BY a.airline_name
ORDER BY avg_duration DESC;