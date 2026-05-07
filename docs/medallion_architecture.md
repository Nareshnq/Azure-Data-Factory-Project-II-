# Medallion Architecture

## Overview

The **Medallion Architecture** is a data design pattern used in modern data lakes to progressively refine raw data into business-ready outputs. It uses three layers — **Bronze**, **Silver**, and **Gold** — each with a distinct purpose.

```
Raw Sources
    ↓
┌─────────┐     ┌─────────┐     ┌─────────┐
│  BRONZE │ ──► │  SILVER │ ──► │   GOLD  │
│  (Raw)  │     │(Cleaned)│     │(Business│
│         │     │         │     │  Views) │
└─────────┘     └─────────┘     └─────────┘
```

## Layer Definitions

### 🥉 Bronze Layer — Raw Ingestion

- **What it stores:** Raw, unmodified data exactly as it arrived from the source
- **Format:** Parquet (compressed), CSV, JSON — whatever the source produces
- **Transformations:** None — data is landed as-is
- **Who writes to it:** ADF Copy Activities (Pipelines 1, 2, 3)
- **ADLS Path:** `bronze/`

**Purpose:** Immutable audit trail. If anything goes wrong in Silver or Gold, you can always reprocess from Bronze.

---

### 🥈 Silver Layer — Cleansed & Conformed

- **What it stores:** Cleaned, validated, deduplicated data
- **Format:** Parquet (Delta Lake in production)
- **Transformations:** PySpark in Databricks or Synapse Analytics
  - Remove nulls and duplicates
  - Standardise data types and formats
  - Apply business rules and joins
- **ADLS Path:** `silver/`

**Purpose:** Single source of truth. Data is reliable and consistent for any downstream use.

---

### 🥇 Gold Layer — Business Views

- **What it stores:** Aggregated, domain-specific datasets ready for reporting
- **Format:** Parquet or Delta Lake
- **Transformations:** Aggregations, KPIs, dimensional models
- **Consumers:** Power BI, Azure Synapse Analytics, Tableau, business analysts
- **ADLS Path:** `gold/`

**Purpose:** Business-ready data. Optimised for read performance and reporting.

---

## This Project's Medallion Flow

```
On-Prem Files      REST API         Azure SQL DB
     │                │                  │
     ▼                ▼                  ▼
  Pipeline 1      Pipeline 2         Pipeline 3
     │                │             (Incremental)
     └────────────────┴──────────────────┘
                       │
                   BRONZE Layer
              (Raw Parquet in ADLS)
                       │
                  PySpark Jobs
              (Databricks/Synapse)
                       │
                   SILVER Layer
              (Cleansed Parquet)
                       │
              Aggregation Queries
                       │
                   GOLD Layer
          (Business Views for Reporting)
```

## Why Parquet Over CSV?

| Feature | CSV | Parquet |
|---|---|---|
| Compression | None | 50–80% smaller |
| Read speed | Slow (full scan) | Fast (columnar reads) |
| Schema enforcement | No | Yes |
| Cost (storage) | High | Low |
| Analytics engine support | Limited | Universal |

In this project, the Bronze layer stores data in **Parquet format**, cutting storage size by ~52% compared to the raw SQL data size.
