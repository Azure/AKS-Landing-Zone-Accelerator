$ErrorActionPreference = "Stop"

Write-Output "Configuring IIS with authentication."

# Add required Windows features, since they are not installed by default.
Install-WindowsFeature "Web-Windows-Auth", "Web-Asp-Net45"

# Configure IIS with authentication.
Import-Module IISAdministration
Start-IISCommitDelay
(Get-IISConfigSection -SectionPath 'system.webServer/security/authentication/windowsAuthentication').Attributes['enabled'].value = $true
(Get-IISConfigSection -SectionPath 'system.webServer/security/authentication/anonymousAuthentication').Attributes['enabled'].value = $false
(Get-IISServerManager).Sites[0].Applications[0].VirtualDirectories[0].PhysicalPath = 'C:\inetpub\wwwroot\'
Stop-IISCommitDelay

Write-Output "IIS with authentication is ready."

C:\ServiceMonitor.exe w3svc

.\Set-WebConfigSettings.ps1 -webConfig c:\inetpub\wwwroot\Web.config

If (Test-Path Env:\ASPNET_ENVIRONMENT)
{
    \WebConfigTransformRunner.1.0.0.1\Tools\WebConfigTransformRunner.exe \inetpub\wwwroot\Web.config "\inetpub\wwwroot\Web.$env:ASPNET_ENVIRONMENT.config" \inetpub\wwwroot\Web.config
}
Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }