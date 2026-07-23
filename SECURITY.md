# Security policy

## Supported version

Security fixes are applied to the latest tagged release and the `main` branch.

## Report a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do not include reflection text, personal journal exports, credentials, or other private user data in a public issue.

Include the affected Limiter version, macOS version, reproduction steps, expected behavior, and actual behavior. A minimal proof of concept is welcome.

## Security boundaries

Limiter is deliberately unprivileged. It does not install a daemon, system extension, kernel extension, privileged helper, certificate, or network service. It does not request Accessibility, Input Monitoring, Screen Recording, or administrator access.

Limiter is not designed to withstand a user who can quit, modify, or delete the app. Reports that only demonstrate this documented limitation are not security vulnerabilities.

The public side-project release is ad-hoc signed and therefore cannot provide Developer ID publisher identity or notarization. Users should verify the published SHA-256 checksum and may build from source.
