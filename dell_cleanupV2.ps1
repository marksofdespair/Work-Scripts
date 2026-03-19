New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
Start-Transcript -Path "C:\Temp\dell_cleanup_log.txt" -Append

# Programs Deskside Listed to Remove, can add/remove
$Bloatware = @(
"Dell Core Services",
"Dell Pair",
"Dell SupportAssist OS Recovery Plugin",
"Dell SupportAssist Remediation",
"Dell Trusted Device",
"Intel(R) Computing Improvement Program"
)

# Registry uninstall paths
$UninstallPaths = @(
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledApps = Get-ItemProperty $UninstallPaths | Where-Object { $_.DisplayName }

Write-Host "Stopping Dell Pair processes..."

$DellPairProcesses = Get-Process "*Dell*Pair*" -ErrorAction SilentlyContinue

if ($DellPairProcesses) {
    $DellPairProcesses | Stop-Process -Force
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
