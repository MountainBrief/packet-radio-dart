// Copyright 2026 Stijn Vanveerdeghem
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

import 'ax25_address.dart';
import 'ax25_frame.dart';

class Ax25CodecException implements Exception {
  Ax25CodecException(this.message);
  final String message;
  @override
  String toString() => 'Ax25CodecException: $message';
}

/// Encode/decode AX.25 modulo-8 frames for KISS DATA payloads.
///
/// Does **not** append an HDLC FCS. The TNC/radio boundary owns FCS.
abstract final class Ax25Codec {
  /// Encode the supported no-digipeater profile. Information defaults to 256 bytes.
  static Uint8List encode(Ax25Frame frame, {int maxInformationBytes = 256}) {
    _validateFrame(frame, maxInformationBytes);
    final destC = frame.command;
    final srcC = !frame.command;
    final dest = frame.destination.encode(last: false, commandCBit: destC);
    final src = frame.source.encode(last: true, commandCBit: srcC);
    final out = BytesBuilder(copy: false);
    out.add(dest);
    out.add(src);
    out.addByte(_encodeControl(frame));
    if (frame.kind == Ax25FrameKind.i || frame.uControl == Ax25UControl.ui) {
      out.addByte(frame.pid);
      out.add(frame.info);
    } else if (frame.info.isNotEmpty) {
      out.add(frame.info);
    }
    return out.toBytes();
  }

  static Ax25Frame decode(Uint8List bytes, {int maxInformationBytes = 256}) {
    _validateLimit(maxInformationBytes);
    if (bytes.length < 15) {
      throw Ax25CodecException('truncated frame');
    }
    if (bytes.length > 16 + maxInformationBytes && bytes.length > 18) {
      throw Ax25CodecException('frame exceeds configured information limit');
    }
    final dest = Ax25Address.decode(bytes, offset: 0);
    if (dest.last) {
      throw Ax25CodecException('destination address-extension bit marks last');
    }
    final src = Ax25Address.decode(bytes, offset: 7);
    if (!src.last) {
      throw Ax25CodecException(
        'source address-extension bit not last (digipeaters unsupported)',
      );
    }
    if (dest.commandCBit == src.commandCBit) {
      throw Ax25CodecException('inconsistent command/response C-bits');
    }
    final command = dest.commandCBit && !src.commandCBit;
    final control = bytes[14];
    final rest = bytes.sublist(15);

    if ((control & 0x01) == 0) {
      if (rest.isEmpty) {
        throw Ax25CodecException('I frame missing PID');
      }
      _validateInfoLength(rest.length - 1, maxInformationBytes);
      return Ax25Frame.i(
        destination: dest.address,
        source: src.address,
        command: command,
        ns: (control >> 1) & 0x07,
        nr: (control >> 5) & 0x07,
        pollFinal: (control & 0x10) != 0,
        pid: rest[0],
        info: Uint8List.fromList(rest.sublist(1)),
      );
    }

    if ((control & 0x02) == 0) {
      if (rest.isNotEmpty) {
        throw Ax25CodecException('S frame has trailing information');
      }
      return Ax25Frame.s(
        destination: dest.address,
        source: src.address,
        command: command,
        control: _decodeS(control),
        nr: (control >> 5) & 0x07,
        pollFinal: (control & 0x10) != 0,
      );
    }

    final pf = (control & 0x10) != 0;
    final masked = control & 0xef;
    final uControl = _decodeU(masked);
    if (uControl == Ax25UControl.ui) {
      if (rest.isEmpty) {
        throw Ax25CodecException('UI frame missing PID');
      }
      _validateInfoLength(rest.length - 1, maxInformationBytes);
      return Ax25Frame(
        destination: dest.address,
        source: src.address,
        command: command,
        kind: Ax25FrameKind.u,
        uControl: uControl,
        pollFinal: pf,
        pid: rest[0],
        info: Uint8List.fromList(rest.sublist(1)),
      );
    }
    _validateU(uControl, command, rest.length);
    return Ax25Frame.u(
      destination: dest.address,
      source: src.address,
      command: command,
      control: uControl,
      pollFinal: pf,
      info: rest.isEmpty ? null : Uint8List.fromList(rest),
    );
  }

  static Ax25Frame? tryDecode(Uint8List bytes,
      {int maxInformationBytes = 256}) {
    try {
      return decode(bytes, maxInformationBytes: maxInformationBytes);
    } on Ax25CodecException {
      return null;
    } on Ax25AddressException {
      return null;
    }
  }

  static void _validateLimit(int limit) {
    if (limit < 0) throw RangeError.value(limit, 'maxInformationBytes');
  }

  static void _validateInfoLength(int length, int limit) {
    if (length > limit) {
      throw Ax25CodecException('information exceeds $limit bytes');
    }
  }

  static void _validateFrame(Ax25Frame frame, int limit) {
    _validateLimit(limit);
    if (frame.kind != Ax25FrameKind.u && frame.uControl != null ||
        frame.kind != Ax25FrameKind.s && frame.sControl != null) {
      throw Ax25CodecException('control does not match frame kind');
    }
    switch (frame.kind) {
      case Ax25FrameKind.i:
        _validateInfoLength(frame.info.length, limit);
      case Ax25FrameKind.s:
        if (frame.ns != 0 || frame.info.isNotEmpty) {
          throw Ax25CodecException('S frame has unused sequence/information');
        }
      case Ax25FrameKind.u:
        if (frame.ns != 0 || frame.nr != 0) {
          throw Ax25CodecException('U frame has unused sequence number');
        }
        if (frame.uControl == Ax25UControl.ui) {
          _validateInfoLength(frame.info.length, limit);
        } else if (frame.uControl != null) {
          _validateU(frame.uControl!, frame.command, frame.info.length);
        }
    }
  }

  static void _validateU(Ax25UControl control, bool command, int infoLength) {
    final isCommand =
        control == Ax25UControl.sabm || control == Ax25UControl.disc;
    if (control != Ax25UControl.unknown && isCommand != command) {
      throw Ax25CodecException('U frame command/response mismatch');
    }
    final expected = control == Ax25UControl.frmr ? 3 : 0;
    if (infoLength != expected) {
      throw Ax25CodecException('U frame requires $expected information bytes');
    }
  }

  static int _encodeControl(Ax25Frame frame) {
    switch (frame.kind) {
      case Ax25FrameKind.i:
        return ((frame.nr & 0x07) << 5) |
            ((frame.pollFinal ? 1 : 0) << 4) |
            ((frame.ns & 0x07) << 1);
      case Ax25FrameKind.s:
        final ss = switch (frame.sControl) {
          Ax25SControl.rr => 0x01,
          Ax25SControl.rnr => 0x05,
          Ax25SControl.rej => 0x09,
          null => throw Ax25CodecException('S frame missing control'),
        };
        return ((frame.nr & 0x07) << 5) | ((frame.pollFinal ? 1 : 0) << 4) | ss;
      case Ax25FrameKind.u:
        final base = switch (frame.uControl) {
          Ax25UControl.sabm => Ax25UControlByte.sabm,
          Ax25UControl.ua => Ax25UControlByte.ua,
          Ax25UControl.disc => Ax25UControlByte.disc,
          Ax25UControl.dm => Ax25UControlByte.dm,
          Ax25UControl.frmr => Ax25UControlByte.frmr,
          Ax25UControl.ui => Ax25UControlByte.ui,
          Ax25UControl.unknown => throw Ax25CodecException(
              'cannot encode unknown U control',
            ),
          null => throw Ax25CodecException('U frame missing control'),
        };
        return base | ((frame.pollFinal ? 1 : 0) << 4);
    }
  }

  static Ax25SControl _decodeS(int control) {
    switch (control & 0x0f) {
      case 0x01:
        return Ax25SControl.rr;
      case 0x05:
        return Ax25SControl.rnr;
      case 0x09:
        return Ax25SControl.rej;
      default:
        throw Ax25CodecException(
          'unsupported S control ${control.toRadixString(16)}',
        );
    }
  }

  static Ax25UControl _decodeU(int masked) {
    switch (masked) {
      case Ax25UControlByte.sabm:
        return Ax25UControl.sabm;
      case Ax25UControlByte.ua:
        return Ax25UControl.ua;
      case Ax25UControlByte.disc:
        return Ax25UControl.disc;
      case Ax25UControlByte.dm:
        return Ax25UControl.dm;
      case Ax25UControlByte.frmr:
        return Ax25UControl.frmr;
      case Ax25UControlByte.ui:
        return Ax25UControl.ui;
      default:
        throw Ax25CodecException(
            'unsupported U control ${masked.toRadixString(16)}');
    }
  }
}
