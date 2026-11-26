# Security

Treat transport bytes as untrusted input. KISS framing has no authentication or
integrity checksum. The codecs do not establish sender identity or delivery.

Report a resource-exhaustion or parsing issue privately to the repository
maintainers using an existing authorized contact channel. If GitHub private
vulnerability reporting is enabled for the public project, use that facility.
Include a minimal synthetic byte sequence and observed behavior. Avoid posting
secrets or unredacted operational traffic in public issues.

The development preview has offline software validation only. No claim of radio
interoperability, safety certification or a complete independent audit is made.
