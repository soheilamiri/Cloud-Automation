<#
.SYNOPSIS
    PowerCLI script to calculate total provisioned resources (VM count, vCPUs, RAM) 
    across all ESXi hosts in a vCenter or cluster.

.DESCRIPTION
    - Connects to a vCenter server using VMware PowerCLI
    - Iterates through each ESXi host
    - Collects total number of powered-on VMs, provisioned vCPU cores, and provisioned RAM
    - Displays results per host and aggregated cluster totals

.REQUIREMENTS
    - VMware PowerCLI module installed
    - Network connectivity to vCenter
    - User with read privileges on vCenter and ESXi hosts

.NOTES
    Author: Your Name
    GitHub: https://github.com/yourrepo/cloud-automation
    License: MIT
#>

# Disable SSL certificate warnings (optional, not recommended for production)
Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:$false | Out-Null

# =========================
# User Variables
# =========================
# Replace these placeholders with your vCenter credentials and address
$vcenter_user = "your-username@domain.local"
$vcenter_pass = "your-password"   # ⚠️ Consider using Get-Credential or a secure vault
$vcenter_add  = "your-vcenter.domain.local"

# Connect to vCenter
Connect-VIServer -Server $vcenter_add -User $vcenter_user -Password $vcenter_pass

# Get all ESXi hosts in vCenter 
# (To scope to a specific cluster, use: Get-Cluster -Name "ClusterName" | Get-VMHost)
$vmhosts = Get-VMHost

# Initialize cluster totals
$clusterTotals = [PSCustomObject]@{
    TotalVMs   = 0
    TotalCPU   = 0
    TotalRAMGB = 0
}

# =========================
# Loop through each ESXi host
# =========================
foreach ($esxi in $vmhosts) {
    # Get powered-on VMs on the host
    $poweredOnVMs = Get-VM -Location $esxi | Where-Object {$_.PowerState -eq 'PoweredOn'}

    # Calculate totals per host
    $vmCount  = $poweredOnVMs.Count
    $cpuTotal = ($poweredOnVMs | Measure-Object -Property NumCPU   -Sum).Sum
    $ramTotal = ($poweredOnVMs | Measure-Object -Property MemoryGB -Sum).Sum

    # Print per-host info
    Write-Host "Host: $($esxi.Name)" -ForegroundColor Cyan
    Write-Host "  Running VMs       : $vmCount"
    Write-Host "  Provisioned vCPUs : $cpuTotal"
    Write-Host "  Provisioned RAMGB : $ramTotal"
    Write-Host ""

    # Add to cluster totals
    $clusterTotals.TotalVMs   += $vmCount
    $clusterTotals.TotalCPU   += $cpuTotal
    $clusterTotals.TotalRAMGB += $ramTotal
}

# =========================
# Print overall cluster totals
# =========================
Write-Host "===== Cluster Totals =====" -ForegroundColor Green
Write-Host "Total Running VMs       : $($clusterTotals.TotalVMs)"
Write-Host "Total Provisioned vCPUs : $($clusterTotals.TotalCPU)"
Write-Host "Total Provisioned RAMGB : $($clusterTotals.TotalRAMGB)"
