# Master Pipeline — Data Orchestration

## Overview

The **Master Pipeline (Parent Pipeline)** aggregates all individual data pipelines into a single orchestrated workflow. It uses the **Execute Pipeline** activity to create a parent-child relationship, where this pipeline controls the overall flow and each child pipeline does the actual data work.

## Why a Master Pipeline?

In production, you don't manually trigger three pipelines every day. The Master Pipeline lets you:

- Run everything from **one trigger**
- Control **execution order** (sequential or parallel)
- Set up **one alert** (Logic Apps) for all failures
- Manage the full workflow from a **single monitoring view**

## Pipeline Structure

```
Master_Pipeline (Parent)
        │
        ├── Execute Pipeline → pipeline1_only_bank_txns
        │       (On-Prem File System Migration)
        │
        ├── Execute Pipeline → pipeline2_API_Migration
        │       (GitHub API to ADLS)
        │
        └── Execute Pipeline → pipeline3_Sql_Data_migration_to_ADLS
                (Incremental Load from Azure SQL DB)
```

## Execute Pipeline Activity

The **Execute Pipeline** activity is the key to orchestration in ADF. It:

- Calls another pipeline from within the current pipeline
- Supports both **synchronous** (wait for completion) and **asynchronous** (fire and forget) modes
- Passes parameters between parent and child pipelines
- Propagates success/failure status back to the parent

## Child Pipelines

| Execute Activity Name | Child Pipeline | Description |
|---|---|---|
| `Execute_PL1_only_pipeline1_only_bank_txns` | `pipeline1_only_bank_txns` | File system migration |
| `Execute_pipeline2_pipeline2_API...` | `pipeline2_API_Migration` | API data ingestion |
| `Execute_pipeline3_pipeline3_Sql_Data...` | `pipeline3_Sql_Data_migration_to_ADLS` | Incremental SQL load |

## Logic Apps Integration

When the Master Pipeline (or any child) fails, a **Logic Apps** workflow sends an alert notification (email/Teams message) with:

- Pipeline name
- Run ID
- Failure reason
- Timestamp

This removes the need to manually monitor ADF every day.

## Trigger

The Master Pipeline is configured with a **Schedule Trigger** to run automatically (e.g., nightly at 2 AM). All child pipelines are triggered through this single parent trigger.
