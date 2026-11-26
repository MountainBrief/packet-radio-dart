# Changelog

## 0.1.0-dev.1

- Extract KISS and AX.25 address/frame codecs into a Dart-only package.
- Replace unbounded KISS accumulation with bounded incremental decoding.
- Escape and decode KISS type bytes on every port, including type C0 and DB.
- Bound diagnostic retention and recover at the next frame delimiter.
- Reject invalid integer ranges instead of masking sequence numbers or PIDs.
- Validate supported AX.25 frame/control, C-bit and information combinations.
- Include an offline example, independent wire fixtures and fragmented/adversarial
  stream tests.
- Record original source provenance and prepare a private release candidate.
