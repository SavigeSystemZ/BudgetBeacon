# gRPC Service Blueprint

Use this for internal or external services that benefit from protobuf contracts and strong client generation.

## Expectations

- Protobuf files are the canonical contract
- Generated code is clearly separated from handwritten service logic
- Health checking and version compatibility are defined early
- Transport security and auth model are explicit

## Validation commands

- Protobuf generation or lint step
- Service unit tests
- Contract or integration tests using a generated client

## First milestone suggestion

1. Define the first protobuf service and messages.
2. Implement a health endpoint.
3. Verify one client round trip in tests.
