<#
CMIT-UniFi-Discovery.ps1
pellis@cmitsolutions.com
2025-08-04-002

Latest Notes: Fastping change, swapped to ping (w/ 300ms timeout) instead of Test-Connection

Using RMM, MDM or other means to deliver and run this on a machine in the LAN of the device you are wanting to fix.
#>
# Fast ping function using ping.exe for quicker response
function FastPing {
    param([string]$ip)
    $result = ping.exe -n 1 -w 300 $ip
    return $result -match "Reply from"
}

# Define the list of MAC addresses to find
$targetMacs = @(
    "58:38:79:81:67:98",
    "58-38-79-7E-83-6A"
)

# Normalize MACs to uppercase and dash-separated
$targetMacs = $targetMacs | ForEach-Object {
    $normalized = $_.ToUpper().Replace(":", "-")
    Write-Host "Normalized target MAC: $_ -> $normalized" -ForegroundColor Magenta
    $normalized
}

$foundMacs = @{}

# Define IP range
$subnet = "192.168.12"
$start = 1
$end = 254

Write-Host "Starting scan of $subnet.$start to $subnet.$end..."
Write-Host "Target MACs: $($targetMacs -join ', ')`n"

for ($i = $start; $i -le $end; $i++) {
    $ip = "$subnet.$i"
    Write-Host "Pinging $ip..." -ForegroundColor Cyan
    $ping = FastPing $ip

    if ($ping) {
        Write-Host "Ping successful. Checking ARP cache for $ip..." -ForegroundColor Green
        $arpOutput = arp -a $ip

        foreach ($line in $arpOutput) {
            if ($line -match "($ip)\s+([a-fA-F0-9:-]{17})") {
                $mac = $matches[2].ToUpper().Replace(":", "-")
                Write-Host "Found MAC $mac at $ip" -ForegroundColor Yellow

                foreach ($target in $targetMacs) {
                    Write-Host "Comparing $mac to target $target" -ForegroundColor DarkYellow
                }

                if ($targetMacs -contains $mac -and -not $foundMacs.ContainsKey($mac)) {
                    $foundMacs[$mac] = $ip
                    Write-Host "✅ Match found: $mac at $ip" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "No response from $ip" -ForegroundColor DarkGray
    }

    if ($foundMacs.Count -eq $targetMacs.Count) {
        Write-Host "`n🎯 All target MAC addresses found. Stopping scan." -ForegroundColor Green
        break
    }
}

Write-Host "`nScan complete. Found $($foundMacs.Count) of $($targetMacs.Count) MAC addresses."

if ($foundMacs.Count -gt 0) {
    foreach ($entry in $foundMacs.GetEnumerator()) {
        Write-Host " - $($entry.Key) found at $($entry.Value)"
    }
} else {
    Write-Host "⚠️ No target MAC addresses were found. Consider verifying the MAC list or network range." -ForegroundColor Red
}
