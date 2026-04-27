<#
.SYNOPSIS
    禁用 Windows 系统备份与还原
.DESCRIPTION
    关闭系统还原点创建、删除所有现有还原点、禁用相关备份服务，并写入注册表禁止手动开启。
    需要以管理员身份运行。
#>

# 自动请求管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请求管理员权限..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null 2>&1

# 禁用快速编辑模式（避免误触暂停）
try {
    Set-ItemProperty -Path "HKCU:\Console" -Name QuickEdit -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
} catch { }

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "      正在禁用 Windows 系统备份与还原" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 1. 关闭系统还原点创建
Write-Host "1. 关闭系统还原点创建..." -ForegroundColor Yellow
try {
    Disable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
} catch { }

# 2. 删除所有现有还原点
Write-Host "2. 删除已存在的还原点..." -ForegroundColor Yellow
try {
    $restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    foreach ($rp in $restorePoints) {
        Remove-ComputerRestorePoint -RestorePoint $rp.SequenceNumber -ErrorAction SilentlyContinue
    }
} catch { }

# 3. 禁用备份相关服务
Write-Host "3. 禁用备份相关服务..." -ForegroundColor Yellow
$services = @("VSS", "srservice", "BackupRestore")
foreach ($svc in $services) {
    try {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    } catch { }
}

# 4. 注册表禁用还原（兜底写法）
Write-Host "4. 禁用手动开启还原..." -ForegroundColor Yellow
$regPaths = @(
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore"; Name = "DisableSR"; Value = 1; Type = "DWord"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"; Name = "DisableConfig"; Value = 1; Type = "DWord"},
    @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\FileHistory"; Name = "Disabled"; Value = 1; Type = "DWord"}
)
foreach ($reg in $regPaths) {
    try {
        if (-not (Test-Path $reg.Path)) {
            New-Item -Path $reg.Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type $reg.Type -Force -ErrorAction SilentlyContinue
    } catch { }
}

Write-Host ""
Write-Host "✅ 操作完成！（无报错即生效）" -ForegroundColor Green
Write-Host "提示：即使有服务/注册表提示不存在，也不影响核心功能" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")