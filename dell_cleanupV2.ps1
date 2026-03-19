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

# Me and the homies hate dell pair
Write-Host "Attempting direct uninstall of Dell Pair..."

$DellPairUninstaller = "C:\Program Files\Dell\Dell Pair\Uninstall.exe"

if (Test-Path $DellPairUninstaller) {

    Start-Process $DellPairUninstaller `
        -ArgumentList "/S /silent /quiet /norestart" `
        -WindowStyle Hidden `
        -Wait

    Write-Host "Dell Pair uninstall command executed."
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

                    $SilentCmd = "$UninstallCmd /S /silent /quiet /norestart"

                    Start-Process "cmd.exe" `
                        -ArgumentList "/c $SilentCmd" `
                        -WindowStyle Hidden `
                        -Wait
                }

                break
            }
        }
    }
}

Stop-Transcript
