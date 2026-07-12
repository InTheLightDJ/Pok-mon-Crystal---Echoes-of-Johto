@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Parse-CCSpriteSheet.ps1" -InDir "%~dp0sprites" -OutDir "%~dp0characters"
pause
