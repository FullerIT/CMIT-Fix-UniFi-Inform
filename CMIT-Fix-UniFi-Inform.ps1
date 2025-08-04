<#
CMIT-Fix-UniFi-Inform.ps1
pellis@cmitsolutions.com
2025-08-01-002

Latest Notes: Sends set-inform before each status check until "Connected" is detected.

Using RMM, MDM or other means to deliver and run this on a machine in the LAN of the device you are wanting to fix.
#>

# === CONFIGURATION ===
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$paramFile = Join-Path $scriptDir "deviceParams.json"
$plinkFile = "plink.exe"
$plinkPath = Join-Path $scriptDir $plinkFile
$plinkUrl = "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe"
$correctUrl = "http://unifi.cmitcincy.com:8080/inform"

# === LOAD PARAMETERS ===
if (-Not (Test-Path $paramFile)) {
    Write-Error "Parameter file not found: $paramFile"
    exit
}
$params = Get-Content $paramFile -Raw | Out-String | ConvertFrom-Json
$username = $params.username
$password = $params.password
$ips = $params.ips

# === CHECK FOR PLINK ===
if (-Not (Test-Path $plinkPath)) {
    Write-Host "Plink not found. Downloading..."
    Invoke-WebRequest -Uri $plinkUrl -OutFile $plinkPath
    Write-Host "Plink downloaded to $plinkPath"
}

# === FUNCTION TO RUN SSH COMMAND ===
function Run-SSHCommand($ip, $command) {
    & $plinkPath -ssh "$username@$ip" -pw $password -batch -no-antispoof $command
}

# === LOOP THROUGH IPs ===
foreach ($ip in $ips) {
    Write-Host "`n--- Checking device at $ip ---"

    try {
        $infoOutput = Run-SSHCommand $ip "mca-cli-op info"
        $statusLine = $infoOutput | Where-Object { $_ -like "Status:*" }

        Write-Host "Initial Status:`n$statusLine"

        $needsUpdate = $true

        if ($statusLine -match "https?://[^\s]+") {
            $currentUrl = $matches[0]
            if ($currentUrl -eq $correctUrl -and $statusLine -match "Connected") {
                Write-Host "✅ Device at $ip is already connected to the correct inform URL."
                $needsUpdate = $false
            } else {
                Write-Host "Incorrect inform URL or not connected. Detected: $currentUrl"
            }
        } else {
            Write-Host "No inform URL found in status. Proceeding to set it."
        }

        if ($needsUpdate) {
            $maxAttempts = 12  # 12 x 15s = 3 minutes max wait
            $attempt = 0
            do {
                Write-Host "Sending set-inform command to $ip..."
                Run-SSHCommand $ip "mca-cli-op set-inform $correctUrl"

                Start-Sleep -Seconds 15

                $infoOutput = Run-SSHCommand $ip "mca-cli-op info"
                $statusLine = $infoOutput | Where-Object { $_ -like "Status:*" }
                Write-Host "Status check [$($attempt + 1)]: $statusLine"
                $attempt++
            } while ($statusLine -notmatch "Connected" -and $attempt -lt $maxAttempts)

            if ($statusLine -match "Connected") {
                Write-Host "✅ Device at $ip is now connected to the correct inform URL."
            } else {
                Write-Warning "⚠️ Device at $ip did not connect within the expected time."
            }
        }
    } catch {
        Write-Warning "⚠️ Failed to connect to $ip."
    }
}

# === CLEANUP PARAMETER FILE ===
Remove-Item $paramFile -Force
Write-Host "`nParameter file deleted."
