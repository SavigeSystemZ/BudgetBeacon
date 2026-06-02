# Budget Beacon Installation Guide

## Android (Recommended)
Budget Beacon is distributed as a hardened sideload APK. It is not available on the Google Play Store to maintain absolute privacy and avoid third-party analytics tracking requirements.

1. Download the latest `budget-beacon-vX.X.X.apk` from the GitHub Releases page.
2. Transfer the file to your Android device.
3. Open a file manager, tap the APK, and select **Install**.
   * *Note: You may be prompted to allow installation from "Unknown Sources". Allow this for your file manager.*
4. Open the app and begin tracking your budget.

## Desktop / Web
Budget Beacon can be built and run locally on any desktop.

### Prerequisites
*   Node.js v20+
*   npm

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/budget-beacon.git
   cd budget-beacon
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```
4. Access the app at `http://localhost:5173`.

### Production Build
To create a static production build:
```bash
npm run build
```
You can serve the contents of the `dist/` directory using any static file server (e.g., Caddy, Nginx, Python `http.server`).

## Progressive Web App (PWA)
If served over HTTPS, you can install Budget Beacon as a PWA on iOS, Android, macOS, or Windows by selecting "Add to Home Screen" or "Install App" from your browser menu.
