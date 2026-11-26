# Source provenance

The initial codecs were developed within Mountain Brief on September 21, 2026.
Their Git history credits Stijn Vanveerdeghem with Cursor assistance. Standalone
extraction and hardening also used AI-assisted coding with ChatGPT.

The extraction baseline is Mountain Brief commit
`4bfd8531de009c30bf28187b92c1d85501352c2b`, recorded November 26, 2026.
The original application repository is separate from this package.

| Package file | Original path under resident/mountainbrief_app/ | Original Git blob |
| --- | --- | --- |
| lib/src/kiss.dart | lib/ops/tnclink/mb_kiss_codec.dart | 2fcebfd9115d3324c30d6bab0580210abd2b4f0c |
| lib/src/ax25_address.dart | lib/ops/ax25/mb_ax25_address.dart | 276a20b22456ca26148d4e77a18b5faae4ca31a4 |
| lib/src/ax25_codec.dart | lib/ops/ax25/mb_ax25_codec.dart | b96671a0b0583546505f0216c9c4f39b3918f8cf |
| lib/src/ax25_frame.dart | lib/ops/ax25/mb_ax25_frame.dart | e7ad69a25684b501d349060850e0e36fecf6c36a |

Original KISS introduction: `4c22e0bb485da4b41f4156b416cabae843f2a29f`.
Original AX.25 introduction: `3dad0473ef3003049f44d172fdabad0883e62175`.
Subsequent AX.25 fixes include `8ab232e1b2262f45424d922a4a502df9fc8e8b74`
and `4f7948f63377ffaf70e1c40af70ee942af3d58d5`.

## Extraction changes

- Added standalone Dart packaging and a single public library.
- Added defensive byte copies, read-only payloads and integer range validation.
- Replaced KISS accumulation with bounded incremental parsing and diagnostics.
- Escaped the KISS type byte as well as payload bytes, including values C0/DB.
- Defined delimiter synchronization and strict corrupt-frame recovery.
- Validated supported AX.25 control, information and command/response combinations.
- Added explicit information limits, independent wire fixtures, fragmented and
  adversarial-input tests, an offline example and CI.

The package uses Dart SDK imports and does not bundle Mountain Brief's ESP32
firmware, vendored APRS libraries, WinlinkKit or Bluetooth plugins. The protocol
specifications linked in README.md are references, not included source code.
Copyright and attribution notices are retained in the source headers and NOTICE.
