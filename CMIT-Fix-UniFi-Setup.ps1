<#
CMIT-Fix-UniFi-Inform.ps1
pellis@cmitsolutions.com
2025-08-01-001

Latest Notes: Setup script to get host key into local cache

Using RMM, MDM or other means to deliver and run this on a machine in the LAN of the device you are wanting to fix.
#>
# === CONFIGURATION ===
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$paramFile = Join-Path $scriptDir "deviceParams.json"
$plinkFile = "plink.exe"
$plinkPath = Join-Path $scriptDir $plinkFile
$plinkUrl = "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe"

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

# === CONNECT TO EACH DEVICE TO CACHE HOST KEY ===
foreach ($ip in $ips) {
    Write-Host "`nConnecting to $ip to cache host key..."
    try {
        # This will prompt for host key and cache it
        & $plinkPath -ssh "$username@$ip" -pw $password "exit"
        Write-Host "Host key cached for $ip"
    } catch {
        Write-Warning "Failed to connect to $ip"
    }
}

Write-Host "`n Host key caching complete. You can now run your main script in batch mode."
