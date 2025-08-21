# Example configuration for building Tailwind CSS from source
# This is useful for platforms where pre-built binaries are not available
# such as FreeBSD ARM64, OpenBSD, NetBSD, or custom architectures

import Config

# Enable building from source instead of downloading pre-built binaries
config :tailwind,
  version: "4.1.12",
  build_from_source: true,  # This enables source building
  default: [
    args: ~w(
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Alternative: Use pre-built binaries (default behavior)
# config :tailwind,
#   version: "4.1.12",
#   # build_from_source defaults to false
#   default: [
#     args: ~w(
#       --input=css/app.css
#       --output=../priv/static/assets/app.css
#     ),
#     cd: Path.expand("../assets", __DIR__)
#   ]

# Requirements for source building:
# 1. Rust and Cargo must be installed
# 2. Git must be available for cloning source
# 3. Sufficient disk space for building
# 4. Internet connection for cloning source

# To install Rust:
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#   source ~/.cargo/env

# To install Git:
#   # On FreeBSD: pkg install git
#   # On OpenBSD: pkg_add git
#   # On NetBSD: pkgin install git
#   # On macOS: brew install git
#   # On Linux: apt-get install git or yum install git
