param(
    [Parameter(Mandatory=$true)]
    [string]$appdevs,
    [Parameter(Mandatory=$true)]
    [string]$aksops
)

# checking if Azure module is installed
$isInstalled = $false
if(Get-InstalledModule -Name Az.Resources -ErrorAction SilentlyContinue){
    $isInstalled = $true
}

if($isInstalled){
    New-AzADGroup -DisplayName $appdevs -MailNickname $appdevs
    New-AzADGroup -DisplayName $aksops -MailNickname $aksops
}
else {
    Write-Output "Azure PowerShell not installed. Installation steps in: https://learn.microsoft.com/powershell/azure/install-az-ps"
}
