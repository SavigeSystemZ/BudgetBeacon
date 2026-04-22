# Architecture

## Overview
Budget Beacon is a client-side only Progressive Web App (PWA) built with React, Vite, and TypeScript.
It relies on IndexedDB (via Dexie) for local-first persistence, ensuring user financial data remains on their device.

## Components
- **Frontend**: React 19, React Router, TailwindCSS for styling.
- **State/Persistence**: Dexie.js for IndexedDB.
- **Build/Packaging**: Vite, TypeScript, and a custom Bash installer for Linux desktop integration.
