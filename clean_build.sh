#!/bin/bash
# ============================================================
# KOW-2.0 Complete Clean Build Script (macOS/Linux)
# ============================================================
# This script performs a complete clean build, removing all
# package cache and temporary files. Run this if you see
# "package residue" errors or build corruption issues.
#
# Usage: chmod +x clean_build.sh && ./clean_build.sh
# ============================================================

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║  KOW-2.0 COMPLETE BUILD CLEAN                      ║"
echo "║  Removing all package residue and temporary files  ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found!"
    echo "Please run this script from the KOW-2.0 project root."
    exit 1
fi

echo "[1/6] Removing Flutter build artifacts..."
rm -rf build .dart_tool 2>/dev/null
echo "✓ Flutter artifacts removed"

echo "[2/6] Cleaning Android build cache..."
cd android
rm -rf build .gradle 2>/dev/null
echo "✓ Android build cache cleaned"

echo "[3/6] Cleaning Android app build..."
rm -rf app/build 2>/dev/null
echo "✓ Android app build cleaned"

cd ..

echo "[4/6] Cleaning Pub cache..."
flutter clean
echo "✓ Pub cache cleaned"

echo "[5/6] Getting dependencies..."
flutter pub get
echo "✓ Dependencies retrieved"

echo "[6/6] Running Dart code generation..."
flutter pub run build_runner build --delete-conflicting-outputs
echo "✓ Code generation complete"

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║  BUILD CLEAN COMPLETE                             ║"
echo "║  Ready to build fresh: flutter run --release      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
