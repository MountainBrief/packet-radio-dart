# Validation

## Continuous integration

CI checks Dart **3.4.4** and **stable** on Linux. Each job resolves development
dependencies, verifies formatting, runs static analysis and all tests, and
executes the offline example. The package has no runtime dependencies outside
the Dart SDK.

The initial 0.1.0 candidate `c0ec5d1fccbd18ae8f9ceaf08eacb73f21f06e0d`
passed the matrix with **45 tests** in
[GitHub Actions](https://github.com/MountainBrief/packet-radio-dart/actions/runs/45895985275).
The latest workflow results are available in the repository's Actions tab.

## Test coverage

- Hand-authored AX.25 wire bytes, including I/UI PID placement, control bits,
  command/response addresses and supported U/S frame shapes.
- Every KISS port/command field combination and all 256 payload byte values.
- Escaped type bytes, every split of an escaped fixture, coalesced frames and
  deterministic randomized fragmentation.
- Invalid/truncated escapes, oversized incomplete input, bounded diagnostics,
  connection resets and recovery at the next delimiter.
- Invalid sequence/PID/address/information inputs and immutable payloads.

## Separate consumer project

An independent project using a path dependency was checked on Dart **3.11.5**
on macOS ARM64. Dependency resolution, analysis and the offline example passed.
The example also compiled to JavaScript. That compilation check is distinct from
execution in a browser.

The example produces:

```text
N0CALL-1 -> APRS: Hello from the packet radio toolkit
54 KISS bytes, 0 decode errors
```

## Hardware scope

These results validate software behavior. This release has no live-TNC or RF
interoperability qualification. Compatibility reports with identified hardware,
software versions and minimal wire fixtures are welcome.
