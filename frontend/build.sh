#!/bin/bash
# Clone Flutter SDK if not present
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Enable Web and Build
flutter config --enable-web
flutter build web --release --dart-define=BASE_URL=https://gtoconnect.vercel.app
