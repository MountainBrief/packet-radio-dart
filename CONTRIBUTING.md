# Contributing

Bug reports, small fixes and compatibility reports are welcome. Include a
minimal synthetic byte sequence, expected behavior and actual behavior. State
the origin and redistribution terms of any external fixture.

For a hardware report, identify the TNC model, firmware/software versions,
transport, input bytes and observed result. Keep captures free of credentials,
private messages and location-linked personal information. Use SECURITY.md for
potential vulnerabilities.

## Checks

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart run example/mb_packet_radio_example.dart
```

Keep core changes independent of Flutter and operating-system or Bluetooth
plugins. Add deterministic wire fixtures for protocol changes. Discuss new
protocol features before expanding the documented subset.

Describe evidence precisely: encoding, transport writes, radio transmission and
remote acceptance are different observations. Offline tests establish software
behavior; hardware compatibility needs a reproducible hardware result.

Contribute only material you are authorized to share under Apache-2.0, retaining
required copyright and third-party notices. Follow the repository license for
contributions; no copyright assignment is required by this contribution guide.
