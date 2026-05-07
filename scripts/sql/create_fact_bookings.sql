-- =============================================
-- Create FactBookings Table
-- Azure SQL Database: sql-database
-- Server: sql-sserver1 (Canada Central)
-- =============================================

CREATE TABLE dbo.FactBookings (
    booking_id          INT             NOT NULL,
    passenger_id        INT             NOT NULL,
    flight_id           INT             NOT NULL,
    airline_id          INT             NOT NULL,
    origin_airport      INT             NOT NULL,
    destination_id      INT             NOT NULL,
    booking_date        DATE            NOT NULL,
    ticket_cost         DECIMAL(10, 1)  NOT NULL,
    flight_duration     INT             NOT NULL,
    checkin_status      VARCHAR(10)     NOT NULL
);

-- =============================================
-- Optional: Add soft-delete support
-- (recommended for incremental load patterns)
-- =============================================

-- ALTER TABLE dbo.FactBookings
-- ADD isDeleted BIT DEFAULT 0,
--     LastUpdated DATETIME DEFAULT GETDATE();
