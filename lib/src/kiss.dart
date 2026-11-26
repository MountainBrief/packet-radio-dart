// Copyright 2026 Stijn Vanveerdeghem
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

/// A decoded KISS frame. Payload bytes are copied and read-only.
class KissFrame {
  KissFrame({required List<int> payload, int port = 0, int command = 0})
      : port = RangeError.checkValueInInterval(port, 0, 15, 'port'),
        command = RangeError.checkValueInInterval(command, 0, 15, 'command'),
        payload = _copyBytes(payload).asUnmodifiableView();

  final int port;
  final int command;
  final Uint8List payload;

  bool get isData => command == 0;
  int get typeByte => (port << 4) | command;

  @override
  bool operator ==(Object other) {
    if (other is! KissFrame ||
        port != other.port ||
        command != other.command ||
        payload.length != other.payload.length) {
      return false;
    }
    for (var i = 0; i < payload.length; i++) {
      if (payload[i] != other.payload[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(port, command, Object.hashAll(payload));
}

abstract final class KissConstants {
  static const int fend = 0xc0;
  static const int fesc = 0xdb;
  static const int tfend = 0xdc;
  static const int tfesc = 0xdd;
  static const int attHeaderBytes = 3;
  static const int defaultAttMtu = 23;
}

/// Byte framing only. No socket, Bluetooth, TNC or radio is opened.
abstract final class KissCodec {
  static Uint8List encode(KissFrame frame) {
    final out = BytesBuilder(copy: false)..addByte(KissConstants.fend);
    // The type byte is part of the escaped body, including on ports 12/13.
    _appendEscaped(out, frame.typeByte);
    for (final byte in frame.payload) {
      _appendEscaped(out, byte);
    }
    out.addByte(KissConstants.fend);
    return out.takeBytes();
  }

  static void _appendEscaped(BytesBuilder out, int byte) {
    if (byte == KissConstants.fend) {
      out.add(const [KissConstants.fesc, KissConstants.tfend]);
    } else if (byte == KissConstants.fesc) {
      out.add(const [KissConstants.fesc, KissConstants.tfesc]);
    } else {
      out.addByte(byte);
    }
  }

  /// Space for a value after a three-byte ATT header. No BLE API is used.
  static int attPayloadBytes({required int mtu}) {
    if (mtu <= KissConstants.attHeaderBytes) {
      throw RangeError.value(mtu, 'mtu', 'must be greater than 3');
    }
    return mtu - KissConstants.attHeaderBytes;
  }

  /// Split encoded bytes into value-sized chunks for an ATT MTU.
  static List<Uint8List> chunk(Uint8List encoded, {required int mtu}) {
    final size = attPayloadBytes(mtu: mtu);
    return [
      for (var i = 0; i < encoded.length; i += size)
        Uint8List.fromList(encoded.sublist(
          i,
          i + size < encoded.length ? i + size : encoded.length,
        )),
    ];
  }
}

/// Incremental, bounded KISS decoder for arbitrary transport fragments.
///
/// Ignores bytes before the first FEND. Consecutive FENDs are idle, and one
/// delimiter may end a frame and start the next. Malformed or oversized frames
/// are dropped in full until the next FEND. This strict error policy deliberately
/// differs from receivers that continue assembling after a bad escape.
///
/// [maxFrameBytes] counts the unescaped type byte plus payload, not delimiters.
/// At most that many pending bytes and [maxErrors] diagnostic strings are kept.
/// Returned complete frames are owned by the caller and are not retained here.
class KissReassembler {
  KissReassembler({this.maxFrameBytes = 4096, this.maxErrors = 32}) {
    if (maxFrameBytes < 1) {
      throw RangeError.value(maxFrameBytes, 'maxFrameBytes');
    }
    if (maxErrors < 0) {
      throw RangeError.value(maxErrors, 'maxErrors');
    }
  }

  final int maxFrameBytes;
  final int maxErrors;
  final List<int> _body = [];
  final List<String> _errors = [];
  bool _started = false;
  bool _escaped = false;
  bool _discarding = false;
  int _errorCount = 0;

  List<String> get errors => List.unmodifiable(_errors);
  int get errorCount => _errorCount;
  int get pendingByteCount => _body.length;

  List<KissFrame> addChunk(List<int> chunk) {
    // Validate before changing state so invalid integers cannot corrupt a stream.
    for (final byte in chunk) {
      RangeError.checkValueInInterval(byte, 0, 255, 'byte');
    }
    final frames = <KissFrame>[];
    for (final byte in chunk) {
      if (byte == KissConstants.fend) {
        if (_started && !_discarding) {
          if (_escaped) {
            _recordError('truncated escape');
          } else if (_body.isNotEmpty) {
            final type = _body.first;
            frames.add(KissFrame(
              port: type >> 4,
              command: type & 0x0f,
              payload: _body.sublist(1),
            ));
          }
        }
        _body.clear();
        _started = true;
        _escaped = false;
        _discarding = false;
        continue;
      }
      if (!_started || _discarding) continue;
      if (_escaped) {
        _escaped = false;
        if (byte == KissConstants.tfend) {
          _append(KissConstants.fend);
        } else if (byte == KissConstants.tfesc) {
          _append(KissConstants.fesc);
        } else {
          _drop('malformed escape 0x${byte.toRadixString(16)}');
        }
      } else if (byte == KissConstants.fesc) {
        _escaped = true;
      } else {
        _append(byte);
      }
    }
    return frames;
  }

  /// Reset on a transport disconnect so fragments cannot cross connections.
  /// Also clears diagnostics and the lifetime error counter.
  void reset() {
    _body.clear();
    _errors.clear();
    _started = false;
    _escaped = false;
    _discarding = false;
    _errorCount = 0;
  }

  void _append(int byte) {
    if (_body.length == maxFrameBytes) {
      _drop('frame exceeds $maxFrameBytes decoded bytes');
    } else {
      _body.add(byte);
    }
  }

  void _drop(String message) {
    _recordError(message);
    _body.clear();
    _escaped = false;
    _discarding = true;
  }

  void _recordError(String message) {
    _errorCount++;
    if (maxErrors == 0) return;
    if (_errors.length == maxErrors) _errors.removeAt(0);
    _errors.add(message);
  }
}

Uint8List _copyBytes(List<int> bytes) {
  for (final byte in bytes) {
    RangeError.checkValueInInterval(byte, 0, 255, 'payload byte');
  }
  return Uint8List.fromList(bytes);
}
