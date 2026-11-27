// Copyright 2026 Stijn Vanveerdeghem
// Copyright assigned to Mountain Brief LLC effective 2026-11-26.
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

import 'ax25_address.dart';

enum Ax25FrameKind { u, s, i }

enum Ax25UControl { sabm, ua, disc, dm, frmr, ui, unknown }

enum Ax25SControl { rr, rnr, rej }

/// AX.25 modulo-8 frame, without HDLC FCS. Information is copied and read-only.
class Ax25Frame {
  Ax25Frame({
    required this.destination,
    required this.source,
    required this.command,
    required this.kind,
    this.uControl,
    this.sControl,
    int ns = 0,
    int nr = 0,
    this.pollFinal = false,
    int pid = Ax25Pid.noLayer3,
    List<int>? info,
  })  : ns = RangeError.checkValueInInterval(ns, 0, 7, 'ns'),
        nr = RangeError.checkValueInInterval(nr, 0, 7, 'nr'),
        pid = RangeError.checkValueInInterval(pid, 0, 255, 'pid'),
        info = _copyInfo(info ?? const []).asUnmodifiableView();

  factory Ax25Frame.u({
    required Ax25Address destination,
    required Ax25Address source,
    required bool command,
    required Ax25UControl control,
    bool pollFinal = false,
    List<int>? info,
    int pid = Ax25Pid.noLayer3,
  }) {
    return Ax25Frame(
      destination: destination,
      source: source,
      command: command,
      kind: Ax25FrameKind.u,
      uControl: control,
      pollFinal: pollFinal,
      info: info,
      pid: pid,
    );
  }

  factory Ax25Frame.s({
    required Ax25Address destination,
    required Ax25Address source,
    required bool command,
    required Ax25SControl control,
    required int nr,
    bool pollFinal = false,
  }) {
    return Ax25Frame(
      destination: destination,
      source: source,
      command: command,
      kind: Ax25FrameKind.s,
      sControl: control,
      nr: nr,
      pollFinal: pollFinal,
    );
  }

  factory Ax25Frame.i({
    required Ax25Address destination,
    required Ax25Address source,
    required int ns,
    required int nr,
    List<int>? info,
    bool command = true,
    bool pollFinal = false,
    int pid = Ax25Pid.noLayer3,
  }) {
    return Ax25Frame(
      destination: destination,
      source: source,
      command: command,
      kind: Ax25FrameKind.i,
      ns: ns,
      nr: nr,
      pollFinal: pollFinal,
      pid: pid,
      info: info,
    );
  }

  final Ax25Address destination;
  final Ax25Address source;
  final bool command;
  final Ax25FrameKind kind;
  final Ax25UControl? uControl;
  final Ax25SControl? sControl;
  final int ns;
  final int nr;
  final bool pollFinal;
  final int pid;
  final Uint8List info;

  bool get isSabm => kind == Ax25FrameKind.u && uControl == Ax25UControl.sabm;
  bool get isUa => kind == Ax25FrameKind.u && uControl == Ax25UControl.ua;
  bool get isDisc => kind == Ax25FrameKind.u && uControl == Ax25UControl.disc;
  bool get isDm => kind == Ax25FrameKind.u && uControl == Ax25UControl.dm;
  bool get isFrmr => kind == Ax25FrameKind.u && uControl == Ax25UControl.frmr;
  bool get isRr => kind == Ax25FrameKind.s && sControl == Ax25SControl.rr;
  bool get isRnr => kind == Ax25FrameKind.s && sControl == Ax25SControl.rnr;
  bool get isRej => kind == Ax25FrameKind.s && sControl == Ax25SControl.rej;
  bool get isI => kind == Ax25FrameKind.i;
}

abstract final class Ax25Pid {
  /// No layer 3 protocol (ordinary AX.25 connected byte-stream).
  static const int noLayer3 = 0xf0;
}

abstract final class Ax25UControlByte {
  static const int sabm = 0x2f;
  static const int ua = 0x63;
  static const int disc = 0x43;
  static const int dm = 0x0f;
  static const int frmr = 0x87;
  static const int ui = 0x03;
}

Uint8List _copyInfo(List<int> bytes) {
  for (final byte in bytes) {
    RangeError.checkValueInInterval(byte, 0, 255, 'information byte');
  }
  return Uint8List.fromList(bytes);
}
