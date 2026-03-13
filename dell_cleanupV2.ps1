# V1.5, Ensure log folder exists
New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null

Start-Transcript -Path "C:\Temp\dell_cleanup_log.txt" -Append

Write-Host "Starting Dell cleanup script..."

# Programs deskside listed as removeable
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

    } else {
        Write-Host "$Target not found."
    }
}

Write-Host "Checking for Dell Pair leftovers..."

# Remove Dell Pair scheduled tasks
Get-ScheduledTask | Where-Object {$_.TaskName -like "*Dell*Pair*"} | ForEach-Object {
    Write-Host "Removing scheduled task: $($_.TaskName)"
    Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false
}

# Remove leftover Dell Pair folder, should fully uninstall now?
$DellPairPath = "C:\Program Files\Dell\DellPair"

if (Test-Path $DellPairPath) {
    Write-Host "Removing leftover Dell Pair folder..."
    Remove-Item $DellPairPath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Removing Microsoft language packs..."

# Remove language packs silently
$languages = @(
"fr-FR",
"pt-BR",
"es-ES"
)

foreach ($lang in $languages) {

    Write-Host "Attempting to remove language pack $lang"

    Start-Process "lpksetup.exe" `
        -ArgumentList "/u $lang /quiet /norestart" `
        -WindowStyle Hidden `
        -Wait
}

Write-Host "Cleanup script finished."

Stop-Transcript