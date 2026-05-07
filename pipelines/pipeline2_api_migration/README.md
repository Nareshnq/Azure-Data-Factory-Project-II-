# Pipeline 2 — API to Azure Migration

## Overview

This pipeline pulls data from a **GitHub REST API** using a **Web Activity** and lands it in **Azure Data Lake Storage Gen2** using a **Copy Activity**. It demonstrates the classic real-world ADF pattern for API-based data ingestion.

## The Pattern: Web Activity + Copy Activity

```
Web Activity (HTTP GET → GitHub API)
        ↓
Copy Data Activity (API Response → ADLS Gen2)
```

### Why Both Activities?

| Use Case | Copy Data | Web Activity |
|---|---|---|
| Move data from API → Storage | ✅ Yes | ❌ No |
| Trigger an external REST endpoint | ❌ No | ✅ Yes |
| Get an OAuth/Bearer token | ❌ No | ✅ Yes |
| Call a webhook before pipeline | ❌ No | ✅ Yes |
| Read small JSON response for logic | ❌ No | ✅ Yes |
| Notify Slack/Teams on failure | ❌ No | ✅ Yes |

**In short:**
- `Copy Data` = the truck that **moves** the data
- `Web Activity` = the phone call you make **before** sending the truck

## Pipeline Flow

```
Web Activity API 1
(GET https://github.com/NareshHindu/Data7-...)
        ↓
Copy data1
(REST source → ADLS sink)
```

## Activities

| Activity | Type | Description |
|---|---|---|
| `Web Activity API 1` | Web | HTTP GET call to GitHub API |
| `Copy data1` | Copy | Transfers API data to ADLS |

## Web Activity Configuration

| Property | Value |
|---|---|
| URL | `https://github.com/NareshHindu/Data7-...` |
| Method | GET |
| Authentication | None (public repo) |

## Integration Runtime

Both activities use `AutoResolveIntegrationRuntime` — cloud-to-cloud, no on-prem involved.

## Result

Pipeline ran successfully. Data was fetched from GitHub via the API and landed in ADLS Gen2.

## When to Use This Pattern in Production

If your API requires:
- OAuth token refresh before each call → use Web Activity to get token, pass it to Copy Activity
- Pagination (multiple pages of results) → use ForEach + Web Activity
- Triggering a job on a remote server before copying → Web Activity first, then Copy
- Reading configuration from a config endpoint → Web Activity at pipeline start
