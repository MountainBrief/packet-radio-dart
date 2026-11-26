# Initial release readiness

Version 0.1.0 is prepared as a developer preview in a private repository.
The proposed public release is described in [releases/0.1.0.md](releases/0.1.0.md).

## Technical review

- The four extracted codecs are attributed to Stijn Vanveerdeghem; the source
  paths, original blobs and extraction changes are recorded in PROVENANCE.md.
- The initial candidate `61a93a0cdcffa189aab26dead13d477925e78cd1` passed all
  45 tests, formatting, analysis and the offline example on Dart 3.4.4 and stable
  in [GitHub Actions](https://github.com/MountainBrief/packet-radio-dart/actions/runs/45895043754).
- Release preparation changes package metadata and documentation only. The
  codec and test source remains identical to that validated baseline.
- The release pull request runs those checks again for the exact prepared source.
- A separate consumer-project check verifies installation by a path dependency,
  execution of the offline example, and compilation to JavaScript. Its result
  is recorded in the release pull request.
- This package includes no original repository history, operational secrets,
  runtime data, ESP32/APRS firmware or GPL firmware libraries.

## Publication decision

The remaining decision is to make the standalone repository public and publish
the v0.1.0 GitHub release under Apache-2.0. No public release or outreach has
been performed as part of preparation. Pub.dev publication remains disabled
with `publish_to: none` and is outside this first GitHub release.

The source-owner publication decision must cover the selected files and
license grant. Git authorship records attribution, rather than a separate legal
ownership determination. Copyright attribution remains unchanged; Foundation
stewardship does not create an assignment of copyright.

## Follow-on work

- Invite outside developers to run the example and contribute minimal fixtures
  or TNC compatibility reports.
- Add a receive-only adapter example in response to actual community use cases.
- Split the connected-session abstract frame link from Flutter before offering
  connected mode, with a separate review of timing and recovery limitations.
- Consider digipeater paths based on outside demand.
- Adopt selected hardening changes back into MB through its normal source
  review and development acceptance. This extraction changes no deployed MB
  application or firmware.
