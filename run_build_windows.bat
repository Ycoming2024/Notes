@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT_DIR=%~dp0"
set "APP_DIR=%ROOT_DIR%apps\flutter_app"
set "FLUTTER_BAT=D:\flutter\bin\flutter.bat"
set "API_BASE_URL=https://ycoming.top"

if not exist "%APP_DIR%" (
  echo [ERROR] Flutter app folder not found: %APP_DIR%
  exit /b 1
)

if not exist "%FLUTTER_BAT%" (
  echo [ERROR] Flutter not found: %FLUTTER_BAT%
  echo         Please update FLUTTER_BAT in this script.
  exit /b 1
)

pushd "%APP_DIR%"

call "%FLUTTER_BAT%" config --enable-windows-desktop
if errorlevel 1 (
  popd
  exit /b 1
)

call "%FLUTTER_BAT%" clean
if errorlevel 1 (
  popd
  exit /b 1
)

call "%FLUTTER_BAT%" pub get
if errorlevel 1 (
  popd
  exit /b 1
)

call "%FLUTTER_BAT%" build windows --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "BUILD_EXIT=%ERRORLEVEL%"

popd

if not "%BUILD_EXIT%"=="0" (
  exit /b %BUILD_EXIT%
)

echo [OK] Windows app built:
echo      %APP_DIR%\build\windows\x64\runner\Release\
exit /b 0
