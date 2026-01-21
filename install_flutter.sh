#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git -b stable

# Make flutter executable globally inside this build
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
flutter doctor