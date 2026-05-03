@echo off
REM ============================================================
REM KOW-2.0 Complete Clean Build Script (Windows)
REM ============================================================
REM This script performs a complete clean build, removing all
REM package cache and temporary files. Run this if you see
REM "package residue" errors or build corruption issues.
REM
REM Usage: run this script from the project root directory
REM ============================================================

echo.
echo ╔════════════════════════════════════════════════════╗
echo ║  KOW-2.0 COMPLETE BUILD CLEAN                      ║
echo ║  Removing all package residue and temporary files  ║
echo ╚════════════════════════════════════════════════════╝
echo.

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the KOW-2.0 project root.
    pause
    exit /b 1
)

echo [1/6] Removing Flutter build artifacts...
rmdir /s /q build 2>nul
if exist ".dart_tool" rmdir /s /q .dart_tool 2>nul
echo ✓ Flutter artifacts removed

echo [2/6] Cleaning Android build cache...
cd android
if exist "build" rmdir /s /q build 2>nul
if exist ".gradle" rmdir /s /q .gradle 2>nul
echo ✓ Android build cache cleaned

echo [3/6] Cleaning Android app build...
if exist "app\build" rmdir /s /q app\build 2>nul
echo ✓ Android app build cleaned

cd ..

echo [4/6] Cleaning Pub cache...
call flutter clean
echo ✓ Pub cache cleaned

echo [5/6] Getting dependencies...
call flutter pub get
echo ✓ Dependencies retrieved

echo [6/6] Running Dart code generation...
call flutter pub run build_runner build --delete-conflicting-outputs
echo ✓ Code generation complete

echo.
echo ╔════════════════════════════════════════════════════╗
echo ║  BUILD CLEAN COMPLETE                             ║
echo ║  Ready to build fresh: flutter run --release      ║
echo ╚════════════════════════════════════════════════════╝
echo.
pause
