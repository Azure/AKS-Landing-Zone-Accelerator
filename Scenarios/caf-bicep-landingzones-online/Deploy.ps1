$Json = @()
$Json += Get-content -Path "C:\Users\mattl\OneDrive\Documents\Enterprise-Scale-for-AKS\Enterprise-Scale-for-AKS\Scenarios\caf-bicep-landingzones-online\Modules\DdosProtectionPlans\ddos.parameters.json" -raw | ConvertFrom-Json
$Json += Get-content -Path "C:\Users\mattl\OneDrive\Documents\Enterprise-Scale-for-AKS\Enterprise-Scale-for-AKS\Scenarios\caf-bicep-landingzones-online\Modules\virtualNetwork\vnet.parameters.json" -raw | ConvertFrom-Json
$Json = $Json.parameters
$Json = $Json | ConvertTo-Json | Out-File -FilePath "./merged.json"




$files = @("C:\Users\mattl\OneDrive\Documents\Enterprise-Scale-for-AKS\Enterprise-Scale-for-AKS\Scenarios\caf-bicep-landingzones-online\Modules\DdosProtectionPlans\ddos.parameters.json", "C:\Users\mattl\OneDrive\Documents\Enterprise-Scale-for-AKS\Enterprise-Scale-for-AKS\Scenarios\caf-bicep-landingzones-online\Modules\virtualNetwork\vnet.parameters.json")
    $allFiles = @()
	ForEach($file in $files){
		$data = Get-Content -Path $file -Raw | ConvertFrom-Json
		$allFiles += $data	
	}

    $allFiles | ConvertTo-Json | Out-File -FilePath ./merged.json



az deployment sub create --location 'uksouth' --template-file './deploy.bicep' --parameters '@./merged.json'