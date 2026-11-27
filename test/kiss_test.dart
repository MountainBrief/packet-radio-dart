// Copyright 2026 Stijn Vanveerdeghem
// Copyright assigned to Mountain Brief LLC effective 2026-11-26.
// SPDX-License-Identifier: Apache-2.0

import 'dart:math';
import 'dart:typed_data';

import 'package:mb_packet_radio/mb_packet_radio.dart';
import 'package:test/test.dart';

void main() {
  group('KISS wire format', () {
    test('independent escape fixture includes type byte on port 12', () {
      final frame = KissFrame(port: 12, payload: [0x41, 0xc0, 0xdb]);
      const wire = [0xc0, 0xdb, 0xdc, 0x41, 0xdb, 0xdc, 0xdb, 0xdd, 0xc0];
      expect(KissCodec.encode(frame), wire);
      expect(KissReassembler().addChunk(wire), [frame]);
    });

    test('escaped type DB is decoded as port 13 command 11', () {
      final decoded =
          KissReassembler().addChunk([0xc0, 0xdb, 0xdd, 0x42, 0xc0]);
      expect(decoded.single.port, 13);
      expect(decoded.single.command, 11);
      expect(decoded.single.isData, isFalse);
      expect(decoded.single.payload, [0x42]);
      expect(KissCodec.encode(decoded.single), [0xc0, 0xdb, 0xdd, 0x42, 0xc0]);
    });

    test('every split of a literal escaped wire fixture', () {
      const wire = [0xc0, 0x20, 0x41, 0xdb, 0xdc, 0xdb, 0xdd, 0xc0];
      for (var split = 0; split <= wire.length; split++) {
        final decoder = KissReassembler();
        final frames = [
          ...decoder.addChunk(wire.sublist(0, split)),
          ...decoder.addChunk(wire.sublist(split)),
        ];
        expect(
            frames,
            [
              KissFrame(port: 2, payload: [0x41, 0xc0, 0xdb])
            ],
            reason: 'split $split');
        expect(decoder.errors, isEmpty);
      }
    });

    test('idle delimiters, leading garbage, command and shared delimiter', () {
      final frames = KissReassembler().addChunk([
        1,
        2,
        3,
        0xc0,
        0xc0,
        0x00,
        0x41,
        0xc0,
        0x01,
        50,
        0xc0,
        0xc0,
      ]);
      expect(frames, [
        KissFrame(payload: [0x41]),
        KissFrame(command: 1, payload: [50])
      ]);
    });

    test('empty command payload is distinct from an idle delimiter', () {
      expect(KissReassembler().addChunk([0xc0, 0, 0xc0]),
          [KissFrame(payload: [])]);
      expect(KissReassembler().addChunk([0xc0, 0xc0]), isEmpty);
    });

    test('all port/command nibbles and every possible payload byte', () {
      final payload = List.generate(256, (i) => i);
      for (var port = 0; port < 16; port++) {
        for (var command = 0; command < 16; command++) {
          final frame =
              KissFrame(port: port, command: command, payload: payload);
          final decoder = KissReassembler();
          final frames = <KissFrame>[];
          for (final byte in KissCodec.encode(frame)) {
            frames.addAll(decoder.addChunk([byte]));
          }
          expect(frames, [frame], reason: 'port $port command $command');
        }
      }
    });

    test('deterministic random frames survive arbitrary chunk boundaries', () {
      final random = Random(4107);
      final frames = List.generate(
          200,
          (_) => KissFrame(
                port: random.nextInt(16),
                command: random.nextInt(16),
                payload: List.generate(
                    random.nextInt(97), (_) => random.nextInt(256)),
              ));
      final stream = frames.expand(KissCodec.encode).toList();
      final decoder = KissReassembler();
      final actual = <KissFrame>[];
      for (var offset = 0; offset < stream.length;) {
        final end = min(stream.length, offset + 1 + random.nextInt(29));
        actual.addAll(decoder.addChunk(stream.sublist(offset, end)));
        offset = end;
      }
      expect(actual, frames);
      expect(decoder.errorCount, 0);
    });
  });

  group('KISS stream recovery and resource limits', () {
    test('bad escape drops entire corrupt frame and recovers', () {
      final decoder = KissReassembler();
      final frames = decoder.addChunk([
        0xc0,
        0,
        0x41,
        0xdb,
        0,
        0x42,
        0xc0,
        0,
        0x43,
        0xc0,
      ]);
      expect(frames, [
        KissFrame(payload: [0x43])
      ]);
      expect(decoder.errorCount, 1);
    });

    test('FEND after FESC aborts that frame and opens the next', () {
      final decoder = KissReassembler();
      expect(decoder.addChunk([0xc0, 0, 0xdb]), isEmpty);
      expect(decoder.addChunk([0xc0, 0, 0x44, 0xc0]), [
        KissFrame(payload: [0x44])
      ]);
      expect(decoder.errors, ['truncated escape']);
    });

    test('unterminated oversized input stays bounded, then recovers', () {
      final decoder = KissReassembler(maxFrameBytes: 16, maxErrors: 2);
      decoder.addChunk([0xc0, ...List.filled(100000, 0x41)]);
      expect(decoder.pendingByteCount, lessThanOrEqualTo(16));
      expect(decoder.errorCount, 1);
      expect(decoder.addChunk([0xc0, 0, 0x45, 0xc0]), [
        KissFrame(payload: [0x45])
      ]);
    });

    test('limit includes type, but counts escaped values once', () {
      final decoder = KissReassembler(maxFrameBytes: 2);
      expect(decoder.addChunk([0xc0, 0, 0xdb, 0xdc, 0xc0]), [
        KissFrame(payload: [0xc0])
      ]);
      expect(decoder.addChunk([0xc0, 0, 1, 2, 0xc0]), isEmpty);
      expect(decoder.errorCount, 1);
    });

    test('diagnostics stay bounded while lifetime errors are counted', () {
      final decoder = KissReassembler(maxErrors: 2);
      for (var i = 0; i < 50; i++) {
        decoder.addChunk([0xc0, 0, 0xdb, 1, 0xc0]);
      }
      expect(decoder.errorCount, 50);
      expect(decoder.errors, hasLength(2));
      expect(() => decoder.errors.add('foreign'), throwsUnsupportedError);
      final quiet = KissReassembler(maxErrors: 0)..addChunk([0xc0, 0xdb, 0xc0]);
      expect(quiet.errors, isEmpty);
      expect(quiet.errorCount, 1);
    });

    test('reset prevents fragments crossing transport connections', () {
      final decoder = KissReassembler()..addChunk([0xc0, 0, 0x41]);
      decoder.reset();
      expect(decoder.addChunk([0x42, 0xc0]), isEmpty);
      expect(decoder.addChunk([0, 0x43, 0xc0]), [
        KissFrame(payload: [0x43])
      ]);
      expect(decoder.pendingByteCount, 0);
      expect(decoder.errorCount, 0);
    });

    test('invalid integer is rejected before consuming any of the chunk', () {
      final decoder = KissReassembler()..addChunk([0xc0, 0]);
      expect(() => decoder.addChunk([0x41, 256]), throwsRangeError);
      expect(decoder.addChunk([0x42, 0xc0]), [
        KissFrame(payload: [0x42])
      ]);
      expect(() => KissReassembler(maxFrameBytes: 0), throwsRangeError);
      expect(() => KissReassembler(maxErrors: -1), throwsRangeError);
    });
  });

  test('frame bytes are immutable snapshots and nibbles are validated', () {
    final bytes = [1, 2];
    final frame = KissFrame(payload: bytes);
    bytes[0] = 9;
    expect(frame.payload, [1, 2]);
    expect(() => frame.payload[0] = 3, throwsUnsupportedError);
    expect(() => KissFrame(payload: [-1]), throwsRangeError);
    expect(() => KissFrame(payload: [], port: 16), throwsRangeError);
    expect(() => KissFrame(payload: [], command: -1), throwsRangeError);
    expect(frame.hashCode, KissFrame(payload: [1, 2]).hashCode);
  });

  test('ATT chunking reconstructs the exact bytes and validates MTU', () {
    final encoded = Uint8List.fromList(List.generate(45, (i) => i));
    final chunks = KissCodec.chunk(encoded, mtu: 23);
    expect(chunks.map((c) => c.length), [20, 20, 5]);
    expect(chunks.expand((c) => c), encoded);
    expect(KissCodec.chunk(Uint8List(0), mtu: 23), isEmpty);
    expect(() => KissCodec.chunk(encoded, mtu: 3), throwsRangeError);
  });
}
