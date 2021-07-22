Param(
    [Parameter(Mandatory=$true)]
    [string]$location,
    [Parameter(Mandatory=$true)]
    [string]$templatefilepath,
    [Parameter(Mandatory=$true)]
    [string]$parameterfolderpath
)
$parameters=""
$parameterfiles=ls $parameterfolderpath
foreach($paramfile in $parameterfiles){
$parameters+="@"+$paramfile+" "
}
cmd /c "az deployment sub create --location $location --template-file $templatefilepath --parameters $parameters"