# MB Packet Radio

Portable Dart codecs for KISS-framed TNC links and a strict AX.25 modulo-8 frame
subset. Build packet-radio utilities, offline diagnostics and transport adapters
without importing a mobile app or cloud service.

**Developer preview: 0.1.0.** Prepared for community stewardship through
Mountain Brief Foundation. This is a codec library, not a modem or a connected-mode
AX.25 session implementation. There are no runtime dependencies outside the Dart
SDK, no Flutter requirement and no networking or hardware access.

## Try it offline

Install Dart 3.4 or newer, then run these commands from the package directory:

```sh
git clone https://github.com/MountainBrief/packet-radio-dart.git mb-packet-radio-dart
cd mb-packet-radio-dart
dart pub get
dart run example/mb_packet_radio_example.dart
dart test
```

`pub get` downloads development tools on the first run. The example and codec
tests run locally and neither open a transport nor transmit a packet.

To use a local checkout from another Dart or Flutter project:

```yaml
dependencies:
  mb_packet_radio:
    path: ../mb-packet-radio-dart
```

The package is distributed through GitHub, rather than pub.dev, for the initial
developer preview. Its pubspec contains `publish_to: none`.

## Encode, fragment and decode a packet

```dart
import 'dart:convert';
import 'package:mb_packet_radio/mb_packet_radio.dart';

void main() {
  final packet = Ax25Frame.u(
    destination: Ax25Address('APRS'),
    source: Ax25Address('N0CALL', 1), // Synthetic example callsign.
    command: true,
    control: Ax25UControl.ui,
    info: utf8.encode('Hello packet radio'),
  );

  final wire = KissCodec.encode(
    KissFrame(port: 0, payload: Ax25Codec.encode(packet)),
  );
  final receiver = KissReassembler();
  for (final chunk in KissCodec.chunk(wire, mtu: 23)) {
    for (final frame in receiver.addChunk(chunk)) {
      if (!frame.isData) continue;
      final decoded = Ax25Codec.decode(frame.payload);
      print('${decoded.source}: ${utf8.decode(decoded.info)}');
    }
  }
}
```

Use each `KissReassembler` for one transport byte stream. Call `reset()` when
that transport disconnects. A KISS command frame is represented separately from
a data frame; applications should check `isData` before passing payloads to AX.25.

## Supported profile

| Component | Included | Outside this release |
| --- | --- | --- |
| KISS | All 16 port/command nibble values, escaping of type and payload bytes, fragmented/coalesced streams, idle delimiters | TNC command execution, hardware setup, checksummed KISS extensions |
| Addressing | ASCII alphanumeric callsigns of 1–6 characters; SSIDs 0–15; source/destination C and extension bits | Digipeater paths; legacy equal-C-bit AX.25 1.x frames |
| AX.25 frames | Modulo-8 I, RR/RNR/REJ, SABM/UA/DISC/DM/FRMR/UI; P/F bits; UI and I PID bytes | Modulo-128, SABME, SREJ, XID/TEST and unknown U controls |
| Framing boundary | AX.25 bytes from destination through information, before FCS | HDLC flags, FCS generation/verification, bit stuffing, audio or RF modulation |
| Transport | Pure byte APIs; optional ATT-sized chunk arithmetic | Bluetooth scanning, permissions, serial/TCP connections, retransmission or connection timers |

The codec does not establish delivery, issuing authority or permission to
transmit. It is not a complete AX.25 2.2 implementation or an APRS application.
Successful decoding means only that a frame matches this documented subset.

### Bounds and error behavior

- KISS defaults to at most **4096 decoded body bytes**, including the type byte,
  and **32 retained error messages** per reassembler. Both are configurable.
- Bytes before the first delimiter are ignored. Invalid escapes, truncated
  escapes at a delimiter and oversized frames cause the whole frame to be
  discarded until the next delimiter. This strict policy differs from parsers
  that keep assembling after an invalid escape.
- Memory retained for an incomplete frame and diagnostics is bounded. A call
  that contains many complete frames returns all of them; callers own that
  output and should bound transport chunk sizes as appropriate.
- AX.25 I/UI information defaults to at most **256 bytes**. The
  `maxInformationBytes` argument on encode/decode can explicitly select a
  different limit; match it to the actual modem and application.
- FRMR carries exactly three information bytes in this modulo-8 profile. Other
  supported non-UI U frames and all S frames reject trailing information.
- Invalid sequence numbers, SSIDs, PIDs, integer bytes and frame/control
  combinations are rejected rather than silently truncated. Frame payloads
  are defensive copies exposed as read-only byte views.
- `Ax25Codec.tryDecode` returns `null` for malformed or unsupported wire data.
  Invalid configuration, such as a negative information limit, still throws.

## Development

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart run example/mb_packet_radio_example.dart
```

Tests include hand-authored wire fixtures, binary payloads, every KISS
port/command combination, every split of an escaped fixture, randomized transport
fragmentation, corrupt-frame recovery, resource limits and malformed AX.25 input.
These are offline software tests; live TNC/radio interoperability is future work.

See [CONTRIBUTING.md](CONTRIBUTING.md), [PROVENANCE.md](PROVENANCE.md) and
[docs/RELEASE_READINESS.md](docs/RELEASE_READINESS.md).

## Origins and license

Extracted from Mountain Brief's Dart mobile-app codecs, with standalone
packaging and validation changes. This extraction includes no ESP32 APRS
firmware, GPL firmware library, operational configuration, resident records,
authentication secrets or original repository history.

Apache-2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). Copyright attribution
follows the original source history; Foundation stewardship does not imply an
assignment of copyright. Publication status and the prepared release decision
are recorded in [docs/RELEASE_READINESS.md](docs/RELEASE_READINESS.md).

Protocol references: [KISS by K3MC and KA9Q](https://www.ax25.net/kiss.aspx) and
[TAPR/ARRL AX.25 specification](https://files.tapr.org/tech_docs/AX25/AX25.2.2.pdf).
Those documents explain the wire protocols; their text and implementations are
not bundled or relicensed by this package.
