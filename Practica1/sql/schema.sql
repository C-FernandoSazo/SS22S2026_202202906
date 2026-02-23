-- =========================================
-- Practica 1 - Modelo Estrella (SQL Server)
-- Archivo: sql/01_schema.sql
-- =========================================

-- Limpieza
IF OBJECT_ID('dbo.FactTicketFlight', 'U') IS NOT NULL DROP TABLE dbo.FactTicketFlight;

IF OBJECT_ID('dbo.DimPassenger', 'U') IS NOT NULL DROP TABLE dbo.DimPassenger;
IF OBJECT_ID('dbo.DimAirline', 'U') IS NOT NULL DROP TABLE dbo.DimAirline;
IF OBJECT_ID('dbo.DimAirport', 'U') IS NOT NULL DROP TABLE dbo.DimAirport;
IF OBJECT_ID('dbo.DimAircraft', 'U') IS NOT NULL DROP TABLE dbo.DimAircraft;
IF OBJECT_ID('dbo.DimCabin', 'U') IS NOT NULL DROP TABLE dbo.DimCabin;
IF OBJECT_ID('dbo.DimSalesChannel', 'U') IS NOT NULL DROP TABLE dbo.DimSalesChannel;
IF OBJECT_ID('dbo.DimPaymentMethod', 'U') IS NOT NULL DROP TABLE dbo.DimPaymentMethod;
IF OBJECT_ID('dbo.DimCurrency', 'U') IS NOT NULL DROP TABLE dbo.DimCurrency;
IF OBJECT_ID('dbo.DimDateTime', 'U') IS NOT NULL DROP TABLE dbo.DimDateTime;
GO

-- ======================
-- DIMENSIONS
-- ======================

CREATE TABLE dbo.DimPassenger (
    PassengerKey INT IDENTITY(1,1) PRIMARY KEY,
    passenger_id UNIQUEIDENTIFIER NOT NULL,
    passenger_gender VARCHAR(10) NULL,
    passenger_age INT NULL,
    passenger_nationality VARCHAR(10) NULL,
    CONSTRAINT UQ_DimPassenger UNIQUE (passenger_id)
);

CREATE TABLE dbo.DimAirline (
    AirlineKey INT IDENTITY(1,1) PRIMARY KEY,
    airline_code VARCHAR(10) NOT NULL,
    airline_name VARCHAR(100) NULL,
    CONSTRAINT UQ_DimAirline UNIQUE (airline_code)
);

CREATE TABLE dbo.DimAirport (
    AirportKey INT IDENTITY(1,1) PRIMARY KEY,
    airport_code VARCHAR(10) NOT NULL,
    CONSTRAINT UQ_DimAirport UNIQUE (airport_code)
);

CREATE TABLE dbo.DimAircraft (
    AircraftKey INT IDENTITY(1,1) PRIMARY KEY,
    aircraft_type VARCHAR(20) NOT NULL,
    CONSTRAINT UQ_DimAircraft UNIQUE (aircraft_type)
);

CREATE TABLE dbo.DimCabin (
    CabinKey INT IDENTITY(1,1) PRIMARY KEY,
    cabin_class VARCHAR(20) NOT NULL,
    CONSTRAINT UQ_DimCabin UNIQUE (cabin_class)
);

CREATE TABLE dbo.DimSalesChannel (
    SalesChannelKey INT IDENTITY(1,1) PRIMARY KEY,
    sales_channel VARCHAR(20) NOT NULL,
    CONSTRAINT UQ_DimSalesChannel UNIQUE (sales_channel)
);

CREATE TABLE dbo.DimPaymentMethod (
    PaymentMethodKey INT IDENTITY(1,1) PRIMARY KEY,
    payment_method VARCHAR(30) NOT NULL,
    CONSTRAINT UQ_DimPaymentMethod UNIQUE (payment_method)
);

CREATE TABLE dbo.DimCurrency (
    CurrencyKey INT IDENTITY(1,1) PRIMARY KEY,
    currency VARCHAR(10) NOT NULL,
    CONSTRAINT UQ_DimCurrency UNIQUE (currency)
);

CREATE TABLE dbo.DimDateTime (
    DateTimeKey INT IDENTITY(1,1) PRIMARY KEY,
    dt DATETIME2(0) NOT NULL,
    [year] INT NOT NULL,
    [month] INT NOT NULL,
    [day] INT NOT NULL,
    [hour] INT NOT NULL,
    [minute] INT NOT NULL,
    CONSTRAINT UQ_DimDateTime UNIQUE (dt)
);

GO

-- ======================
-- FACT TABLE
-- ======================
CREATE TABLE dbo.FactTicketFlight (
    record_id INT NOT NULL PRIMARY KEY,  -- viene del dataset

    PassengerKey INT NOT NULL,
    AirlineKey INT NOT NULL,
    OriginAirportKey INT NOT NULL,
    DestinationAirportKey INT NOT NULL,
    AircraftKey INT NOT NULL,
    CabinKey INT NOT NULL,
    SalesChannelKey INT NOT NULL,
    PaymentMethodKey INT NOT NULL,
    CurrencyKey INT NOT NULL,

    BookingDateKey INT NOT NULL,
    DepartureDateKey INT NULL,
    ArrivalDateKey INT NULL,

    -- atributos de evento
    flight_number VARCHAR(20) NULL,
    seat VARCHAR(10) NULL,
    status VARCHAR(20) NULL,

    -- métricas
    ticket_price DECIMAL(18,2) NULL,
    ticket_price_usd_est DECIMAL(18,2) NULL,
    duration_min INT NULL,
    delay_min INT NULL,
    bags_total INT NULL,
    bags_checked INT NULL,

    -- FKs
    CONSTRAINT FK_Fact_Passenger FOREIGN KEY (PassengerKey) REFERENCES dbo.DimPassenger(PassengerKey),
    CONSTRAINT FK_Fact_Airline FOREIGN KEY (AirlineKey) REFERENCES dbo.DimAirline(AirlineKey),
    CONSTRAINT FK_Fact_OriginAirport FOREIGN KEY (OriginAirportKey) REFERENCES dbo.DimAirport(AirportKey),
    CONSTRAINT FK_Fact_DestinationAirport FOREIGN KEY (DestinationAirportKey) REFERENCES dbo.DimAirport(AirportKey),
    CONSTRAINT FK_Fact_Aircraft FOREIGN KEY (AircraftKey) REFERENCES dbo.DimAircraft(AircraftKey),
    CONSTRAINT FK_Fact_Cabin FOREIGN KEY (CabinKey) REFERENCES dbo.DimCabin(CabinKey),
    CONSTRAINT FK_Fact_SalesChannel FOREIGN KEY (SalesChannelKey) REFERENCES dbo.DimSalesChannel(SalesChannelKey),
    CONSTRAINT FK_Fact_PaymentMethod FOREIGN KEY (PaymentMethodKey) REFERENCES dbo.DimPaymentMethod(PaymentMethodKey),
    CONSTRAINT FK_Fact_Currency FOREIGN KEY (CurrencyKey) REFERENCES dbo.DimCurrency(CurrencyKey),
    CONSTRAINT FK_Fact_BookingDate FOREIGN KEY (BookingDateKey) REFERENCES dbo.DimDateTime(DateTimeKey),
    CONSTRAINT FK_Fact_DepartureDate FOREIGN KEY (DepartureDateKey) REFERENCES dbo.DimDateTime(DateTimeKey),
    CONSTRAINT FK_Fact_ArrivalDate FOREIGN KEY (ArrivalDateKey) REFERENCES dbo.DimDateTime(DateTimeKey)
);
GO

-- indices para rendimiento en análisis
CREATE INDEX IX_Fact_AirlineKey ON dbo.FactTicketFlight(AirlineKey);
CREATE INDEX IX_Fact_OriginAirportKey ON dbo.FactTicketFlight(OriginAirportKey);
CREATE INDEX IX_Fact_DestinationAirportKey ON dbo.FactTicketFlight(DestinationAirportKey);
CREATE INDEX IX_Fact_BookingDateKey ON dbo.FactTicketFlight(BookingDateKey);
GO