Push-Location -LiteralPath (Join-Path $PSScriptRoot '..')
& "C:\flutter\bin\flutter.bat" run -d android
Pop-Location
