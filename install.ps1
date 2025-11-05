<#
.SYNOPSIS
  安全安装器模板，用于从 GitHub 下载并执行你的 payload.ps1。

.DESCRIPTION
  该脚本会：
  - 从指定 raw 链接下载 payload；
  - 验证 SHA256（若设置）；
  - 询问用户确认（或使用 -Force 跳过）；
  - 执行 payload；
  - 自动清理临时文件。

USAGE
  iwr https://raw.githubusercontent.com/Enheng404/test115/main/install.ps1 -useb | iex
#>

param(
    [switch]$Force
)

# === CONFIG: 请根据你的实际仓库替换以下信息 ===
$rawUrl = "https://raw.githubusercontent.com/Enheng404/test115/main/payload.ps1"   # ✅ 你的 payload 文件地址
$expectedHash = "8675094A5DD54B03C862FE8AC879143EE62956CB5BE046E8EE85CBECB786D30E"   # ✅ TODO: 替换为 payload.ps1 的 SHA256（Get-FileHash 得到的值）
# ==================================================

function Write-ErrorAndExit {
    param($msg, $code = 1)
    Write-Error $msg
    exit $code
}

Write-Host "Installer (safe template)"
if (-not $rawUrl) {
    Write-ErrorAndExit "ERROR: rawUrl is not set in install.ps1. Edit the script and set the source URL."
}

Write-Host "Source: $rawUrl"
Write-Host ""

# 下载 payload
try {
    if (Get-Command Invoke-RestMethod -ErrorAction SilentlyContinue) {
        $content = Invoke-RestMethod -Uri $rawUrl -UseBasicParsing
    } else {
        $wc = New-Object System.Net.WebClient
        $content = $wc.DownloadString($rawUrl)
    }
}
catch {
    Write-ErrorAndExit "Failed to download payload: $($_.Exception.Message)"
}

if (-not $content) {
    Write-ErrorAndExit "Downloaded payload is empty."
}

# 计算 SHA256
try {
    $ms = New-Object System.IO.MemoryStream
    $sw = New-Object System.IO.StreamWriter($ms)
    $sw.Write($content)
    $sw.Flush()
    $ms.Position = 0
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($ms)
    $calculated = ([BitConverter]::ToString($hashBytes)).Replace("-","").ToUpperInvariant()
}
catch {
    Write-ErrorAndExit "Failed to compute hash: $($_.Exception.Message)"
}

Write-Host "Payload SHA256: $calculated"

# 校验哈希
if ($expectedHash -and $expectedHash -ne "8675094A5DD54B03C862FE8AC879143EE62956CB5BE046E8EE85CBECB786D30E") {
    if ($calculated -ne $expectedHash.ToUpperInvariant()) {
        Write-ErrorAndExit "Hash mismatch! Expected: $expectedHash  Calculated: $calculated"
    } else {
        Write-Host "Hash verified."
    }
} else {
    Write-Warning "Warning: expectedHash is not configured. Skipping integrity check."
}

# 确认执行
if (-not $Force) {
    $yn = Read-Host "Proceed to execute the payload? Type Y to continue"
    if ($yn -notin @('Y','y','Yes','yes')) {
        Write-Host "Aborted by user."
        exit 0
    }
}

# 写入临时文件
try {
    $tempFile = Join-Path $env:TEMP ("payload_{0}.ps1" -f ([guid]::NewGuid().Guid))
    Set-Content -Path $tempFile -Value $content -Force -Encoding UTF8
}
catch {
    Write-ErrorAndExit "Failed to write payload to temp file: $($_.Exception.Message)"
}

Write-Host "Executing payload at: $tempFile"

# 执行 payload
$exe = (Get-Command pwsh -ErrorAction SilentlyContinue) ? "pwsh" : "powershell"
$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$tempFile`""
$proc = Start-Process -FilePath $exe -ArgumentList $arg -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Warning "Payload exited with code $($proc.ExitCode)."
}

# 清理
try {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Failed to remove temp file: $tempFile"
}

Write-Host "Done."
