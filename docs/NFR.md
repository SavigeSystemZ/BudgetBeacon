# Non-Functional Requirements (NFRs)

## Performance
- The application must load instantly as a PWA.
- Dashboard summaries and transaction lists must render without noticeable delay.

## Security & Privacy
- All data must remain on the local device (IndexedDB). No cloud sync is currently implemented.
- The app must not expose any financial data externally.

## Reliability
- Calculations for remaining budget and rollups must be accurate.
