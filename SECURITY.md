# Security

Treat transport bytes as untrusted. KISS framing supplies no authentication or
integrity checksum. AX.25 frame decoding does not establish sender identity or
successful delivery.

For a potential vulnerability, use GitHub private vulnerability reporting when
available. Otherwise, open an issue requesting a private reporting channel
without including the exploit or sensitive data. Supply a minimal synthetic
reproducer through the private channel.

The preview has offline software validation. Pending frame storage and retained
diagnostics have configurable limits. Completed frames returned to a caller
must be managed by that caller. See README.md and docs/VALIDATION.md for the
supported profile and tested behavior.
