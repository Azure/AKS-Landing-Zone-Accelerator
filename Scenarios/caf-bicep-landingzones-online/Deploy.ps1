Param(
    [string]$location="uksouth",
    [string]$templatefilepath="$PSScriptRoot\deploy.bicep",
    [string]$parameterfolderpath="$PSScriptRoot\Parameters"
)
$parameters=""
$parameterfiles=ls $parameterfolderpath
foreach($paramfile in $parameterfiles){
$parameters+="@"+$paramfile+" "
}
cmd /c "az deployment sub create --location $location --template-file $templatefilepath --parameters $parameters"