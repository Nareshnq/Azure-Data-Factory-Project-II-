# Self-Hosted Integration Runtime — Setup Guide

## What Is a Self-Hosted IR?

The **Self-Hosted Integration Runtime (SHIR)** is a software agent you install on a Windows machine inside your private network. It enables ADF (which lives in the Azure cloud) to securely reach data sources that are behind a firewall — like an on-premises SQL Server, a local file system, or a company database.

## Analogy

> Moving houses (migrating data):
> - **ADF** = the moving coordinator making a list of boxes
> - **AutoResolve IR** = a standard mail truck moving between public post offices
> - **Self-Hosted IR** = a specialized security van with keys to your private gated driveway

## Why Is It Needed?

1. **Security:** Azure cannot reach into a private company server directly — that would be a security hole.
2. **The Agent Model:** The SHIR sits inside the private network and *reaches out* to ADF asking "Do you have any jobs for me?" — then pushes data up to Azure.
3. **Connectivity:** Without SHIR, ADF pipelines targeting local sources get a "Connection Denied" error.

## When to Use Which IR

| Scenario | Use This IR |
|---|---|
| Azure Storage → Azure Storage | `AutoResolveIntegrationRuntime` |
| REST API → Azure Storage | `AutoResolveIntegrationRuntime` |
| On-prem File System → ADLS | `naresh-self-hosted-IR` |
| On-prem SQL Server → Azure SQL | `naresh-self-hosted-IR` |
| Azure SQL DB → ADLS | `AutoResolveIntegrationRuntime` |

## Step-by-Step Setup

### 1. Create the SHIR in ADF

1. Open ADF → **Manage** → **Integration Runtimes** → **+ New**
2. Select **Self-Hosted**
3. Give it a name (e.g., `naresh-self-hosted-IR`)
4. Choose **Option 2: Manual setup**
5. Copy **Key 1** (save it — you'll need it on your machine)

### 2. Install the Runtime on Your Windows Machine

1. Download **Microsoft Integration Runtime** from the setup wizard link or Microsoft's website
2. Run the installer
3. Once installed, the **Microsoft Integration Runtime Configuration Manager** opens automatically

### 3. Register the Machine

1. Paste **Key 1** into the Authentication Key field
2. Click **Register**
3. The status should show **Connected** / **Running**

### 4. Verify in ADF

Go back to ADF → **Manage** → **Integration Runtimes**. You should see:

| Name | Type | Status |
|---|---|---|
| AutoResolveIntegrationRuntime | Azure | Running |
| naresh-self-hosted-IR | Self-Hosted | Running |

## Troubleshooting

### Error: Local Folder Path Validation Failed

When creating a File System Linked Service using a local path (e.g., `C:\Azure_project2_files_for_Migration`), ADF may refuse the connection with a path validation error.

**Fix (run PowerShell as Administrator on the SHIR machine):**

```powershell
cd "C:\Program Files\Microsoft Integration Runtime\5.0\Shared\"
.\dmgcmd.exe -DisableLocalFolderPathValidation
```

After running this, re-test the connection in ADF — it should succeed.

### Error: Connection Denied / Cannot Reach Source

- Verify the SHIR machine is **running** (check Windows Services → "Integration Runtime Service")
- Check that the machine has **network access** to the data source
- Ensure no firewall rules block outbound HTTPS (port 443) from the SHIR machine to Azure

## High Availability (Production Recommendation)

For production use, register **at least 2 nodes** for the Self-Hosted IR. This enables:

- Automatic failover if one node goes down
- Load balancing across nodes
- Zero-downtime IR updates

To add a second node, repeat the registration steps with the same authentication key on a second machine.
