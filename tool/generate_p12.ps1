$downloads = "$env:USERPROFILE\Downloads"
$cerPath = "$downloads\distribution.cer"
$p12Path = "$downloads\distribution.p12"
$pass = "segurcel123"

Write-Host "=== GENERATING APPLE P12 CERTIFICATE ==="

if (-not (Test-Path $cerPath)) {
    Write-Host "ERROR: distribution.cer not found in Downloads folder!"
    exit 1
}

# Load CER
$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
$cerKeyHex = [System.BitConverter]::ToString($cer.PublicKey.EncodedKeyValue.RawData)

# Search Windows Cert Store for matching key
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "CurrentUser")
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)

$found = $null
foreach ($c in $store.Certificates) {
    if ($c.HasPrivateKey) {
        $keyHex = [System.BitConverter]::ToString($c.PublicKey.EncodedKeyValue.RawData)
        if ($keyHex -eq $cerKeyHex) {
            $found = $c
            break
        }
    }
}

if ($found) {
    Write-Host "FOUND MATCHING CERTIFICATE WITH PRIVATE KEY!"
    # Export PFX using certutil or RSACryptoServiceProvider
    $thumb = $found.Thumbprint
    Write-Host "Thumbprint: $thumb"
} else {
    Write-Host "Searching all cert stores..."
}
$store.Close()
