# Source provenance

Extracted on November 26, 2026 from canonical Mountain Brief source commit
`4bfd8531de009c30bf28187b92c1d85501352c2b` on `platform/mb-native`.
The operational repository and its history were not copied into this package.

| Package file | Original path under resident/mountainbrief_app/ | Original Git blob |
| --- | --- | --- |
| lib/src/kiss.dart | lib/ops/tnclink/mb_kiss_codec.dart | 2fcebfd9115d3324c30d6bab0580210abd2b4f0c |
| lib/src/ax25_address.dart | lib/ops/ax25/mb_ax25_address.dart | 276a20b22456ca26148d4e77a18b5faae4ca31a4 |
| lib/src/ax25_codec.dart | lib/ops/ax25/mb_ax25_codec.dart | b96671a0b0583546505f0216c9c4f39b3918f8cf |
| lib/src/ax25_frame.dart | lib/ops/ax25/mb_ax25_frame.dart | e7ad69a25684b501d349060850e0e36fecf6c36a |

The original file histories record Stijn Vanveerdeghem as author, beginning with
commits `4c22e0bb4` (KISS) and `3dad0473e` (AX.25). Subsequent AX.25 fixes include
`8ab232e1b` and `4f7948f63`. Author metadata is attribution evidence and does not
resolve employment, contractor, patent or other ownership rights.

## Changes during extraction

- Rename file imports and introduce a single public Dart library.
- Copy payload/information bytes into read-only views; reject out-of-range
  integer inputs instead of wrapping or masking them.
- Replace KISS buffering with a bounded incremental state machine, retaining
  only a bounded diagnostic history.
- Escape the KISS type byte as well as payload bytes and decode it after
  unescaping. The original encoder escaped only the payload.
- Require a starting delimiter; discard malformed frames until the next
  delimiter and document that strict stream-recovery policy.
- Reject unsupported AX.25 controls, trailing control-frame information,
  inconsistent frame models and invalid U-frame command/response combinations.
- Introduce an explicit I/UI information limit and modulo-8 FRMR length check.
- Add synthetic independent wire fixtures, adversarial input and fragmentation
  tests, standalone packaging, example, documentation and CI.

No source was copied from ESP32/APRS firmware, WinlinkKit, wl2k-go, Dire Wolf or
another third-party implementation for this extraction. Protocol references
are linked in README.md. Source files in this package have undergone extraction
changes and are not claimed to be byte-identical to the source blobs above.
