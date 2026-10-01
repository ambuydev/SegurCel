$apkPath = "build/app/outputs/flutter-apk/app-debug.apk"
if (-Not (Test-Path $apkPath)) {
    Write-Host "APK file not found"
    exit
}

$bytes = [System.IO.File]::ReadAllBytes($apkPath)
$bucket = "segurcel-45c92.appspot.com"
$uri = "https://firebasestorage.googleapis.com/v0/b/$bucket/o?name=SegurCel-Android.apk"

try {
    $res = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/vnd.android.package-archive" -Body $bytes
    Write-Host "UPLOAD SUCCESSFUL!"
    Write-Host "Name: $($res.name)"
    Write-Host "Download Token: $($res.downloadTokens)"
    $downloadUrl = "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$($res.name)?alt=media&token=$($res.downloadTokens)"
    Write-Host "DOWNLOAD_URL: $downloadUrl"
} catch {
    Write-Host "UPLOAD ERROR: $_"
}
