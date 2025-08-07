<#
.SYNOPSIS
    Compares the system time of remote servers to the local machine.
.DESCRIPTION
    This script reads a list of Windows servers from a JSON inventory file,
    connects to each one via PowerShell remoting, and compares their system time 
    against the local system. Results show time difference and a status 
    indicating whether it's within the acceptable range (±2 minutes).
.PARAMETER InventoryPath
    Path to the JSON file containing the server list.
.PARAMETER Credential
    User credential for authenticating remote sessions.
.EXAMPLE
    PS> $cred = Get-Credential
    PS> .\Check-RemoteTimeSync.ps1 -InventoryPath "C:\Path\inventory.json" -Credential $cred
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$InventoryPath,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential
)

# Load server inventory
try {
    $inventory = Get-Content -Raw -Path $InventoryPath | ConvertFrom-Json
} catch {
    Write-Error "Failed to read inventory file: $_"
    exit 1
}

# Initialize results
$results = @()
$localTime = Get-Date

# Loop through each server
foreach ($server in $inventory.Abris.windows) {
    try {
        # Start remote session
        $session = New-PSSession -ComputerName $server -Credential $Credential 

        # Get remote system time
        $remoteTime = Invoke-Command -Session $session -ScriptBlock { Get-Date }

        # Compare time difference
        $timeDiff = [math]::Round((New-TimeSpan -Start $remoteTime -End $localTime).TotalMinutes, 2)
        $isSynced = [math]::Abs($timeDiff) -le 2
        $status = if ($isSynced) { "Synced" } else { "Out of Sync" }

        # Add result
        $results += [PSCustomObject]@{
            Server     = $server
            RemoteTime = $remoteTime
            LocalTime  = $localTime
            DiffMin    = $timeDiff
            Status     = $status
        }

        # Clean up
        Remove-PSSession -Session $session
    } catch {
        Write-Warning "Failed to connect to ${server}: $_"
        $results += [PSCustomObject]@{
            Server     = $server
            RemoteTime = "N/A"
            LocalTime  = $localTime
            DiffMin    = "N/A"
            Status     = "Unreachable"
        }
    }
}

# Output result as table
$results | Format-Table -AutoSize
