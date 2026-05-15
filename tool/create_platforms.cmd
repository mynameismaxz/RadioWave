@echo off
pushd "%~dp0.."
"C:\flutter\bin\flutter.bat" create --platforms=android,ios,web,windows,macos,linux .
"C:\flutter\bin\flutter.bat" pub get
"C:\flutter\bin\flutter.bat" analyze
popd
