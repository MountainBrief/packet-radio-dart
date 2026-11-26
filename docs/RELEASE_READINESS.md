# Initial release readiness

Version: 0.1.0-dev.1. This is a private preparation checkpoint, not a public
release, Foundation copyright assignment or live-radio qualification.

## Implemented

- Standalone Dart SDK core with no runtime package dependencies.
- KISS framing, bounded stream reassembly and ATT-sized chunk helper.
- Strict AX.25 modulo-8 address/frame codec subset.
- Offline runnable example and independent malformed/fragmented wire tests.
- Source provenance, notices, candidate Apache-2.0 license and contribution docs.
- Read-only-permission CI workflow with Actions pinned to retrieved commit SHAs.
- Automatic pub.dev publication disabled with `publish_to: none`.

## Before public release

- Confirm the source owner's authority to publish the selected files and grant
  Apache-2.0 rights, including any applicable employment/contractor/patent rights.
  Git author metadata records attribution, not a legal ownership determination.
- Confirm the Foundation's preferred stewardship/repository identity. Do not
  imply a copyright transfer without a separate written decision.
- Review the package API, documented limits, notices and exact candidate commit.
- Record clean analysis, tests and example execution for the reviewed source.
- Confirm CI on the declared minimum SDK and stable Dart; a configured job is
  not evidence that it ran successfully.
- Make the reviewed standalone repository public only when publication is
  authorized. Separately decide whether to publish on pub.dev and select the
  final version; do not remove `publish_to: none` as part of routine testing.

## Follow-on work

- A receive-only adapter example for a real TNC byte stream.
- External TNC compatibility reports and privately sanitized capture fixtures.
- Split the connected-session abstract frame link from Flutter before offering
  connected mode. Review timing and recovery limitations separately.
- Consider optional digipeater-path support based on outside use cases.
- Adopt selected hardened changes back into MB through its normal source review,
  development acceptance and production process. This extraction changes no MB
  application, firmware or deployed runtime.
