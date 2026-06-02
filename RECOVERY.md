# Budget Beacon Disaster Recovery Guide

As a local-first application, **your device is the sole custodian of your financial data** unless you have specifically configured and run export or sync routines.

## Routine Backups (Highly Recommended)
We strongly recommend creating routine manual backups.
1. Open the application.
2. Navigate to **Settings**.
3. Under "Data Management", select **Export Backup**.
4. This will download a JSON file containing your entire household data (Ledger, Bills, Tax Records, etc.).
5. Store this file in a secure location (e.g., a trusted cloud drive, USB stick, or password manager).

## Restoring from a Backup
If you move to a new device or accidentally wipe your data:
1. Open the application on your device.
2. Navigate to **Settings** -> **Restore from JSON**.
3. Select your previously exported backup file.
4. **Warning:** Restoring from a JSON backup will completely overwrite your current local database with the contents of the backup. Ensure this is what you intend.

## Device Loss & E2EE Sync (M10+)
If you use the End-to-End Encrypted (E2EE) Sync over a relay server:
*   The relay server holds an encrypted cache of your state (to allow offline catching up).
*   **Crucial:** If you lose your device, you can *only* recover this synced data if you have another device already paired to the household, OR if you have safely stored your **Recovery Codes** or a **Join Code** (including your Household Key).
*   If you lose your only device and do not have a JSON backup or a way to derive your Household Key, **your synced data is unrecoverable** because the relay server cannot decrypt it.

## Extreme Corruption
In the rare event that your IndexedDB becomes irreversibly corrupted:
1. Navigate to your browser's Developer Tools (F12) -> Application -> IndexedDB.
2. Delete the `BudgetBeaconDB`.
3. Reload the page. You will be placed at the onboarding screen.
4. Use a recent JSON backup to restore your data.
