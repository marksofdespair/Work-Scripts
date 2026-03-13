Start-Transcript -Path "C:\Temp\dell_cleanup_log.txt" -Append

# Programs we want removed
$Bloatware = @(
"Dell Core Services",
"Dell Pair",
"Dell SupportAssist OS Recovery Plugin",
"Dell SupportAssist Remediation",
"Dell Trusted Device",
"Intel(R) Computing Improvement Program",
"Microsoft 365 - fr-fr",
"Microsoft 365 - pt-br",
"Microsoft OneNote - es-es",
"Microsoft OneNote - fr-fr",
"Microsoft OneNote - pt-br"
)

# Registry uninstall paths
$UninstallPaths = @(
"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$InstalledApps = Get-ItemProperty $UninstallPaths | Where-Object { $_.DisplayName }

Write-Host "Stopping Dell Pair processes..."

Get-Process | Where-Object {$_.ProcessName -like "*Dell*Pair*"} |
Stop-Process -Force -ErrorAction SilentlyContinue

foreach ($Target in $Bloatware) {

    $Matches = $InstalledApps | Where-Object { $_.DisplayName -like "*$Target*" }

    if ($Matches) {

        foreach ($App in $Matches) {

            Write-Host "Removing $($App.DisplayName)..."

            if ($App.UninstallString) {

                $UninstallCmd = $App.UninstallString

                if ($UninstallCmd -match "msiexec") {
                    $UninstallCmd = $UninstallCmd -replace "/I","/X"
                    $UninstallCmd += " /quiet /norestart"
                }

                Start-Process "cmd.exe" `
                    -ArgumentList "/c $UninstallCmd" `
                    -WindowStyle Hidden `
                    -Wait
            }
            else {
                Write-Host "No uninstall command found for $($App.DisplayName)"
            }
        }

    } 
    else {
        Write-Host "$Target not found."
    }
}

Stop-Transcript
