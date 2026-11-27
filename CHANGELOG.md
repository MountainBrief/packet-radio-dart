# Changelog

## 0.1.0 — developer preview

- Dart-only KISS and AX.25 address/frame codecs, extracted from Mountain Brief.
- Bounded incremental KISS parsing, diagnostic retention and frame recovery.
- Escaping of KISS type and payload bytes across all port/command field values.
- Immutable byte snapshots and strict sequence, PID and frame/control validation.
- Explicit I/UI information limits and modulo-8 FRMR length validation.
- Offline example, independent wire fixtures, binary payload tests and adversarial
  stream/fragmentation coverage.
- Documentation of the supported subset, source provenance and CI validation.
