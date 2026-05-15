@echo off
set "FLUTTER_BIN=C:\flutter\bin"

echo Adding %FLUTTER_BIN% to your user PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$flutter='C:\flutter\bin'; $path=[Environment]::GetEnvironmentVariable('Path','User'); if ([string]::IsNullOrWhiteSpace($path)) { [Environment]::SetEnvironmentVariable('Path',$flutter,'User') } elseif (($path -split ';') -notcontains $flutter) { [Environment]::SetEnvironmentVariable('Path', ($path.TrimEnd(';') + ';' + $flutter), 'User') }"

echo.
echo Done. Close this terminal, open a new PowerShell window, then run:
echo   flutter pub get
echo   flutter run -d android
