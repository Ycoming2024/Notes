@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT_DIR=%~dp0"
set "APP_DIR=%ROOT_DIR%apps\flutter_app"
set "FLUTTER_BAT=D:\flutter\bin\flutter.bat"

if not exist "%APP_DIR%" (
  echo [ERROR] Flutter app folder not found: %APP_DIR%
  exit /b 1
)

if not exist "%FLUTTER_BAT%" (
  echo [ERROR] Flutter not found: %FLUTTER_BAT%
  echo         Please update FLUTTER_BAT in this script.
  exit /b 1
)

set "SDK_CANDIDATE="
if defined ANDROID_SDK_ROOT set "SDK_CANDIDATE=%ANDROID_SDK_ROOT%"
if not defined SDK_CANDIDATE if defined ANDROID_HOME set "SDK_CANDIDATE=%ANDROID_HOME%"
if not defined SDK_CANDIDATE if exist "%LOCALAPPDATA%\Android\Sdk" set "SDK_CANDIDATE=%LOCALAPPDATA%\Android\Sdk"

if not defined SDK_CANDIDATE (
  echo [ERROR] Android SDK not found.
  echo         Open Android Studio -^> More Actions -^> SDK Manager
  echo         Install: Android SDK, Platform-Tools, Build-Tools, Command-line Tools.
  echo         Suggested path: %LOCALAPPDATA%\Android\Sdk
  exit /b 1
)

if not exist "%SDK_CANDIDATE%\platform-tools\adb.exe" (
  echo [ERROR] SDK path found but platform-tools is missing:
  echo         %SDK_CANDIDATE%
  echo         Please install Platform-Tools in SDK Manager.
  exit /b 1
)

set "ANDROID_HOME=%SDK_CANDIDATE%"
set "ANDROID_SDK_ROOT=%SDK_CANDIDATE%"
set "PATH=%ANDROID_SDK_ROOT%\platform-tools;%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin;%PATH%"
set "GRADLE_OPTS=-Dorg.gradle.internal.plugins.portal.url.override=https://maven.aliyun.com/repository/gradle-plugin -Dhttps.protocols=TLSv1.2 -Dfile.encoding=UTF-8 %GRADLE_OPTS%"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
set "API_BASE_URL=https://ycoming.top"

echo [INFO] Using Android SDK: %ANDROID_SDK_ROOT%
echo [INFO] Using Gradle plugin mirror: https://maven.aliyun.com/repository/gradle-plugin
echo [INFO] Using Flutter storage mirror: %FLUTTER_STORAGE_BASE_URL%
echo [INFO] Using API base URL: %API_BASE_URL%

set "LOCAL_PROPERTIES=%APP_DIR%\android\local.properties"
if exist "%LOCAL_PROPERTIES%" (
  findstr /b /c:"sdk.dir=" "%LOCAL_PROPERTIES%" >nul
  if errorlevel 1 (
    >> "%LOCAL_PROPERTIES%" echo sdk.dir=%ANDROID_SDK_ROOT:\=\\%
  )
) else (
  (
    echo flutter.sdk=D:\\flutter
    echo sdk.dir=%ANDROID_SDK_ROOT:\=\\%
  )> "%LOCAL_PROPERTIES%"
)

pushd "%APP_DIR%"
if exist ".dart_tool" (
  rmdir /s /q ".dart_tool"
)

call "%FLUTTER_BAT%" pub get
if errorlevel 1 (
  popd
  exit /b 1
)

if not exist ".dart_tool\package_config.json" (
  echo [ERROR] .dart_tool\package_config.json not found after pub get.
  echo         Try running manually in %APP_DIR%:
  echo         %FLUTTER_BAT% clean ^&^& %FLUTTER_BAT% pub get
  popd
  exit /b 1
)

call "%FLUTTER_BAT%" build apk --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "BUILD_EXIT=%ERRORLEVEL%"
popd

if not "%BUILD_EXIT%"=="0" (
  exit /b %BUILD_EXIT%
)

echo [OK] APK generated:
echo      %APP_DIR%\build\app\outputs\flutter-apk\app-release.apk
exit /b 0
