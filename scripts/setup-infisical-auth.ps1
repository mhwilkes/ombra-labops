# Infisical Authentication Setup Script
# Run this manually after setting up your Infisical project

# 1. First, encode your Infisical credentials
Write-Host "=== Infisical Auth Setup ===" -ForegroundColor Green

# Get credentials from user
$clientId = Read-Host "Enter your Infisical Client ID"
$clientSecret = Read-Host "Enter your Infisical Client Secret" -AsSecureString

# Convert secure string back to plain text for encoding
$clientSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))

# Base64 encode
$clientIdB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($clientId))
$clientSecretB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($clientSecretPlain))

# Create the secret YAML
$secretYaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: infisical-universal-auth
  namespace: infisical-operator-system
type: Opaque
data:
  clientId: $clientIdB64
  clientSecret: $clientSecretB64
"@

# Apply the secret
Write-Host "Applying Infisical auth secret..." -ForegroundColor Yellow
$secretYaml | kubectl apply -f -

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Infisical auth secret applied successfully!" -ForegroundColor Green
    Write-Host "You can now deploy your storage applications." -ForegroundColor Green
} else {
    Write-Host "❌ Failed to apply secret. Check your kubectl access." -ForegroundColor Red
}

# Clear variables for security
Clear-Variable clientId, clientSecret, clientSecretPlain, clientIdB64, clientSecretB64, secretYaml
