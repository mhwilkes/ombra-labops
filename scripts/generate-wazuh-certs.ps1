<#!
.SYNOPSIS
  Generate self-signed TLS certificates for Wazuh indexer and dashboard.

.DESCRIPTION
  Creates a local Root CA and issues the required certificates/keys expected by
  gitops/apps/security/wazuh/kustomization.yaml secretGenerators:
    - certs/indexer_cluster/{root-ca.pem,node.pem,node-key.pem,dashboard.pem,dashboard-key.pem,admin.pem,admin-key.pem,filebeat.pem,filebeat-key.pem}
    - certs/dashboard_http/{cert.pem,key.pem}

  Requires OpenSSL to be available on PATH. On Windows, you can install via:
    - winget install ShiningLight.OpenSSL
    - or choco install openssl.light

.PARAMETER Force
  Overwrite existing files if they exist.

.EXAMPLE
  ./scripts/generate-wazuh-certs.ps1 -Verbose

.EXAMPLE
  ./scripts/generate-wazuh-certs.ps1 -Force
#>

[CmdletBinding()]
param(
  [switch]$Force
)

function Test-ToolExists {
  param([Parameter(Mandatory)][string]$Name)
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Required tool not found: $Name. Please install it and ensure it's on PATH."
  }
}

Write-Host "Generating Wazuh self-signed certificates with OpenSSL..." -ForegroundColor Cyan
Test-ToolExists -Name 'openssl'

$repoRoot = Split-Path -Parent $PSScriptRoot
$certRoot = Join-Path $repoRoot 'gitops/apps/security/wazuh/certs'
$indexerDir = Join-Path $certRoot 'indexer_cluster'
$dashDir = Join-Path $certRoot 'dashboard_http'

New-Item -ItemType Directory -Force -Path $indexerDir | Out-Null
New-Item -ItemType Directory -Force -Path $dashDir | Out-Null

$rootKey = Join-Path $indexerDir 'root-ca.key'
$rootPem = Join-Path $indexerDir 'root-ca.pem'

$tmpDir = Join-Path ([IO.Path]::GetTempPath()) ("wazuh-certs-" + ([guid]::NewGuid()))
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
  # Common OpenSSL configs with SAN support
  $serverCnf = @"
[req]
distinguished_name = dn
req_extensions = req_ext
prompt = no

[dn]
C = US
O = Ombra Lab
CN = __CN__

[req_ext]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = indexer
DNS.2 = indexer.wazuh.svc
DNS.3 = wazuh-indexer
DNS.4 = wazuh-indexer.wazuh.svc
DNS.5 = wazuh-indexer-0
DNS.6 = wazuh-indexer-0.wazuh.svc
DNS.7 = wazuh-indexer-1
DNS.8 = wazuh-indexer-1.wazuh.svc
DNS.9 = wazuh-indexer-2
DNS.10 = wazuh-indexer-2.wazuh.svc
"@

  $dashCnf = @"
[req]
distinguished_name = dn
req_extensions = req_ext
prompt = no

[dn]
C = US
O = Ombra Lab
CN = dashboard

[req_ext]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = dashboard
DNS.2 = dashboard.wazuh.svc
"@

  $clientCnf = @"
[req]
distinguished_name = dn
req_extensions = req_ext
prompt = no

[dn]
C = US
O = Ombra Lab
CN = __CN__

[req_ext]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
"@

  # Write config files
  $serverCnfPath = Join-Path $tmpDir 'server.cnf'
  $dashCnfPath = Join-Path $tmpDir 'dashboard.cnf'
  $clientCnfPath = Join-Path $tmpDir 'client.cnf'
  Set-Content -Path $serverCnfPath -Value ($serverCnf -replace '__CN__','wazuh-indexer') -NoNewline
  Set-Content -Path $dashCnfPath -Value $dashCnf -NoNewline
  Set-Content -Path $clientCnfPath -Value ($clientCnf -replace '__CN__','client') -NoNewline

  # Generate Root CA
  if ((Test-Path $rootKey) -and -not $Force) { throw "Root CA already exists at $rootKey. Re-run with -Force to overwrite." }
  & openssl genrsa -out $rootKey 4096 | Write-Verbose
  & openssl req -x509 -new -nodes -key $rootKey -sha256 -days 3650 -subj "/C=US/O=Ombra Lab/CN=Wazuh Root CA" -out $rootPem | Write-Verbose

  # Helper to sign a CSR with our CA
  function Invoke-CertSign {
    param(
      [Parameter(Mandatory)][string]$Csr,
      [Parameter(Mandatory)][string]$Out,
      [Parameter(Mandatory)][string]$ExtFile,
      [Parameter(Mandatory)][string]$Extensions
    )
    & openssl x509 -req -in $Csr -CA $rootPem -CAkey $rootKey -CAcreateserial -out $Out -days 3650 -sha256 -extfile $ExtFile -extensions $Extensions | Write-Verbose
  }

  # Node (server)
  $nodeKey = Join-Path $indexerDir 'node-key.pem'
  $nodeCsr = Join-Path $tmpDir 'node.csr'
  $nodePem = Join-Path $indexerDir 'node.pem'
  if ((Test-Path $nodeKey) -and -not $Force) { throw "File exists: $nodeKey (use -Force)" }
  & openssl genrsa -out $nodeKey 2048 | Write-Verbose
  & openssl req -new -key $nodeKey -out $nodeCsr -config $serverCnfPath | Write-Verbose
  Invoke-CertSign -Csr $nodeCsr -Out $nodePem -ExtFile $serverCnfPath -Extensions req_ext

  # Dashboard (server)
  $dashKey = Join-Path $indexerDir 'dashboard-key.pem'
  $dashCsr = Join-Path $tmpDir 'dashboard.csr'
  $dashPem = Join-Path $indexerDir 'dashboard.pem'
  if ((Test-Path $dashKey) -and -not $Force) { throw "File exists: $dashKey (use -Force)" }
  & openssl genrsa -out $dashKey 2048 | Write-Verbose
  & openssl req -new -key $dashKey -out $dashCsr -config $dashCnfPath | Write-Verbose
  Invoke-CertSign -Csr $dashCsr -Out $dashPem -ExtFile $dashCnfPath -Extensions req_ext

  # Admin (client)
  $adminKey = Join-Path $indexerDir 'admin-key.pem'
  $adminCsr = Join-Path $tmpDir 'admin.csr'
  $adminPem = Join-Path $indexerDir 'admin.pem'
  if ((Test-Path $adminKey) -and -not $Force) { throw "File exists: $adminKey (use -Force)" }
  & openssl genrsa -out $adminKey 2048 | Write-Verbose
  # Write a temp admin config
  $adminCnfPath = Join-Path $tmpDir 'admin.cnf'
  Set-Content -Path $adminCnfPath -Value ($clientCnf -replace '__CN__','admin') -NoNewline
  & openssl req -new -key $adminKey -out $adminCsr -config $adminCnfPath | Write-Verbose
  Invoke-CertSign -Csr $adminCsr -Out $adminPem -ExtFile $adminCnfPath -Extensions req_ext

  # Filebeat (client)
  $fbKey = Join-Path $indexerDir 'filebeat-key.pem'
  $fbCsr = Join-Path $tmpDir 'filebeat.csr'
  $fbPem = Join-Path $indexerDir 'filebeat.pem'
  if ((Test-Path $fbKey) -and -not $Force) { throw "File exists: $fbKey (use -Force)" }
  & openssl genrsa -out $fbKey 2048 | Write-Verbose
  $fbCnfPath = Join-Path $tmpDir 'filebeat.cnf'
  Set-Content -Path $fbCnfPath -Value ($clientCnf -replace '__CN__','filebeat') -NoNewline
  & openssl req -new -key $fbKey -out $fbCsr -config $fbCnfPath | Write-Verbose
  Invoke-CertSign -Csr $fbCsr -Out $fbPem -ExtFile $fbCnfPath -Extensions req_ext

  # Copy dashboard certs to dashboard_http location and include root CA
  Copy-Item -Path $dashPem -Destination (Join-Path $dashDir 'cert.pem') -Force
  Copy-Item -Path $dashKey -Destination (Join-Path $dashDir 'key.pem') -Force
  Copy-Item -Path $rootPem -Destination (Join-Path $dashDir 'root-ca.pem') -Force

  Write-Host "✅ Certificates generated:" -ForegroundColor Green
  Get-ChildItem $indexerDir | ForEach-Object { Write-Host "  - $($_.Name)" }
  Get-ChildItem $dashDir | ForEach-Object { Write-Host "  - dashboard_http/$($_.Name)" }
  Write-Host "Note: These are self-signed for lab/demo. For production, use your PKI or a trusted CA." -ForegroundColor Yellow
}
finally {
  if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
}
