Param(
    [string]$templatefilepath="$PSScriptRoot\deploy.bicep",
    [string]$parameterfolderpath="$PSScriptRoot\Parameters"
)
$location=(Get-Content "$parameterfolderpath\rg.parameters.json"|ConvertFrom-Json).parameters.rglocation.value
$parameters=""
$parameterfiles=ls $parameterfolderpath
foreach($paramfile in $parameterfiles){
$parameters+="@"+$paramfile+" "
}
cmd /c "az deployment sub create --location $location --template-file $templatefilepath --parameters $parameters"