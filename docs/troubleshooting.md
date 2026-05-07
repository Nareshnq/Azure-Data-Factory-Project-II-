# Troubleshooting Guide

## Common Errors and Fixes

---

### 1. File System Linked Service — Connection Failed

**Error:** `Connection failed` when testing File System Linked Service in ADF

**Cause:** Self-Hosted IR blocks local folder path access by default.

**Fix:**
```powershell
# Run PowerShell as Administrator on the SHIR machine
cd "C:\Program Files\Microsoft Integration Runtime\5.0\Shared\"
.\dmgcmd.exe -DisableLocalFolderPathValidation
```

Re-test the connection after running this command.

---

### 2. Pipeline Debug — DEDICATED_SPERRBCODED Error

**Error:** `Conversion failed when converting date and/or time from character string`

**Cause:** The watermark value in `last_load.json` was stored as a full JSON object instead of a plain string.

**Wrong format in JSON:**
```json
{ "firstRow": { "lastload": "1900-01-01T01:37:13.02389762" } }
```

**Correct format:**
```json
{ "lastload": "1900-01-01T00:00:00Z" }
```

**Fix:** Edit `last_load.json` directly in the ADLS portal and ensure only the value (not the Lookup output wrapper) is stored.

---

### 3. Watermark Not Updating After Re-Run

**Symptom:** Re-running the pipeline shows the same `lastload` timestamp — it hasn't moved forward.

**Cause:** No new data was inserted into the source table with a booking date beyond the current watermark.

**Explanation:** If `MAX(booking_date)` hasn't changed (no new rows added), the delta query returns 0 rows. The watermark activity still runs, but writes the same value back.

**Fix:** Insert new rows with dates beyond the current watermark, then re-run.

---

### 4. Self-Hosted IR Shows "Offline" in ADF

**Symptom:** Integration Runtime status shows Offline or Disconnected.

**Causes & Fixes:**

| Cause | Fix |
|---|---|
| SHIR Windows Service stopped | Open Services → Restart "Integration Runtime Service" |
| Machine powered off | Power on the SHIR host machine |
| Firewall blocking outbound 443 | Allow outbound HTTPS from SHIR machine |
| Authentication key expired | Re-register using a new key from ADF |

---

### 5. Parquet Mapping Error

**Error:** Schema mismatch when writing to Parquet sink.

**Fix:** In the Copy Activity → **Mapping** tab, click **Import schemas** to auto-map source columns to sink. Clear any stale mappings first.

---

### 6. Lookup Returns Empty firstRow

**Error:** `The key 'lastload' doesn't exist in firstRow`

**Cause:** The JSON file is empty or malformed.

**Fix:** Ensure `last_load.json` contains valid JSON:
```json
{ "lastload": "1900-01-01T00:00:00Z" }
```

Also verify the Lookup activity's **First row only** setting is checked.
