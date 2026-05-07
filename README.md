# 🏭 Azure Data Factory Project II — End-to-End Data Engineering

> A production-grade Azure Data Engineering project covering on-premises migration, API ingestion, incremental loading, orchestration, and PySpark transformations using the Medallion Architecture.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Pipelines](#pipelines)
- [Setup Guide](#setup-guide)
- [Incremental Load Strategy](#incremental-load-strategy)
- [Data Orchestration](#data-orchestration)
- [Contributing](#contributing)

---

## 🎯 Project Overview

This project demonstrates a **real-world Azure Data Engineering workflow** that migrates and transforms data from multiple sources into a centralized Azure Data Lake using Azure Data Factory (ADF). It follows the **Medallion Architecture** (Bronze → Silver → Gold layers) to progressively refine data for business consumption.

### What This Project Covers

| Area | Description |
|---|---|
| **On-Prem Migration** | File system data migrated from local Windows host to Azure Data Lake Storage Gen2 |
| **API Migration** | GitHub REST API data pulled using Web Activity + Copy Activity pattern |
| **Incremental Loading** | Watermark-based incremental loads from Azure SQL DB to ADLS |
| **Data Orchestration** | Master pipeline using Execute Pipeline activity to chain all workflows |
| **Logic Apps Integration** | Alert notifications when pipeline fails |
| **PySpark Transformations** | Data cleansing and transformations in Databricks/Synapse |
| **Gold Layer** | Aggregated business views for reporting |
| **Triggers & CI/CD** | Schedule triggers + Azure DevOps + GitHub integration |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                             │
│  On-Premises File System │ REST API (GitHub) │ Azure SQL DB     │
└────────────────┬─────────────────┬───────────────┬─────────────┘
                 │                 │               │
        ┌────────▼─────────────────▼───────────────▼────────┐
        │           INTEGRATION RUNTIMES                     │
        │  Self-Hosted IR (On-Prem)  │  AutoResolve IR (Cloud)│
        └────────────────────┬───────────────────────────────┘
                             │
        ┌────────────────────▼───────────────────────────────┐
        │             AZURE DATA FACTORY                      │
        │   Linked Services → Datasets → Pipelines → Triggers │
        └────────────────────┬───────────────────────────────┘
                             │
        ┌────────────────────▼───────────────────────────────┐
        │          AZURE DATA LAKE STORAGE GEN2               │
        │         BRONZE  │  SILVER  │  GOLD (Medallion)      │
        └────────────────────────────────────────────────────┘
```

### Integration Runtime Types

| IR Name | Type | Purpose |
|---|---|---|
| `AutoResolveIntegrationRuntime` | Azure (Cloud) | Cloud-to-cloud data movement |
| `naresh-self-hosted-IR` | Self-Hosted | On-premises to Azure migration |

> **Why IRs first?** Everything else depends on them. You cannot create a Linked Service without choosing an IR. IR setup is always **Step Zero**.

---

## 🛠️ Tech Stack

- **Azure Data Factory (ADF)** — Pipeline orchestration
- **Azure Data Lake Storage Gen2 (ADLS)** — Centralized storage
- **Azure SQL Database** — Source relational database
- **Azure SQL Server** — Hosting SQL DB instance
- **Self-Hosted Integration Runtime** — On-premises connectivity
- **PySpark / Azure Databricks** — Data transformation
- **Azure Logic Apps** — Pipeline failure alerting
- **Azure DevOps** — CI/CD for ADF pipelines
- **GitHub** — Version control & source for API pipeline

---

## 📁 Project Structure

```
azure-adf-project2/
│
├── README.md                          # This file
│
├── docs/
│   ├── architecture.md                # Detailed architecture documentation
│   ├── incremental_load_strategy.md   # Watermark/timestamp strategy explained
│   ├── medallion_architecture.md      # Bronze/Silver/Gold layer definitions
│   └── troubleshooting.md             # Common errors and fixes
│
├── pipelines/
│   ├── pipeline1_file_migration/
│   │   ├── README.md                  # Pipeline 1 documentation
│   │   └── pipeline1_only_bank_txns.json
│   │
│   ├── pipeline2_api_migration/
│   │   ├── README.md                  # Pipeline 2 documentation
│   │   └── pipeline2_API_Migration.json
│   │
│   ├── pipeline3_incremental_load/
│   │   ├── README.md                  # Pipeline 3 documentation
│   │   └── pipeline3_Sql_Data_migration_to_ADLS.json
│   │
│   └── master_pipeline/
│       ├── README.md                  # Master pipeline documentation
│       └── Parent_Pipeline.json
│
├── linked_services/
│   ├── FileSystemLS1.json             # Source: On-prem file system
│   ├── ADLS_LS.json                   # Destination: Azure Data Lake
│   └── SqlDatabaseLinkedService.json  # Source: Azure SQL Database
│
├── integration_runtimes/
│   └── self_hosted_ir_setup.md        # Steps to register Self-Hosted IR
│
├── datasets/
│   ├── ds_sql_source.json             # Azure SQL source dataset
│   ├── Parquet1.json                  # ADLS Parquet sink dataset
│   └── Json2.json                     # Watermark JSON dataset
│
├── scripts/
│   └── sql/
│       ├── create_fact_bookings.sql   # DDL for FactBookings table
│       ├── insert_sample_data.sql     # Sample data inserts (985 → 1000+ rows)
│       └── watermark_query.sql        # Watermark SELECT MAX query
│
├── config/
│   ├── last_load.json                 # Watermark checkpoint file template
│   └── empty.json                     # Dummy source for watermark copy activity
│
└── .github/
    ├── ISSUE_TEMPLATE/
    │   └── bug_report.md
    └── pull_request_template.md
```

---

## 🔁 Pipelines

### Pipeline 1 — On-Premises File System Migration

Migrates **banking transaction datasets** from a local Windows file system to ADLS Gen2.

- **Source:** `C:\Azure_project2_files_for_Migration` (via Self-Hosted IR)
- **Sink:** Azure Data Lake Storage Gen2
- **Key Activities:** ForEach → IfCondition → Copy Data
- **IR Used:** `naresh-self-hosted-IR`

See [`pipelines/pipeline1_file_migration/README.md`](pipelines/pipeline1_file_migration/README.md)

---

### Pipeline 2 — API to Azure Migration

Pulls data from a **GitHub REST API** and lands it in ADLS.

- **Pattern:** Web Activity (GET request) → Copy Activity (land to ADLS)
- **IR Used:** `AutoResolveIntegrationRuntime`
- **Key Concept:** Web Activity handles auth/token; Copy Activity handles data movement

```
Web Activity (GET Token / Call API)
        ↓
Copy Data Activity (Pull Data → Land in ADLS)
```

See [`pipelines/pipeline2_api_migration/README.md`](pipelines/pipeline2_api_migration/README.md)

---

### Pipeline 3 — Incremental Load (SQL → ADLS)

Loads **only new/updated records** from Azure SQL DB using a **Watermark (Timestamp) strategy**.

- **Source:** Azure SQL Database (`dbo.FactBookings`, 1000+ rows)
- **Sink:** ADLS Gen2 — `bronze/` folder in Parquet format
- **Watermark file:** `monitor/last_load/last_load.json`

**Pipeline Flow:**
```
Lookup (LastLoad) → Lookup (LatestLoad) → Copy Data (Incremental) → Copy Watermark (Update Checkpoint)
```

See [`pipelines/pipeline3_incremental_load/README.md`](pipelines/pipeline3_incremental_load/README.md)

---

### Master Pipeline — Data Orchestration

Aggregates all child pipelines using **Execute Pipeline** activity.

```
Master_Pipeline
  ├── Execute: pipeline1_only_bank_txns
  ├── Execute: pipeline2_API_Migration
  └── Execute: pipeline3_Sql_Data_migration_to_ADLS
```

See [`pipelines/master_pipeline/README.md`](pipelines/master_pipeline/README.md)

---

## ⚙️ Setup Guide

### Prerequisites

- Azure Free Account (or Pay-As-You-Go)
- Azure Data Factory instance
- Azure Data Lake Storage Gen2
- Azure SQL Server + SQL Database
- Windows machine (for Self-Hosted IR)
- Python / PowerShell access

### Step 1 — Azure Resources

Create the following resources in one Resource Group (e.g., `Azure_ADF_RG`):

1. Azure Data Factory
2. Azure Data Lake Storage Gen2
3. Azure SQL Server
4. Azure SQL Database

### Step 2 — Integration Runtime Setup

**AutoResolveIntegrationRuntime** — already exists by default in ADF.

**Self-Hosted IR (naresh-self-hosted-IR):**
1. In ADF → Manage → Integration Runtimes → New → Self-Hosted
2. Choose **Manual setup** and copy **Key 1**
3. Download and install **Microsoft Integration Runtime** on your Windows machine
4. Paste Key 1 to register

> **Fix for local folder path error:**
> ```powershell
> # Run PowerShell as Administrator
> cd "C:\Program Files\Microsoft Integration Runtime\5.0\Shared\"
> .\dmgcmd.exe -DisableLocalFolderPathValidation
> ```

### Step 3 — Linked Services

| Name | Type | IR Used |
|---|---|---|
| `FileSystemLS1` | File System | `naresh-self-hosted-IR` |
| `ADLS_LS` | Azure Data Lake Storage Gen2 | `AutoResolveIntegrationRuntime` |
| `SqlDatabaseLinkedService` | Azure SQL Database | `AutoResolveIntegrationRuntime` |

### Step 4 — Watermark Setup

1. Create container `monitor` in ADLS
2. Create folder `last_load/` with file `last_load.json`
3. Initial content:
```json
{ "lastload": "1900-01-01T00:00:00Z" }
```

### Step 5 — Run Pipelines

Run in order, or trigger the **Master Pipeline** which runs all three.

---

## 📈 Incremental Load Strategy

### Why Not Full Load?

| Problem | Impact |
|---|---|
| Reading all 10M rows when only 1K changed | Wastes compute, bandwidth, storage |
| Load window grows over time | Eventually overlaps next scheduled run |
| No cost control | DIU (Data Integration Units) cost spikes |

### Watermark Pattern

```sql
-- Step 1: Get last watermark
SELECT lastload FROM last_load.json          -- e.g., 1900-01-01

-- Step 2: Get current max
SELECT MAX(booking_date) AS latestload
FROM dbo.FactBookings                        -- e.g., 2025-06-30

-- Step 3: Copy only the delta
SELECT * FROM dbo.FactBookings
WHERE booking_date > '@{lastload}'
  AND booking_date <= '@{latestload}'

-- Step 4: Update watermark
-- Write latestload value back to last_load.json
```

### ADF Dynamic Expression Used

```
SELECT * FROM dbo.FactBookings
WHERE booking_date > '@{activity('Lookup1_last_load').output.firstRow.lastload}'
AND booking_date <= '@{activity('Lookup1_latest_load').output.firstRow.latestload}'
```

> ⚠️ **Soft Delete Note:** Timestamps catch **INSERT** and **UPDATE** only. For deleted rows, implement a `isDeleted = 1` soft-delete column pattern.

---

## 🎭 Data Orchestration

The **Master Pipeline** uses the `Execute Pipeline` activity to create a **parent-child** relationship:

- Parent pipeline controls the overall flow and sequencing
- Child pipelines do the actual data movement work
- Failure in any child triggers Logic Apps alert notification

---

