Push-Location -LiteralPath (Join-Path $PSScriptRoot '..')
& "C:\flutter\bin\flutter.bat" run -d chrome
Pop-Location
