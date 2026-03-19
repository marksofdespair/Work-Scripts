New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
Start-Transcript -Path "C:\Temp\dell_cleanup_log.txt" -Append

# Programs Deskside Listed to Remove, can add/remove
$Bloatware = @(
"Dell Core Services",
"Dell Pair",
"Dell SupportAssist OS Recovery Plugin",
"Dell SupportAssist Remediation",
"Dell Trusted Device",
"Dell Optimizer",
"Dell Optimizer Core",
"Intel(R) Computing Improvement Program"
)

# Registry uninstall paths
$UninstallPaths = @(
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledApps = Get-ItemProperty $UninstallPaths | Where-Object { $_.DisplayName }

Write-Host "Stopping Dell-related processes..."

$ProcessesToStop = @(
"*Dell*Pair*",
"*Dell*Optimizer*"
)

foreach ($pattern in $ProcessesToStop) {
    $procs = Get-Process $pattern -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force
    }
}

# Me and the homies hate dell pair AND dell optimizer
Write-Host "Running direct uninstallers..."

$DirectUninstallers = @(
"C:\Program Files\Dell\Dell Pair\Uninstall.exe",
"C:\Program Files\Dell\Dell Optimizer\uninstall.exe",
"C:\Program Files\Dell\Dell Optimizer Core\uninstall.exe"
)

foreach ($uninstaller in $DirectUninstallers) {

    if (Test-Path $uninstaller) {

        Write-Host "Executing $uninstaller"

        Start-Process $uninstaller `
            -ArgumentList "/S /silent /quiet /norestart" `
            -WindowStyle Hidden `
            -Wait
    }
}

foreach ($App in $InstalledApps) {

    foreach ($Target in $Bloatware) {

        if ($App.DisplayName -like "*$Target*") {

            Write-Host "Removing $($App.DisplayName)..."

            if ($App.UninstallString) {

                $UninstallCmd = $App.UninstallString

                if ($UninstallCmd -match "msiexec") {

                    $UninstallCmd = $UninstallCmd -replace "/I","/X"
                    $UninstallCmd += " /quiet /norestart"

                    Start-Process "cmd.exe" `
                        -ArgumentList "/c $UninstallCmd" `
                        -WindowStyle Hidden `
                        -Wait
                }
                else {

                    # For handling .exe uninstallers because they're annoying
                    Start-Process "cmd.exe" `
                        -ArgumentList "/c `"$UninstallCmd /S /silent /quiet /norestart`"" `
                        -WindowStyle Hidden `
                        -Wait
                }

                break
            }
        }
    }
}

Write-Host "Cleaning up leftover Dell directories..."

$CleanupPaths = @(
"C:\Program Files\Dell\DellOptimizer",
"C:\Program Files\Dell\Dell Optimizer",
"C:\Program Files\Dell\Dell Optimizer Core"
)

foreach ($path in $CleanupPaths) {

    if (Test-Path $path) {

        Write-Host "Removing leftover folder: $path"

        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " Uninstalls complete!" -ForegroundColor Green
Write-Host " You can safely close this window." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Stop-Transcript
