# Snapshot testing

Encode a fixture with `deterministicJSON()` and check its bytes into a test target. Fixture names encode the requested civil period. If the model changes, review the output and update the snapshot intentionally; do not regenerate expected values from host-local time or environment state.
