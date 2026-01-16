# apt-github-pages

This repository demonstrates building a simple Go `hello` program, packaging it as a `.deb`, and publishing it in an APT repository hosted on GitHub Pages.

Quick start

```bash
# download the signing key (no gpg required - binary format)
sudo curl -fsSL https://k0in.github.io/apt-github-pages/signing-key.gpg -o /usr/share/keyrings/apt-github-pages.gpg

# add the repository (signed)
echo "deb [signed-by=/usr/share/keyrings/apt-github-pages.gpg] https://k0in.github.io/apt-github-pages stable main" | sudo tee /etc/apt/sources.list.d/apt-github-pages.list

# update and install
sudo apt-get update
sudo apt-get install hello-k0in
```

Alternatively, use `[trusted=yes]` to skip signature verification (not recommended for production):

```bash
echo "deb [trusted=yes] https://k0in.github.io/apt-github-pages stable main" | sudo tee /etc/apt/sources.list.d/apt-github-pages.list
```

## Development

Build and generate the APT repo locally with the Makefile

```bash
# build and package .deb for all architectures (amd64, arm64)
make package-all VERSION=0.1.0

# or build for a single architecture
make package ARCH=amd64 VERSION=0.1.0

# generate the APT repo metadata (requires `dpkg-scanpackages` from `dpkg-dev`)
ARCHITECTURES="amd64 arm64" ./scripts/generate-apt-repo.sh public dist/*.deb
```

## Setting up GPG signing in CI

1. Generate a GPG key (no passphrase for CI):

```bash
gpg --batch --gen-key <<EOF
  Key-Type: EDDSA
  Key-Curve: ed25519
  Key-Usage: sign
  Name-Real: APT Repo Signing Key
  Name-Email: thisk0in@gmail.com
  Expire-Date: 0
  %no-protection
  %commit
EOF
```

1. Export the private key and add it as a GitHub secret named `GPG_PRIVATE_KEY`:

```bash
gpg --armor --export-secret-keys thisk0in@gmail.com
```
