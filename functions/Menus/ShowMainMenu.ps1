<#
.SYNOPSIS
Shows main menu

.DESCRIPTION
ShowMainMenu

.INPUTS
ShowMainMenu - The name of ShowMainMenu

.OUTPUTS
None

.EXAMPLE
ShowMainMenu

.EXAMPLE
ShowMainMenu


#>
function ShowMainMenu() {
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
        ,
        [Parameter(Mandatory = $false)]
        [bool]
        $prerelease = $false
    )

    Write-Verbose 'ShowMainMenu: Starting'

    Set-StrictMode -Version latest
    # stop whenever there is an error
    $ErrorActionPreference = "Stop"

    LoginToAzure -Verbose
    [string] $expiresOn = $(az account get-access-token --query "expiresOn" -o tsv)
    if (![string]::IsNullOrEmpty($expiresOn)) {
        Write-Host "You are already logged into Azure"
    }
    else {
        [Console]::ResetColor()
        Write-Host "Please login to Azure"
        az login
    }

    [string] $loggedInUser = $(az account show --query "user.name"  --output tsv)
    [string] $subscriptionName = $(az account show --query "name"  --output tsv)
    Write-Host "User = $loggedInUser with subscription [$subscriptionName]"

    $kubectlInfo = $(Get-Command kubectl.exe -ErrorAction SilentlyContinue)
    if($kubectlInfo){
        [string] $kubectlVersion = $(kubectl version --client=true --short=true)
        Write-Host "Using kubectl version [$kubectlVersion] from $($kubectlInfo.Source)"
    }
    else {
        Write-Warning "No kubectl found in the path.  Choose Install Client tools below."
    }

    $userinput = ""
    while ($userinput -ne "q") {
        $skip = $false
        $currentcluster = ""
        if (Test-CommandExists kubectl) {
            $currentcluster = $(kubectl config current-context 2> $null)
        }

        Write-Host "================ Health Catalyst ================"
        if ($prerelease) {
            Write-Host "prerelease flag: $prerelease"
        }
        Write-Warning "CURRENT CLUSTER: $currentcluster"

        Write-Host "------ Access Control -------"
        Write-Host "1: Login as admin"
        Write-Host "2: Login as user"
        # Write-Host "3: Enable access for a user"
        Write-Host "4: Install client tools"
        Write-Host "5: Change Azure Subscription"
        Write-Host "11: Connect to different Azure Kubernetes Service"

        Write-Host "------ Infrastructure -------"
        Write-Host "12: Configure existing Azure Kubernetes Service"
        Write-Host "13: Launch AKS Dashboard"
        Write-Host "------ Troubleshooting Infrastructure -------"
        #    Write-Host "3: Launch Traefik Dashboard"
        Write-Host "9: Show nodes"
        Write-Host "10: Show DNS entries for /etc/hosts"

        Write-Host "----- Troubleshooting ----"
        Write-Host "20: Show status of cluster"
        Write-Host "23: View status of DNS pods"
        Write-Host "24: Shows Logs of pods in kube-system"

        Write-Host "------ Keyvault -------"
        Write-Host "26: Copy Kubernetes secrets to keyvault"
        Write-Host "27: Copy secrets from keyvault to kubernetes"

        Write-Host "------ Load Balancer -------"
        Write-Host "30: Test load balancer"
        Write-Host "31: Show load balancer logs"

        Write-Host "------ Realtime -------"
        Write-Host "52: Fabric.Realtime Menu"
        Write-Host "------ NLP -------"
        Write-Host "62: Fabric.NLP Menu"

        Write-Host "q: Quit"
        #--------------------------------------
        $userinput = Read-Host "Please make a selection"
        switch ($userinput) {
            '1' {
                [string] $resourceGroup = ""
                # [string] $resourceGroup = $(GetResourceGroupFromSecret -Verbose).Value
                while ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                    $resourceGroup = Read-Host "Resource Group"
                }

                [string] $clusterName = $(GetClusterName -resourceGroup $resourceGroup -Verbose).ClusterName

                GetClusterCredentials -resourceGroup $resourceGroup -clusterName $clusterName -Verbose
            }
            '2' {
                [string] $resourceGroup = ""
                # [string] $resourceGroup = $(GetResourceGroupFromSecret -Verbose).Value
                while ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                    $resourceGroup = Read-Host "Resource Group"
                }

                [string] $clusterName = $(GetClusterName -resourceGroup $resourceGroup -Verbose).ClusterName

                GetClusterCredentials -resourceGroup $resourceGroup -clusterName $clusterName -Verbose
            }
            '3' {
                kubectl version

                [string] $currentsubscriptionName = $(Get-AzureRmContext).Subscription.Name

                [string] $resourceGroup = ""
                # [string] $resourceGroup = $(GetResourceGroupFromSecret -Verbose).Value
                while ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                    $resourceGroup = Read-Host "Resource Group"
                }

                # [hashtable] $servicePrincipal = GetServicePrincipalFromKeyVault -resourceGroup $resourceGroup -Verbose

                # LoginAsServiceAccount -servicePrincipalClientId $servicePrincipal.ServicePrincipalClientId `
                #     -servicePrincipalClientSecret $servicePrincipal.ServicePrincipalClientSecret `
                #     -tenantId $servicePrincipal.TenantId `
                #     -Verbose

                [string] $clusterName = $(GetClusterName -resourceGroup $resourceGroup -Verbose).ClusterName

                GetClusterAdminCredentials -resourceGroup $resourceGroup -clusterName $clusterName -Verbose

                [string] $userName = ""
                while ([string]::IsNullOrWhiteSpace($userName)) {
                    $userName = Read-Host "User name to grant access to cluster"
                }
                AddPermissionForUser -userName $userName -Verbose
            }
            '4' {
                InstallKubectl

                InstallHelmClient
            }
            '5' {
                ChooseFromSubscriptionList
            }
            '9' {
                Write-Host "Current cluster: $(kubectl config current-context)"
                kubectl version --short
                kubectl get "nodes"
            }
            '10' {
                Write-Host "If you didn't setup DNS, add the following entries in your c:\windows\system32\drivers\etc\hosts file to access the urls from your browser"
                $loadBalancerIPResult = GetLoadBalancerIPs
                $EXTERNAL_IP = $loadBalancerIPResult.ExternalIP

                $dnshostname = $(ReadSecretValue -secretname "dnshostname" -namespace "default")
                Write-Host "$EXTERNAL_IP $dnshostname"
            }
            '11' {
                [string] $resourceGroup = ""
                # [string] $resourceGroup = $(GetResourceGroupFromSecret -Verbose).Value
                while ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                    $resourceGroup = Read-Host "Resource Group"
                }
                [string] $clusterName = $(GetClusterName -resourceGroup $resourceGroup -Verbose).ClusterName

                GetClusterCredentials -resourceGroup $resourceGroup -clusterName $clusterName -Verbose

                $currentcluster = $(kubectl config current-context 2> $null)

                Write-Host "Now pointing to cluster $currentcluster"
            }
            '12' {
                [string] $currentsubscriptionName = $(Get-AzureRmContext).Subscription.Name

                $resourceGroup = ""
                if (!$resourceGroup) {
                    $resourceGroup = Read-Host "Resource Group"
                }
                InitKubernetes -resourceGroup $resourceGroup -subscriptionName $currentsubscriptionName -Verbose
            }
            '13' {
                $resourceGroup = $(GetResourceGroupFromSecret).Value
                if (!$resourceGroup) {
                    $resourceGroup = Read-Host "Resource Group"
                }
                LaunchAksDashboard -resourceGroup $resourceGroup -runAsJob $false
            }
            '20' {
                Write-Host "Current cluster: $(kubectl config current-context)"
                kubectl version --short
                kubectl get "deployments,pods,services,ingress,secrets,nodes" --namespace=kube-system -o wide
            }
            '23' {
                RestartDNSPodsIfNeeded
            }
            '24' {
                kubectl logs -l "app=nginx-ingress" -n kube-system
            }
            '26' {
                $currentResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup -Verbose
                CopyKubernetesSecretsToKeyVault -resourceGroup $currentResourceGroup -Verbose
            }
            '27' {
                $currentResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup -Verbose
                CopyKeyVaultSecretsToKubernetes -resourceGroup $currentResourceGroup -Verbose
            }
            '30' {
                TestAzureLoadBalancer
            }
            '31' {
                kubectl logs -l "app=nginx-ingress" -n kube-system
            }
            '50' {
                ShowTroubleshootingMenu -baseUrl $baseUrl -local $local
                $skip = $true
            }
            '52' {
                ShowRealtimeMenu -baseUrl $baseUrl -namespace "fabricrealtime" -local $local
                $skip = $true
            }
            '62' {
                ShowNlpMenu -baseUrl $baseUrl -namespace "fabricnlp" -local $local
                $skip = $true
            }
            'q' {
                return
            }
        }
        if (!($skip)) {
            $userinput = Read-Host -Prompt "Press Enter to continue or q to exit"
            if ($userinput -eq "q") {
                return
            }
        }
        [Console]::ResetColor()
        Clear-Host
    }

    Write-Verbose 'ShowMainMenu: Done'
}

Export-ModuleMember -Function 'ShowMainMenu'