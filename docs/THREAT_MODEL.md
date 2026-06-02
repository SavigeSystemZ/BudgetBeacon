# Budget Beacon Threat Model

## 1. Application Architecture Overview
Budget Beacon is a local-first application built using web technologies (React, IndexedDB/Dexie, Capacitor). The primary source of truth for all user financial data is the user's own device. Data is not synced to a central cloud server by default. When sync is explicitly enabled by the user (M10+), it uses an End-to-End Encrypted (E2EE) Conflict-Free Replicated Data Type (CRDT) over WebSockets.

## 2. Trust Boundaries
*   **The Device:** The local OS (Android, iOS, Windows, macOS, Linux) is trusted. If the device is compromised (rooted/jailbroken with malicious software installed, or physically accessed while unlocked), the local database (IndexedDB) can be read.
*   **The Relay Server (Opt-In):** The WebSocket relay server is **UNTRUSTED**. It only routes messages. It never possesses the decryption keys.
*   **The Network:** The network (Wi-Fi, Cellular) is **UNTRUSTED**. All external communication happens over TLS, and the synced payloads are internally encrypted before transit.

## 3. Data Storage & Local Security
*   **Local Data:** Financial data (Ledger, Pay Path, Stash Map) is stored in IndexedDB. It is *not* encrypted at rest within IndexedDB, relying on the OS's full-disk encryption and user authentication (lock screen).
*   **Key Storage:** The E2EE Sync Keypair and Household Key are derived and stored in IndexedDB as exported JWK/Raw values. Since the app targets a frictionless "no-login" experience, these keys are available to the running app. We depend on the OS sandbox (Webkit/Blink isolation or Capacitor sandbox) to prevent cross-site/cross-app access.
*   **Destructive Actions:** All actions that destroy data (e.g., wiping the database or deleting loops) require an explicit confirmation modal.

## 4. Sync & E2EE Crypto (M10/M11)
*   **Encryption:** Data is encrypted using `crypto.subtle` AES-GCM (256-bit). The initialization vector (IV) is uniquely generated for every update.
*   **Joint Households (M11):** Pairing devices uses an Elliptic Curve Diffie-Hellman (ECDH) key exchange over the P-256 curve. The public keys are exchanged out-of-band (e.g., via secure messaging or QR codes). The derived shared secret is used to wrap the Household Key securely using AES-GCM before transfer.
*   **Integrity:** GCM mode inherently provides authenticated encryption, ensuring that sync payloads cannot be tampered with by the relay or an attacker without being detected and rejected by the receiving device.

## 5. Third-Party Integrations
*   **Bank Data:** Imported strictly locally (CSV, OFX, QFX). No financial credentials or Plaid-like tokens are ever stored or requested by the core application.
*   **OCR (Vault):** Tesseract.js runs entirely locally in WebAssembly. Documents never leave the device.
*   **AI Assistant:** If configured to use an external API (like OpenAI), the user must explicitly provide an API key. Only specific context subsets are transmitted. By default, it encourages local models (e.g., Ollama).

## 6. Known Risks & Acceptances
1.  **Device Loss:** If a device is lost without a screen lock, the financial data is exposed.
2.  **XSS Vulnerability:** As an HTML5 app, an XSS flaw could theoretically extract the IndexedDB data or keys. We mitigate this through strict React escaping, CSP, and avoiding `innerHTML`.
3.  **No Cloud Backup Default:** Because it's local-first, if a device is destroyed and no manual backup or sync was established, the data is irretrievably lost.
