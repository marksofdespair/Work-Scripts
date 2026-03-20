@echo off

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

:: Run PowerShell script with execution policy bypass
powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\dell_cleanupV2.ps1"

pause