// Copyright 2026 Stijn Vanveerdeghem
// SPDX-License-Identifier: Apache-2.0

import 'dart:typed_data';

class Ax25AddressException implements Exception {
  Ax25AddressException(this.message);
  final String message;
  @override
  String toString() => 'Ax25AddressException: $message';
}

/// AX.25 destination/source callsign and SSID. No digipeater path.
class Ax25Address {
  Ax25Address(String callsign, [int ssid = 0])
      : callsign = normalizeCallsign(callsign),
        ssid = _validateSsid(ssid);

  final String callsign;
  final int ssid;

  /// Parses `CALL` or `CALL-SSID`. Callsign is uppercased.
  factory Ax25Address.parse(String spec) {
    final trimmed = spec.trim();
    if (trimmed.isEmpty) {
      throw Ax25AddressException('empty callsign');
    }
    final match =
        RegExp(r'^([A-Za-z0-9]{1,6})(?:-([0-9]{1,2}))?$').firstMatch(trimmed);
    if (match == null) {
      throw Ax25AddressException('invalid callsign/SSID');
    }
    return Ax25Address(match[1]!, int.parse(match[2] ?? '0'));
  }

  static String normalizeCallsign(String raw) {
    final call = raw.trim().toUpperCase();
    if (call.isEmpty) {
      throw Ax25AddressException('empty callsign');
    }
    if (call.length > 6) {
      throw Ax25AddressException('callsign longer than 6 characters');
    }
    for (var i = 0; i < call.length; i++) {
      final c = call.codeUnitAt(i);
      final ok = (c >= 0x41 && c <= 0x5a) || (c >= 0x30 && c <= 0x39);
      if (!ok) {
        throw Ax25AddressException('invalid callsign character');
      }
    }
    return call;
  }

  static int _validateSsid(int ssid) {
    if (ssid < 0 || ssid > 15) {
      throw Ax25AddressException('SSID out of range 0..15');
    }
    return ssid;
  }

  String get paddedCallsign => callsign.padRight(6, ' ');

  /// 7-byte shifted AX.25 address. Reserved bits are set (0x60).
  /// [commandCBit] is the HDLC C-bit (bit 7). [last] is the E-bit (bit 0).
  Uint8List encode({required bool last, required bool commandCBit}) {
    final out = Uint8List(7);
    final padded = paddedCallsign;
    for (var i = 0; i < 6; i++) {
      out[i] = (padded.codeUnitAt(i) << 1) & 0xfe;
    }
    out[6] = (commandCBit ? 0x80 : 0x00) |
        0x60 |
        ((ssid & 0x0f) << 1) |
        (last ? 0x01 : 0x00);
    return out;
  }

  static DecodedAx25Address decode(List<int> bytes, {required int offset}) {
    if (offset < 0 || offset + 7 > bytes.length) {
      throw Ax25AddressException('truncated address');
    }
    for (var i = offset; i < offset + 7; i++) {
      if (bytes[i] < 0 || bytes[i] > 255) {
        throw Ax25AddressException('address value outside byte range');
      }
    }
    final chars = StringBuffer();
    for (var i = 0; i < 6; i++) {
      final raw = bytes[offset + i];
      if ((raw & 0x01) != 0) {
        throw Ax25AddressException(
          'address-extension bit set in callsign byte',
        );
      }
      final c = raw >> 1;
      if (c != 0x20 &&
          !((c >= 0x41 && c <= 0x5a) || (c >= 0x30 && c <= 0x39))) {
        throw Ax25AddressException('invalid encoded callsign character');
      }
      chars.writeCharCode(c);
    }
    final call = chars.toString().trimRight();
    if (call.isEmpty || call.contains(' ')) {
      throw Ax25AddressException('embedded space in callsign');
    }
    final ssidByte = bytes[offset + 6];
    if ((ssidByte & 0x60) != 0x60) {
      throw Ax25AddressException('reserved address bits not set');
    }
    final address = Ax25Address(call, (ssidByte >> 1) & 0x0f);
    return DecodedAx25Address(
      address: address,
      commandCBit: (ssidByte & 0x80) != 0,
      last: (ssidByte & 0x01) != 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Ax25Address && other.callsign == callsign && other.ssid == ssid;

  @override
  int get hashCode => Object.hash(callsign, ssid);

  @override
  String toString() => ssid == 0 ? callsign : '$callsign-$ssid';
}

class DecodedAx25Address {
  const DecodedAx25Address({
    required this.address,
    required this.commandCBit,
    required this.last,
  });

  final Ax25Address address;
  final bool commandCBit;
  final bool last;
}
