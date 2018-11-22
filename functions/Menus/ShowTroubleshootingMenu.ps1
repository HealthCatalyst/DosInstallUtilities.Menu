<#
.SYNOPSIS
Shows troubleshooting menu

.DESCRIPTION
ShowTroubleshootingMenu

.INPUTS
ShowTroubleshootingMenu - The name of ShowTroubleshootingMenu

.OUTPUTS
None

.EXAMPLE
ShowTroubleshootingMenu

.EXAMPLE
ShowTroubleshootingMenu


#>
function ShowTroubleshootingMenu() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $baseUrl
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $local
    )

    $isAzure = $true
    Write-Verbose 'ShowTroubleshootingMenu: Starting'
    $userinput = ""
    while ($userinput -ne "q") {
        Write-Host "================ Troubleshooting menu ================"
        Write-Host "0: Show status of cluster"
        Write-Host "-----  Kubernetes ------"
        Write-Host "1: Open Kubernetes dashboard"
        Write-Host "3: Test DNS"
        Write-Host "5: Show kubernetes service status"
        Write-Host "6: Troubleshoot Ingresses"
        Write-Host "7: Show logs of all pods in kube-system"
        Write-Host "-----  Traefik reverse proxy ------"
        Write-Host "12: Show load balancer logs"
        Write-Host "------ Other tasks ---- "
        Write-Host "33: Create kubeconfig"
        Write-Host "34: Move TCP ports to main LoadBalancer"
        Write-Host "--------- DNS entries --------"
        Write-Host "41: Show DNS entries to make in DNS server"
        Write-Host "42: Show DNS entries for /etc/hosts"
        Write-Host "--- helpers ---"
        Write-Host "q: Go back to main menu"
        $userinput = Read-Host "Please make a selection"
        switch ($userinput) {
            '0' {
                ShowStatusOfCluster
            }
            '1' {
                if ($isAzure) {
                    LaunchAzureKubernetesDashboard
                }
                else {
                    OpenKubernetesDashboard
                }
            }
            '3' {
                TestDNS $baseUrl
            }
            '12' {
                ShowLoadBalancerLogs
            }
            '33' {
                GenerateKubeConfigFile -Verbose
            }
            '34' {
                MovePortsToLoadBalancer -resourceGroup $(GetResourceGroup).ResourceGroup
            }
            '41' {
                WriteDNSCommands
            }
            '42' {
                $loadBalancerIPResult = $(GetLoadBalancerIPs)
                Write-Host "If you didn't setup DNS, add the following entries in your c:\windows\system32\drivers\etc\hosts file to access the urls from your browser"
                $dnshostname = $(ReadSecretValue -secretname "dnshostname" -namespace "default")
                Write-Host "$($loadBalancerIPResult.ExternalIP) $dnshostname"
                Write-Host "$($loadBalancerIPResult.InternalIP) internal.$dnshostname"
            }
            'q' {
                return
            }
        }
        $userinput = Read-Host -Prompt "Press Enter to continue or q to go back to top menu"
        if ($userinput -eq "q") {
            return
        }
        [Console]::ResetColor()
        Clear-Host
    }

    Write-Verbose 'ShowTroubleshootingMenu: Done'

}

Export-ModuleMember -Function 'ShowTroubleshootingMenu'