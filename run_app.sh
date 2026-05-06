#!/bin/bash

# Create a fake toolchain directory to satisfy Flutter's search for linkers
# specifically when it expects them to be in the same directory as clang.
mkdir -p .fake_toolchain

# Create wrappers for clang and clang++ to prevent Flutter from resolving 
# them back to the LLVM-18 directory (which is missing the linkers).
echo '#!/bin/bash' > .fake_toolchain/clang
echo 'exec /usr/bin/clang "$@"' >> .fake_toolchain/clang
echo '#!/bin/bash' > .fake_toolchain/clang++
echo 'exec /usr/bin/clang++ "$@"' >> .fake_toolchain/clang++
chmod +x .fake_toolchain/clang .fake_toolchain/clang++

# Symlink standard bin tools into the fake toolchain
ln -sf /usr/bin/ld .fake_toolchain/ld
ln -sf /usr/bin/ld .fake_toolchain/ld.lld
ln -sf /usr/bin/ar .fake_toolchain/ar
ln -sf /usr/bin/ar .fake_toolchain/llvm-ar
ln -sf /usr/bin/nm .fake_toolchain/nm
ln -sf /usr/bin/nm .fake_toolchain/llvm-nm
ln -sf /usr/bin/ranlib .fake_toolchain/ranlib
ln -sf /usr/bin/ranlib .fake_toolchain/llvm-ranlib
ln -sf /usr/bin/strip .fake_toolchain/strip
ln -sf /usr/bin/strip .fake_toolchain/llvm-strip

# Set Chrome executable for web development
export CHROME_EXECUTABLE=/snap/bin/chromium

# Add the fake toolchain to PATH
export PATH="$PWD/.fake_toolchain:$PATH"

echo "------------------------------------------------"
echo "🍎 BlissFruitz Multi-App Launcher"
echo "------------------------------------------------"
echo "Choose which app to run:"
echo "1) Customer App (Default)"
echo "2) Rider / Delivery App"
echo "------------------------------------------------"
read -p "Enter choice [1-2]: " choice

case $choice in
    2)
        echo "🚀 Launching Rider App..."
        flutter run --dart-define=APP_FLAVOR=rider "$@"
        ;;
    *)
        echo "🚀 Launching Customer App..."
        flutter run --dart-define=APP_FLAVOR=customer "$@"
        ;;
esac
