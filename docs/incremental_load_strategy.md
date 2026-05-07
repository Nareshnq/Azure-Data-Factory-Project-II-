# Incremental Load Strategy — Watermark Pattern

## Full Load vs Incremental Load

| | Full Load | Incremental Load |
|---|---|---|
| What it does | Copies ALL rows every run | Copies only NEW/CHANGED rows |
| Speed | Slow (grows with table size) | Fast (constant small batches) |
| Cost | High DIU usage | Low DIU usage |
| Recovery | Restart entire load | Restart only the failed slice |
| Use case | Initial/one-time migration | Daily/scheduled production loads |

## Watermark Concept

A **watermark** is a column in your source table that records when a row was last inserted or updated. Common column names:

- `booking_date`
- `LastUpdated`
- `ModifiedDate`
- `created_at`
- `updated_at`

Think of it like a bookmark in a book. ADF reads up to the bookmark, then next time starts from where the bookmark was left.

## The Four-Step Pattern

### Step 1: Read Last Watermark
ADF reads the watermark file (JSON in ADLS or a control table in SQL) to find where the previous run ended.

```json
{ "lastload": "2025-06-30T00:00:00Z" }
```

### Step 2: Get Current Max Watermark
ADF queries the source table to find the most recent timestamp:

```sql
SELECT MAX(booking_date) AS latestload FROM dbo.FactBookings
-- Returns: 2025-08-13T00:00:00Z
```

### Step 3: Copy the Delta
ADF runs the incremental copy with both boundaries:

```sql
SELECT * FROM dbo.FactBookings
WHERE booking_date > '2025-06-30T00:00:00Z'
  AND booking_date <= '2025-08-13T00:00:00Z'
```

### Step 4: Update the Watermark
Write the new max timestamp back to the watermark file so next run starts from here:

```json
{ "lastload": "2025-08-13T00:00:00Z" }
```

## ADF Implementation Details

### Lookup Activity (Last Watermark)
- **Source:** `last_load.json` in ADLS (`monitor/last_load/`)
- **Output:** `activity('Lookup1_last_load').output.firstRow.lastload`

### Lookup Activity (Latest Watermark)
- **Source:** Azure SQL DB
- **Query:** `SELECT MAX(booking_date) AS latestload FROM dbo.FactBookings`
- **Output:** `activity('Lookup1_latest_load').output.firstRow.latestload`

### Copy Activity (Delta Copy) — Dynamic Query
```
SELECT * FROM dbo.FactBookings
WHERE booking_date > '@{activity('Lookup1_last_load').output.firstRow.lastload}'
AND booking_date <= '@{activity('Lookup1_latest_load').output.firstRow.latestload}'
```

### Copy Activity (Watermark Update)
- **Source:** Empty JSON file (dummy — satisfies ADF requirement for a source)
- **Sink:** `last_load.json` in ADLS
- **Additional Column:**
  - Name: `lastload`
  - Value: `@activity('Lookup1_latest_load').output.firstRow.latestload`

## Why Parquet for the Sink?

Parquet is a **columnar storage format** that compresses data significantly:

| Metric | Value |
|---|---|
| Data read from SQL | 60,054 KB |
| Data written (Parquet) | 28,572 KB |
| Compression | ~52% size reduction |

This is why modern data lakes use Parquet (or Delta Lake) instead of CSV for storage.

## Handling Deletes: Soft Delete Pattern

Watermarks only track INSERT and UPDATE. Physical DELETE operations are invisible to this pattern.

**Solution — Soft Deletes:**

```sql
-- Add a soft delete flag
ALTER TABLE dbo.FactBookings ADD isDeleted BIT DEFAULT 0;

-- Instead of DELETE:
UPDATE dbo.FactBookings SET isDeleted = 1, LastUpdated = GETDATE()
WHERE booking_id = 123;
```

Now ADF picks up the change (because `LastUpdated` changes) and syncs `isDeleted = 1` to ADLS.

## Benefits in Medallion Architecture

In a Bronze → Silver → Gold architecture:
- **Bronze layer** receives all incremental raw data
- **Silver layer** applies deduplication and cleansing
- **Gold layer** builds final aggregated business views

Incremental loading keeps Bronze lean and Silver/Gold processing fast.
