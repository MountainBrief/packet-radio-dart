// Copyright 2026 Stijn Vanveerdeghem
// Copyright assigned to Mountain Brief LLC effective 2026-11-26.
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

import 'package:mb_packet_radio/mb_packet_radio.dart';
import 'package:test/test.dart';

// Hand-authored addresses for APRS-2 <- N0CALL-1, command direction.
// These bytes are not generated with the codec under test.
const addresses = [
  0x82,
  0xa0,
  0xa4,
  0xa6,
  0x40,
  0x40,
  0xe4,
  0x9c,
  0x60,
  0x86,
  0x82,
  0x98,
  0x98,
  0x63,
];
final destination = Ax25Address('APRS', 2);
final source = Ax25Address('N0CALL', 1);

Ax25Frame ui([List<int> info = const []]) => Ax25Frame.u(
      destination: destination,
      source: source,
      command: true,
      control: Ax25UControl.ui,
      info: info,
    );
Uint8List raw(List<int> suffix) =>
    Uint8List.fromList([...addresses, ...suffix]);

void main() {
  group('AX.25 address', () {
    test('call/SSID parsing and known wire bytes', () {
      expect(Ax25Address.parse(' n0call-1 '), source);
      expect(Ax25Address.parse('APRS'), Ax25Address('APRS'));
      expect(source.toString(), 'N0CALL-1');
      expect(
          source.encode(last: true, commandCBit: false), addresses.sublist(7));
      final decoded = Ax25Address.decode(addresses, offset: 0);
      expect(decoded.address, destination);
      expect(decoded.commandCBit, isTrue);
      expect(decoded.last, isFalse);
    });

    for (final text in [
      '',
      'TOOLONG',
      'N0CALL-',
      'N0CALL-+1',
      'N0CALL--1',
      'N0CALL-16',
      'N0CALL-256',
      'N0 CALL',
      '-1',
      'N0CALL-1x'
    ]) {
      test('rejects malformed address "$text"', () {
        expect(() => Ax25Address.parse(text),
            throwsA(isA<Ax25AddressException>()));
      });
    }

    test('rejects malformed encoded subfields', () {
      final reserved = addresses.sublist(0, 7)..[6] = 0x84;
      final odd = addresses.sublist(0, 7)..[0] = 0x83;
      final embeddedSpace = addresses.sublist(0, 7)..[1] = 0x40;
      for (final bytes in [
        reserved,
        odd,
        embeddedSpace,
        [256, ...addresses.sublist(1, 7)]
      ]) {
        expect(() => Ax25Address.decode(bytes, offset: 0),
            throwsA(isA<Ax25AddressException>()));
      }
      expect(() => Ax25Address.decode(addresses, offset: -1),
          throwsA(isA<Ax25AddressException>()));
      expect(
          () => Ax25Address('CALL', 16), throwsA(isA<Ax25AddressException>()));
    });
  });

  group('AX.25 independent wire fixtures', () {
    test('UI carries PID immediately after control and no FCS', () {
      final wire = raw([0x03, 0xf0, 0x68, 0x69]);
      expect(Ax25Codec.encode(ui([0x68, 0x69])), wire);
      final decoded = Ax25Codec.decode(wire);
      expect(decoded.uControl, Ax25UControl.ui);
      expect(decoded.pid, 0xf0);
      expect(decoded.info, [0x68, 0x69]);
      expect(decoded.destination, destination);
      expect(decoded.source, source);
      expect(decoded.command, isTrue);
      expect(wire.length, 18);
    });

    test('I frame N(S)=3 N(R)=5 P/F=1 has control B6', () {
      final frame = Ax25Frame.i(
          destination: destination,
          source: source,
          ns: 3,
          nr: 5,
          pollFinal: true,
          info: [0xc0, 0xdb, 0]);
      final wire = raw([0xb6, 0xf0, 0xc0, 0xdb, 0]);
      expect(Ax25Codec.encode(frame), wire);
      final decoded = Ax25Codec.decode(wire);
      expect([decoded.ns, decoded.nr, decoded.pollFinal], [3, 5, true]);
      expect(decoded.info, frame.info);
    });

    for (final entry in {
      Ax25SControl.rr: 0xb1,
      Ax25SControl.rnr: 0xb5,
      Ax25SControl.rej: 0xb9
    }.entries) {
      test('S ${entry.key.name} fixture contains no PID/information', () {
        final frame = Ax25Frame.s(
            destination: destination,
            source: source,
            command: true,
            control: entry.key,
            nr: 5,
            pollFinal: true);
        expect(Ax25Codec.encode(frame), raw([entry.value]));
        final decoded = Ax25Codec.decode(raw([entry.value]));
        expect(decoded.sControl, entry.key);
        expect(decoded.nr, 5);
        expect(decoded.pollFinal, isTrue);
      });
    }

    for (final entry in {
      Ax25UControl.sabm: 0x3f,
      Ax25UControl.ua: 0x73,
      Ax25UControl.disc: 0x53,
      Ax25UControl.dm: 0x1f,
      Ax25UControl.frmr: 0x97
    }.entries) {
      test('U ${entry.key.name} P/F fixture and C-bit direction', () {
        final command =
            entry.key == Ax25UControl.sabm || entry.key == Ax25UControl.disc;
        final info =
            entry.key == Ax25UControl.frmr ? [0x03, 0x10, 0x01] : <int>[];
        final header = List<int>.of(addresses);
        if (!command) {
          header[6] = 0x64;
          header[13] = 0xe3;
        }
        final wire = Uint8List.fromList([...header, entry.value, ...info]);
        final frame = Ax25Frame.u(
            destination: destination,
            source: source,
            command: command,
            control: entry.key,
            pollFinal: true,
            info: info);
        expect(Ax25Codec.encode(frame), wire);
        final decoded = Ax25Codec.decode(wire);
        expect(decoded.command, command);
        expect(decoded.uControl, entry.key);
        expect(decoded.pollFinal, isTrue);
        expect(decoded.info, info);
      });
    }

    test('AX.25 wire bytes survive KISS fragmentation with binary info', () {
      final wire = raw([0x03, 0xf0, 0, 0xc0, 0xdb]);
      final encoded = KissCodec.encode(KissFrame(port: 12, payload: wire));
      final decoder = KissReassembler();
      final frames = encoded.expand((b) => decoder.addChunk([b])).toList();
      expect(frames.single.port, 12);
      expect(Ax25Codec.decode(frames.single.payload).info, [0, 0xc0, 0xdb]);
    });
  });

  group('AX.25 rejects unsupported or lossy inputs', () {
    test('invalid sequences/PID are rejected rather than masked', () {
      for (final value in [-1, 8]) {
        expect(
            () => Ax25Frame.i(
                destination: destination, source: source, ns: value, nr: 0),
            throwsRangeError);
        expect(
            () => Ax25Frame.s(
                destination: destination,
                source: source,
                command: true,
                control: Ax25SControl.rr,
                nr: value),
            throwsRangeError);
      }
      for (final value in [-1, 256]) {
        expect(
            () => Ax25Frame.i(
                destination: destination,
                source: source,
                ns: 0,
                nr: 0,
                pid: value),
            throwsRangeError);
      }
    });

    test('truncation, missing PID, unsupported control and trailing S bytes',
        () {
      for (final wire in [
        Uint8List(0),
        raw([]),
        raw([0x00]),
        raw([0x03]),
        raw([0x01, 0xf0]),
        raw([0x0d]),
        raw([0x6f]),
        raw([0x2f, 0x01])
      ]) {
        expect(Ax25Codec.tryDecode(wire), isNull, reason: '$wire');
      }
    });

    test('rejects wrong address-extension and C-bit combinations', () {
      for (final index in [6, 13]) {
        final wire = raw([0x03, 0xf0])..[index] ^= 1;
        expect(Ax25Codec.tryDecode(wire), isNull);
      }
      final equalC = raw([0x03, 0xf0])..[13] |= 0x80;
      expect(Ax25Codec.tryDecode(equalC), isNull);
    });

    test('rejects mismatched model controls and U information/response', () {
      final models = [
        Ax25Frame(
            destination: destination,
            source: source,
            command: true,
            kind: Ax25FrameKind.i,
            uControl: Ax25UControl.ui),
        Ax25Frame.u(
            destination: destination,
            source: source,
            command: true,
            control: Ax25UControl.ua),
        Ax25Frame.u(
            destination: destination,
            source: source,
            command: false,
            control: Ax25UControl.frmr,
            info: [1, 2]),
        Ax25Frame(
            destination: destination,
            source: source,
            command: true,
            kind: Ax25FrameKind.s,
            sControl: Ax25SControl.rr,
            info: [1]),
      ];
      for (final frame in models) {
        expect(
            () => Ax25Codec.encode(frame), throwsA(isA<Ax25CodecException>()));
      }
    });

    test('information limit is explicit at encode and decode', () {
      final frame = ui(List.filled(257, 0x41));
      expect(() => Ax25Codec.encode(frame), throwsA(isA<Ax25CodecException>()));
      final wire = Ax25Codec.encode(frame, maxInformationBytes: 257);
      expect(Ax25Codec.tryDecode(wire), isNull);
      expect(Ax25Codec.decode(wire, maxInformationBytes: 257).info.length, 257);
      expect(Ax25Codec.encode(ui(List.filled(256, 0x41))).length, 272);
      expect(() => Ax25Codec.decode(wire, maxInformationBytes: -1),
          throwsRangeError);
    });

    test('information is an immutable byte snapshot', () {
      final info = [1, 2];
      final frame = ui(info);
      info[0] = 9;
      expect(frame.info, [1, 2]);
      expect(() => frame.info[0] = 5, throwsUnsupportedError);
      expect(() => ui([256]), throwsRangeError);
    });
  });
}
