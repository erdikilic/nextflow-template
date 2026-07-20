# Security Policy

## Reporting a vulnerability

Please report security issues privately via GitHub's **"Report a vulnerability"**
(Security → Advisories) on this repository, or by contacting the maintainer
directly. Do **not** open a public issue for security problems.

We aim to acknowledge reports within a few working days.

## Secrets

This repository runs [gitleaks](https://github.com/gitleaks/gitleaks) via
pre-commit and CI to prevent credentials from being committed. Never commit
tokens, passwords, or credential-bearing URLs. If a secret is committed, rotate
it immediately — rewriting history does not un-leak an exposed secret.
