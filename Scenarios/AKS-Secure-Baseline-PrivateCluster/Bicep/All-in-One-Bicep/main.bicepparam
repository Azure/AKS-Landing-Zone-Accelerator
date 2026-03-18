using './main.bicep'

// Required parameters — update before deploying
param aksAdminAccessPrincipalId = '<YOUR_ENTRA_ADMIN_GROUP_OBJECT_ID>'

// Jumpbox VM password — set JUMPBOX_PASSWORD environment variable before deploying:
//   $env:JUMPBOX_PASSWORD = 'YourSecurePassword123!'
param jumpboxAdminPassword = readEnvironmentVariable('JUMPBOX_PASSWORD', '')

