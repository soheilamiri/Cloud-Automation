<#
.SYNOPSIS
    Checks multiple Windows servers for pending reboots and system uptime.

.DESCRIPTION
    Reads an inventory JSON file, connects to each Windows server using PowerShell Remoting,
    and checks if a reboot is pending. Also gathers system uptime for each server.

.PARAMETER InventoryPath
    Full path to the JSON file containing server inventory.

.PARAMETER Credential
    Credentials to use when connecting to remote servers.

.EXAMPLE
    .\Check-PendingReboot.ps1 -InventoryPath "C:\inventory.json" -Credential (Get-Credential)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$InventoryPath,

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Credential
)

# Load and parse the inventory JSON file
if (!(Test-Path -Path $InventoryPath)) {
    Write-Error "Inventory file not found: $InventoryPath"
    exit 1
}

try {
    $inventory = Get-Content -Raw -Path $InventoryPath | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse inventory file."
    exit 1
}

# Initialize results array
$results = @()

foreach ($server in $inventory.Abris.windows) {
    try {
        # Create remote session using Kerberos
        $session = New-PSSession -ComputerName $server -Credential $Credential -Authentication Kerberos -ErrorAction Stop

        # Execute reboot and uptime check
        $status = Invoke-Command -Session $session -ScriptBlock {
            function Test-PendingReboot {
                if (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { return $true }
                if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { return $true }
                if (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) { return $true }
                try {
                    $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
                    $status = $util.DetermineIfRebootPending()
                    if ($status -and $status.RebootPending) { return $true }
                } catch {}
                return $false
            }

            # Get system uptime
            $os = Get-CimInstance Win32_OperatingSystem
            $lastBoot = $os.LastBootUpTime
            $uptime = (Get-Date) - $lastBoot
            $formattedUptime = "$($uptime.Days) days $($uptime.Hours) hours"

            [PSCustomObject]@{
                Hostname    = $env:COMPUTERNAME
                NeedReboot  = Test-PendingReboot
                Uptime      = $formattedUptime
            }
        }

        # Add successful result
        $results += $status
    }
    catch {
        # Log error result
        $results += [PSCustomObject]@{
            Hostname   = $server
            NeedReboot = "Unreachable"
            Uptime     = "N/A"
        }
    }
    finally {
        if ($session) {
            Remove-PSSession -Session $session
        }
    }
}

# Display results
$results | Format-Table -AutoSize

# Optional: Export to CSV
# $results | Export-Csv -Path "RebootStatus.csv" -NoTypeInformation
