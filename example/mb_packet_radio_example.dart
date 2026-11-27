// Copyright 2026 Stijn Vanveerdeghem
// Copyright assigned to Mountain Brief LLC effective 2026-11-26.
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';

import 'package:mb_packet_radio/mb_packet_radio.dart';

void main() {
  // Synthetic packet. The entire example runs offline.
  final packet = Ax25Frame.u(
    destination: Ax25Address('APRS'),
    source: Ax25Address('N0CALL', 1),
    command: true,
    control: Ax25UControl.ui,
    info: utf8.encode('Hello from the packet radio toolkit'),
  );
  final encoded =
      KissCodec.encode(KissFrame(payload: Ax25Codec.encode(packet)));
  final decoder = KissReassembler();
  final received = <KissFrame>[];
  for (final fragment in KissCodec.chunk(encoded, mtu: 23)) {
    received.addAll(decoder.addChunk(fragment));
  }
  final decoded = Ax25Codec.decode(received.single.payload);
  print(
      '${decoded.source} -> ${decoded.destination}: ${utf8.decode(decoded.info)}');
  print('${encoded.length} KISS bytes, ${decoder.errorCount} decode errors');
}
