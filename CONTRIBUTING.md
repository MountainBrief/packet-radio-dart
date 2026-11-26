# Contributing

Keep changes small enough to review alongside a concrete protocol behavior.
Include a failing byte fixture or a reproducible test for a bug report, and state
the source of any external fixture. Do not include private traffic, credentials,
callsigns tied to private locations, resident data or unredacted radio-email logs.

Run the development commands in README.md. Prefer deterministic offline tests
for codecs. Transport integrations should live behind separate adapters so the
core remains independent of Flutter, Bluetooth plugins and operating systems.

Do not describe encoding success, a transport write or a unit test as proof of
radio transmission, remote acceptance or delivery. Any hardware test report
should identify the TNC, software version, setup, input bytes and observed result.

Changes here do not automatically change Mountain Brief's application. Coordinate
any future adoption through its normal integration and release process.

The initial public API supports a documented subset. Discuss new protocol
features before broadening it. Contributions must be work you are authorized to
share under the project's chosen release license, retaining required notices.
