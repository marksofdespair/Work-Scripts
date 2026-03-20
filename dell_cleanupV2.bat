@echo off

:: Check for admin rights so it still runs as admin (?)
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run PowerShell script with execution policy bypass because dellware moment
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\dell_cleanupV2.ps1"

pause
