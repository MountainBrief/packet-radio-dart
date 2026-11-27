// Copyright 2026 Stijn Vanveerdeghem
// Copyright assigned to Mountain Brief LLC effective 2026-11-26.
// SPDX-License-Identifier: Apache-2.0

/// Portable KISS framing and a strict AX.25 modulo-8 frame-codec subset.
///
/// No transport or radio is opened. See README.md for supported frame types.
library;

export 'src/ax25_address.dart'
    show Ax25Address, Ax25AddressException, DecodedAx25Address;
export 'src/ax25_codec.dart' show Ax25Codec, Ax25CodecException;
export 'src/ax25_frame.dart'
    show
        Ax25Frame,
        Ax25FrameKind,
        Ax25UControl,
        Ax25SControl,
        Ax25Pid,
        Ax25UControlByte;
export 'src/kiss.dart'
    show KissFrame, KissConstants, KissCodec, KissReassembler;
