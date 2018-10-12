$module = Get-Module -Name "DosInstallUtilities.Menu"
$module | Select-Object *

$params = @{
    'Author' = 'Health Catalyst'
    'CompanyName' = 'Health Catalyst'
    'Description' = 'Functions to create menus'
    'NestedModules' = 'DosInstallUtilities.Menu'
    'Path' = ".\DosInstallUtilities.Menu.psd1"
}

New-ModuleManifest @params
