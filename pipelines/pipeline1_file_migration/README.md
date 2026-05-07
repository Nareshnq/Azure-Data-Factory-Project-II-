# Pipeline 1 — On-Premises File System Migration

## Overview

This pipeline migrates **banking transaction datasets** from a local Windows file system to **Azure Data Lake Storage Gen2**. It uses a **ForEach + IfCondition** pattern to selectively copy only banking-related files from a folder that contains mixed file types.

## Source Data

**Location:** `C:\Azure_project2_files_for_Migration`

Files in source folder:

| File Name | Type | Size |
|---|---|---|
| Bank_transaction_small_dataset | Excel | 41 KB |
| Bank_txns1 | Excel | 7 KB |
| Bank_txns2 | Excel | 7 KB |
| DimAirline | CSV | 1 KB |
| DimFlight | CSV | 1 KB |
| DimPassenger | CSV | 1 KB |
| Fact_Sales_1 | CSV | 320 KB |
| Fact_Sales_2 | CSV | 3 KB |

> Only `Bank_*` files are migrated by this pipeline using an IfCondition filter.

## Pipeline Flow

```
GetMetadata (List files in source folder)
        ↓
ForEach (Iterate over each file)
        ↓
  IfCondition (Does filename start with "Bank_"?)
        ├── TRUE  → Copy Data (Source: FileSystemLS1 → Sink: ADLS_LS)
        └── FALSE → Skip
```

## Activities

| Activity | Type | Purpose |
|---|---|---|
| `ForEach1` | ForEach | Iterates all files in source folder |
| `If Condition1` | IfCondition | Filters for bank transaction files only |
| `Copy data1` | Copy | Moves filtered files to ADLS |

## Integration Runtime

| Component | IR Used |
|---|---|
| Source (File System) | `naresh-self-hosted-IR` |
| Sink (ADLS Gen2) | `AutoResolveIntegrationRuntime` |

## Linked Services

- **Source:** `FileSystemLS1` — points to `C:\Azure_project2_files_for_Migration`
- **Sink:** `ADLS_LS` — Azure Data Lake Storage Gen2

## Known Issues & Fixes

### Connection Failed on File System Linked Service

When testing the connection, ADF may throw a local folder path validation error.

**Fix (run PowerShell as Administrator):**
```powershell
cd "C:\Program Files\Microsoft Integration Runtime\5.0\Shared\"
.\dmgcmd.exe -DisableLocalFolderPathValidation
```

Source: StackOverflow workaround for Self-Hosted IR local path restriction.

## Result

Successfully migrated all `Bank_*` files from the local Windows machine to Azure Data Lake Storage Gen2.
