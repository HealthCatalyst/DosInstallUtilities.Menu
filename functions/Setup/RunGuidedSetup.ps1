<#
.SYNOPSIS
RunGuidedSetup

.DESCRIPTION
RunGuidedSetup

.INPUTS
RunGuidedSetup - The name of RunGuidedSetup

.OUTPUTS
None

.EXAMPLE
RunGuidedSetup

.EXAMPLE
RunGuidedSetup


#>
function RunGuidedSetup()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'RunGuidedSetup: Starting'
    Set-StrictMode -Version latest
    $ErrorActionPreference = 'Stop'

    ChooseFromSubscriptionList

    # CheckUserIsKubernetesAdministrator

    [string] $clusterName = $(GetClusterName -resourceGroup $resourceGroup -Verbose).ClusterName

    GetClusterCredentials -resourceGroup $resourceGroup -clusterName $clusterName -Verbose

    $currentcluster = $(kubectl config current-context 2> $null)

    Write-Host "Now pointing to cluster $currentcluster"

    [string] $currentsubscriptionName = $(Get-AzureRmContext).Subscription.Name
    InitKubernetes -resourceGroup $resourceGroup -subscriptionName $currentsubscriptionName -Verbose

    [string] $installRealtime = ""
    while([string]::IsNullOrWhiteSpace($installRealtime)){
        [string] $installRealtime = Read-Host -Prompt "Install Fabric.Realtime? [Y/N]"
    }

    if($installRealtime -eq 'y'){
        $packageUrl = $kubeGlobals.realtimePackageUrl
        $namespace = "fabricrealtime"
        $local = $true
        $isAzure = $true

        InstallRealtime -namespace $namespace -package "fabricrealtime" -packageUrl $packageUrl -local $local -isAzure $isAzure
    }

    Write-Verbose 'RunGuidedSetup: Done'
}

Export-ModuleMember -Function 'RunGuidedSetup'