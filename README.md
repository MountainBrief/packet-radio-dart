# MB Packet Radio

KISS framing and AX.25 frame codecs for Dart applications, command-line tools
and Flutter projects. Use the same byte APIs for offline diagnostics and your
own transport adapters.

**0.1.0 · Developer preview · Dart 3.4+ · Apache-2.0**

A community software project stewarded by Mountain Brief Foundation.
Copyright owner: Mountain Brief LLC. Original author: Stijn Vanveerdeghem.

The library uses only the Dart SDK. It provides frame encoding and decoding;
applications supply the transport and any connected-session behavior.

## Quickstart

```sh
git clone https://github.com/MountainBrief/packet-radio-dart.git
cd packet-radio-dart
dart pub get
dart run example/mb_packet_radio_example.dart
dart test
```

The example encodes a synthetic packet, fragments the KISS bytes and decodes
them again, entirely offline. The first `pub get` downloads development tools.

To use a local checkout from another Dart or Flutter project:

```yaml
dependencies:
  mb_packet_radio:
    path: ../packet-radio-dart
```

## Encode and decode

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
    KissFrame(payload: Ax25Codec.encode(packet)),
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

Use one `KissReassembler` per transport byte stream and call `reset()` on
disconnect. Check `isData` before treating a KISS payload as AX.25.
`KissCodec.chunk` calculates ATT-sized fragments without accessing Bluetooth.

## Supported profile

| Component | Support |
| --- | --- |
| KISS | All 16 port and command field values; escaped type/payload bytes; fragmented and coalesced frames; idle delimiters |
| Addressing | Source and destination callsigns of 1–6 ASCII alphanumeric characters; SSIDs 0–15; C and extension bits |
| AX.25 | Modulo-8 I, RR/RNR/REJ and SABM/UA/DISC/DM/FRMR/UI frames; P/F bits; I/UI PID bytes |
| Byte boundary | AX.25 destination address through information, before HDLC FCS |

This preview excludes digipeater paths, legacy equal-C-bit addresses,
modulo-128, SABME, SREJ, XID/TEST and unknown U controls. It includes no
connection timers, retransmission engine, Bluetooth/serial/TCP adapter, FCS,
bit stuffing, audio modem or RF transmission. It is a documented codec subset,
not a complete AX.25 implementation or an APRS application.

### Limits and recovery

- KISS defaults to **4096 decoded body bytes**, including the type byte, and
  **32 retained error messages**. Both limits are configurable.
- Bytes before the first FEND are ignored. Malformed and oversized frames are
  discarded until the next FEND; incomplete frames remain pending. This strict
  policy drops a corrupt frame rather than retaining bytes after a bad escape.
- Pending frame storage and diagnostic history are bounded. Completed frames
  returned by `addChunk` belong to the caller; bound transport chunk sizes to
  control the size of each returned list.
- I/UI information defaults to **256 bytes**. Set `maxInformationBytes` on
  encode/decode to choose an explicit alternative. Match it to your transport.
- Modulo-8 FRMR information is exactly three bytes. Other supported non-UI U
  frames and all S frames reject trailing information.
- Invalid byte values, sequence numbers, PIDs and frame/control combinations
  are rejected. Payloads are copied into read-only views.
- `Ax25Codec.tryDecode` returns `null` for unsupported or malformed frames.
  Invalid configuration, such as a negative limit, still throws.

## Development and feedback

```sh
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

See [validation](docs/VALIDATION.md) for tested environments and evidence.
Minimal synthetic wire fixtures, parser edge cases and TNC compatibility
reports are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and
[SECURITY.md](SECURITY.md).

## Origins and license

Developed within Mountain Brief and extracted into a standalone package for
radio and emergency-communications developers. Development included AI-assisted
coding; the source history and extraction changes are recorded in
[PROVENANCE.md](PROVENANCE.md).

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for terms and attribution.
The initial distribution is through GitHub; the package is not on pub.dev.

Protocol references: [KISS by K3MC and KA9Q](https://www.ax25.net/kiss.aspx) and
[TAPR/ARRL AX.25](https://files.tapr.org/tech_docs/AX25/AX25.2.2.pdf).
