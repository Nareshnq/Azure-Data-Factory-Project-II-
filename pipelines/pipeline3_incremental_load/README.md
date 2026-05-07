# Pipeline 3 — Incremental Load: Azure SQL DB → ADLS

## Overview

This pipeline implements an **incremental (watermark-based) load** from **Azure SQL Database** (`dbo.FactBookings`) to **Azure Data Lake Storage Gen2** in **Parquet format**. Only new or updated records since the last successful run are copied — making it efficient, cost-effective, and production-ready.

## The Problem With Full Loads

When using `SELECT * FROM dbo.FactBookings`, ADF reads **every row every time**.

- Table has 1,000 rows today → reads 1,000 rows
- Table has 10,000,000 rows next year → reads 10,000,000 rows
- Load window grows until it eventually overlaps the next scheduled run

## The Solution: Watermark Pattern

A **watermark** is a timestamp column (`booking_date`, `LastUpdated`, `ModifiedDate`) that acts as a bookmark:

> "I already read everything up to `2025-06-30`. Today, only show me records after that date."

### How It Works

```
Step 1: Lookup Old Watermark
        READ last_load.json → { "lastload": "2025-06-30T00:00:00Z" }

Step 2: Lookup New Watermark
        SELECT MAX(booking_date) AS latestload FROM dbo.FactBookings
        → 2025-08-13T00:00:00Z

Step 3: Incremental Copy
        SELECT * FROM dbo.FactBookings
        WHERE booking_date > '2025-06-30'
          AND booking_date <= '2025-08-13'

Step 4: Update Watermark
        Write '2025-08-13T00:00:00Z' back to last_load.json
        → Next run starts from 2025-08-13
```

## Pipeline Flow

```
Lookup1_last_load          Lookup1_latest_load
(Read last_load.json)      (SELECT MAX(booking_date))
        \                       /
         \_____________________/
                    ↓
           Copy_from_SQL
     (Incremental copy to ADLS)
                    ↓
             Watermark
     (Write new timestamp to last_load.json)
```

## Activities

| Activity | Type | Description |
|---|---|---|
| `Lookup1_last_load` | Lookup | Reads watermark from `last_load.json` in ADLS |
| `Lookup1_latest_load` | Lookup | Runs `SELECT MAX(booking_date)` on SQL DB |
| `Copy_from_SQL` | Copy | Copies delta rows to ADLS in Parquet format |
| `Watermark` | Copy | Writes new watermark value to `last_load.json` |

## Dynamic Query (Copy Activity Source)

```sql
SELECT * FROM dbo.FactBookings
WHERE booking_date > '@{activity('Lookup1_last_load').output.firstRow.lastload}'
AND booking_date <= '@{activity('Lookup1_latest_load').output.firstRow.latestload}'
```

**Expression breakdown:**

| Part | Meaning |
|---|---|
| `@{...}` | ADF expression language — evaluated at runtime |
| `activity('Lookup1_last_load')` | References the first Lookup activity |
| `.output.firstRow` | Gets the single row returned by the lookup |
| `.lastload` | The key in the JSON file: `{ "lastload": "..." }` |

## Watermark Update — Why an Empty JSON Source?

The **Watermark copy activity** does NOT move business data. It writes the new checkpoint value back to `last_load.json`.

ADF's Copy Activity always requires both a source and a sink. Since we only care about the sink (writing the watermark), we use an **empty JSON file as a dummy source** — just to satisfy ADF's requirement.

The actual value is injected via **Additional Columns**:

| Name | Value |
|---|---|
| `lastload` | `@activity('Lookup1_latest_load').output.firstRow.latestload` |

## Source Table: dbo.FactBookings

```sql
CREATE TABLE dbo.FactBookings (
    booking_id      INT,
    passenger_id    INT,
    flight_id       INT,
    airline_id      INT,
    origin_airport  INT,
    destination_id  INT,
    booking_date    DATE,
    ticket_cost     DECIMAL(10,1),
    flight_duration INT,
    checkin_status  VARCHAR(10)
);
```

Starting rows: **985** → Grew to **1,000+** during testing.

## Sink Configuration

| Property | Value |
|---|---|
| Format | Parquet |
| Path | `ADLS_LS / bronze / <filename>` |
| Linked Service | `ADLS_LS` |

> Parquet compresses data to less than half the original size, significantly reducing storage costs.

## Watermark File Location

```
ADLS Container: monitor
└── last_load/
    └── last_load.json
```

**Initial state:**
```json
{ "lastload": "1900-01-01T00:00:00Z" }
```

**After first run:**
```json
{ "lastload": "2025-06-30T00:00:00Z" }
```

## ⚠️ Important: Soft Deletes

Timestamps catch **INSERT** and **UPDATE** operations, but **not physical deletes**.

If a row is deleted from SQL, the timestamp doesn't change — the row just disappears.

**Production pattern:** Use a soft-delete column:
```sql
ALTER TABLE dbo.FactBookings ADD isDeleted BIT DEFAULT 0;
-- Instead of DELETE, set isDeleted = 1
-- ADF will pick up the change via the updated timestamp
```

## Results

| Metric | Value |
|---|---|
| Data read from SQL | 60,054 KB |
| Rows read | 985 |
| Data written to ADLS (Parquet) | 28,572 KB |
| Compression ratio | ~52% reduction |
| Watermark updated | ✅ `1900-01-01` → `2025-06-30` |
