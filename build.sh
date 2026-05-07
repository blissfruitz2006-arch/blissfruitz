#!/bin/bash

# --- COLORS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}      BlissFruitz Build System v2.0          ${NC}"
echo -e "${BLUE}==============================================${NC}"

# --- TOOLCHAIN FIX (LLVM Linker Error) ---
# This fixes: "Failed to find any of [ld.lld, ld]"
mkdir -p .fake_toolchain
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
export PATH="$PWD/.fake_toolchain:$PATH"

# --- ARGUMENT HANDLING ---
PLATFORM=$1
FLAVOR=$2

if [ -z "$PLATFORM" ] || [ -z "$FLAVOR" ]; then
    echo -e "${YELLOW}No arguments provided. Switching to INTERACTIVE MODE...${NC}"
    echo "Select Platform:"
    echo "1) Android APK"
    echo "2) Android App Bundle (AAB)"
    echo "3) Linux Desktop"
    echo "4) Web"
    echo "5) Clean Only"
    read -p "Choice [1-5]: " p_choice

    case $p_choice in
        1) PLATFORM="apk";;
        2) PLATFORM="appbundle";;
        3) PLATFORM="linux";;
        4) PLATFORM="web";;
        5) flutter clean; echo -e "${GREEN}Project cleaned.${NC}"; exit 0;;
        *) echo -e "${RED}Invalid choice.${NC}"; exit 1;;
    esac

    echo -e "\nSelect App Version (Flavor):"
    echo "1) Customer App"
    echo "2) Rider App"
    read -p "Choice [1-2]: " f_choice

    case $f_choice in
        1) FLAVOR="customer";;
        2) FLAVOR="rider";;
        *) echo -e "${RED}Invalid choice.${NC}"; exit 1;;
    esac
fi

# --- CLEAN OPTION ---
read -p "Do you want to run 'flutter clean' first? (y/n): " do_clean
if [ "$do_clean" == "y" ]; then
    echo -e "${YELLOW}Cleaning project...${NC}"
    flutter clean
    flutter pub get
fi

# --- BUILD LOGIC ---
echo -e "\n${BLUE}🚀 Starting Build:${NC}"
echo -e "${BLUE}   Platform:${NC} $PLATFORM"
echo -e "${BLUE}   Flavor:  ${NC} $FLAVOR"
echo -e "${BLUE}==============================================${NC}"

if [ "$PLATFORM" == "apk" ]; then
    # Optimized APK build (Split per ABI reduces size by ~60% per file)
    flutter build apk --release --flavor $FLAVOR --dart-define=APP_FLAVOR=$FLAVOR \
        --split-per-abi
elif [ "$PLATFORM" == "appbundle" ]; then
    # App Bundle is naturally optimized by Google Play
    flutter build appbundle --release --flavor $FLAVOR --dart-define=APP_FLAVOR=$FLAVOR
elif [ "$PLATFORM" == "linux" ]; then
    # Linux supports obfuscation
    flutter build linux --release --dart-define=APP_FLAVOR=$FLAVOR \
        --obfuscate --split-debug-info=build/app/outputs/symbols
else
    # Web does not support --obfuscate (minified by default)
    # The --web-renderer flag has been deprecated in recent Flutter versions.
    # Wasm/CanvasKit is now the default.
    flutter build web --release --dart-define=APP_FLAVOR=$FLAVOR
fi

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Build SUCCESSFUL!${NC}"
    case $PLATFORM in
        apk) echo -e "Output: build/app/outputs/flutter-apk/app-${FLAVOR}-release.apk";;
        appbundle) echo -e "Output: build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab";;
        linux) echo -e "Output: build/linux/x64/release/bundle/";;
        web) echo -e "Output: build/web/";;
    esac
else
    echo -e "\n${RED}❌ Build FAILED! Check the errors above.${NC}"
    exit 1
fi
