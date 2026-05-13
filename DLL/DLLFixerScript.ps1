param(
    [string]$Mode = "",
    [switch]$Auto
)

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.PSCommandPath
    }
    if (-not $scriptPath) {
        $scriptPath = Join-Path $PSScriptRoot "DLLFixerScript.ps1"
    }

    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($Mode) {
        $arguments += " -Mode $Mode"
    }
    if ($Auto) {
        $arguments += " -Auto"
    }

    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
try {
    chcp 65001 | Out-Null
} catch {}

$scriptDir = $PSScriptRoot
$jsonDir = Join-Path $scriptDir "Json"
$downloadDir = Join-Path $env:TEMP "DLLFixerDownloads"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

function Write-MenuHeader {
    param([string]$title)
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "        $title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-MenuHeader "DLL修复工具"
    Write-Host "请选择要执行的操作：" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. 全面体检" -ForegroundColor Yellow
    Write-Host "     - 检测系统中的DLL和运行库问题" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. 运行库修复" -ForegroundColor Yellow
    Write-Host "     - 检测并修复VC++运行库（包含 .NET Runtime 检测）" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. DirectX修复" -ForegroundColor Yellow
    Write-Host "     - 检测并修复DirectX组件" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. 系统DLL修复" -ForegroundColor Yellow
    Write-Host "     - 检测并修复系统核心DLL" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  5. 执行全部修复" -ForegroundColor Yellow
    Write-Host "     - 执行所有检测和修复功能" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  0. 退出程序" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

function Get-OSInfo {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $version = [Version]$os.Version
    $arch = "32"
    if ([Environment]::Is64BitOperatingSystem) {
        $arch = "64"
    }
    
    if ($version.Major -eq 10) {
        if ($version.Build -ge 22000) {
            return @{OS="win11"; Arch=$arch}
        }
        return @{OS="win10"; Arch=$arch}
    }
    elseif ($version.Major -eq 6 -and $version.Minor -eq 3) {
        return @{OS="win8"; Arch=$arch}
    }
    elseif ($version.Major -eq 6 -and $version.Minor -eq 1) {
        return @{OS="win7"; Arch=$arch}
    }
    return @{OS="win10"; Arch=$arch}
}

function Test-RegistryKey {
    param([string]$Path, [string]$ValueName = $null)
    try {
        if ($ValueName) {
            $reg = Get-ItemProperty -Path $Path -Name $ValueName -ErrorAction SilentlyContinue
            return $reg -ne $null
        }
        else {
            $reg = Get-Item -Path $Path -ErrorAction SilentlyContinue
            return $reg -ne $null
        }
    }
    catch {
        return $false
    }
}

function Test-VCRedist {
    param([string]$DisplayName)
    $x64Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $x86Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    
    $uninstallKeys = Get-ChildItem -Path $x64Path -ErrorAction SilentlyContinue
    if (-not $uninstallKeys) {
        $uninstallKeys = Get-ChildItem -Path $x86Path -ErrorAction SilentlyContinue
    }
    
    foreach ($key in $uninstallKeys) {
        try {
            $displayName = $key.GetValue("DisplayName")
            if ($displayName -and $displayName -match [regex]::Escape($DisplayName)) {
                return $true
            }
        }
        catch {}
    }
    return $false
}

function Download-File {
    param([string]$Url, [string]$OutputPath, [int]$RetryCount = 2)
    
    $fileName = $Url.Split('/')[-1]
    
    $localDllPath = Join-Path $PSScriptRoot $fileName
    if (Test-Path $localDllPath) {
        Write-Host "  使用本地文件: $fileName" -ForegroundColor Cyan
        Copy-Item -Path $localDllPath -Destination $OutputPath -Force
        Write-Host "  [成功] 本地文件复制完成" -ForegroundColor Green
        return $true
    }
    
    Write-Host "  正在下载: $fileName" -ForegroundColor Cyan
    
    $downloadUrls = @(
        "https://dllarchive.com/files/$fileName",
        "https://www.dll-files.com/$fileName/download",
        "https://www.dllme.com/dll/files/$fileName",
        "https://www.dllsite.com/dll/$fileName"
    )
    
    $sourceIndex = 0
    foreach ($downloadUrl in $downloadUrls) {
        $sourceIndex++
        for ($i = 1; $i -le $RetryCount; $i++) {
            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($downloadUrl, $OutputPath)
                $sourceName = $downloadUrl.Split('/')[2]
                Write-Host "  [成功] 源 $sourceIndex ($sourceName) 下载完成" -ForegroundColor Green
                return $true
            }
            catch {
                if ($i -lt $RetryCount) {
                    Write-Host "  [重试] 源 $sourceIndex 下载失败，重试第 $i 次..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                }
                else {
                    Write-Host "  [切换] 源 $sourceIndex 失败，尝试下一个源..." -ForegroundColor Yellow
                    break
                }
            }
        }
    }
    
    Write-Host "  [失败] 所有源都无法访问" -ForegroundColor Red
    Write-Host "  原始链接: $Url" -ForegroundColor Gray
    return $false
}

function Install-VCRedist {
    param([string]$Path, [string]$Arguments)
    try {
        Write-Host "正在安装..." -ForegroundColor Gray
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Path
        $psi.Arguments = $Arguments
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        $process = [System.Diagnostics.Process]::Start($psi)
        $process.WaitForExit()
        
        if ($process.ExitCode -eq 0) {
            Write-Host "安装成功" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "安装失败，退出码: $($process.ExitCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "安装错误: $_" -ForegroundColor Red
        return $false
    }
}

function Write-ProgressBar {
    param([int]$Current, [int]$Total, [string]$Label)
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 30
    $filledLength = [math]::Round(($Current / $Total) * $barLength)
    $emptyLength = $barLength - $filledLength
    
    $progressBar = "[" + ("=" * $filledLength) + (" " * $emptyLength) + "]"
    Write-Host "$progressBar $percent% - $Label" -ForegroundColor Cyan
}

function Scan-VCRedist {
    param([switch]$Fix)
    
    Write-Host ""
    Write-Host "[运行库检测]" -ForegroundColor Yellow
    
    $osInfo = Get-OSInfo
    $jsonFile = Join-Path (Join-Path $jsonDir "VCDirectxJson") "VC_Scan_$($osInfo.Arch).json"
    
    if (-not (Test-Path $jsonFile)) {
        Write-Host "未找到配置文件: $jsonFile" -ForegroundColor Red
        return @()
    }
    
    $vcList = Get-Content $jsonFile -Raw | ConvertFrom-Json
    $missingList = @()
    $totalCount = $vcList.Count
    $currentCount = 0
    
    foreach ($vc in $vcList) {
        $currentCount++
        $installed = Test-VCRedist -DisplayName $vc.DISPLAYNAME
        
        if ($installed) {
            Write-Host "[已安装] $($vc.DISPLAYVERIONS)" -ForegroundColor Green
        }
        else {
            Write-Host "[缺失] $($vc.DISPLAYVERIONS)" -ForegroundColor Red
            $missingList += $vc
            
            if ($Fix) {
                Write-ProgressBar -Current $currentCount -Total $totalCount -Label "正在修复: $($vc.DISPLAYVERIONS)"
                $fileName = $vc.DOWNLOAD.Split('/')[-1].Trim()
                $downloadPath = Join-Path $downloadDir $fileName
                
                Write-Host "  正在下载..." -ForegroundColor Gray
                if (Download-File -Url $vc.DOWNLOAD -OutputPath $downloadPath) {
                    Write-Host "  正在安装..." -ForegroundColor Gray
                    Install-VCRedist -Path $downloadPath -Arguments $vc.COMMANDLINE
                    Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "[.NET Runtime 检测]" -ForegroundColor Yellow
    
    $dotNetPaths = @(
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\NET Framework Setup\NDP\v4\Full"
    )
    
    foreach ($path in $dotNetPaths) {
        if (Test-Path $path) {
            $version = (Get-ItemProperty -Path $path).Release
            if ($version) {
                $displayVersion = ""
                switch ($version) {
                    { $_ -ge 533320 } { $displayVersion = ".NET Framework 4.8.1" }
                    { $_ -ge 528040 } { $displayVersion = ".NET Framework 4.8" }
                    { $_ -ge 461808 } { $displayVersion = ".NET Framework 4.7.2" }
                    { $_ -ge 461308 } { $displayVersion = ".NET Framework 4.7.1" }
                    { $_ -ge 460798 } { $displayVersion = ".NET Framework 4.7" }
                    { $_ -ge 394802 } { $displayVersion = ".NET Framework 4.6.2" }
                    { $_ -ge 394254 } { $displayVersion = ".NET Framework 4.6.1" }
                    { $_ -ge 393295 } { $displayVersion = ".NET Framework 4.6" }
                    { $_ -ge 379893 } { $displayVersion = ".NET Framework 4.5.2" }
                    { $_ -ge 378675 } { $displayVersion = ".NET Framework 4.5.1" }
                    { $_ -ge 378389 } { $displayVersion = ".NET Framework 4.5" }
                    default { $displayVersion = ".NET Framework 4.x (Unknown)" }
                }
                Write-Host "[已安装] $displayVersion" -ForegroundColor Green
            }
        }
    }
    
    $dotNetCorePaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    
    foreach ($path in $dotNetCorePaths) {
        if (Test-Path $path) {
            $items = Get-ChildItem $path
            foreach ($item in $items) {
                $props = Get-ItemProperty -Path $item.PSPath
                $displayName = $props.DisplayName
                if ($displayName -and ($displayName -match "Microsoft \.NET|Microsoft Windows Desktop Runtime|Microsoft ASP\.NET Core")) {
                    Write-Host "[已安装] $displayName" -ForegroundColor Green
                }
            }
        }
    }
    
    return $missingList
}

function Scan-DirectX {
    param([switch]$Fix)
    
    Write-Host ""
    Write-Host "[DirectX检测]" -ForegroundColor Yellow
    
    $osInfo = Get-OSInfo
    $jsonFile = Join-Path (Join-Path $jsonDir "VCDirectxJson") "DirectX_$($osInfo.Arch).json"
    
    if (-not (Test-Path $jsonFile)) {
        Write-Host "未找到配置文件: $jsonFile" -ForegroundColor Red
        return @()
    }
    
    $dxList = Get-Content $jsonFile -Raw | ConvertFrom-Json
    $missingList = @()
    $totalCount = $dxList.Count
    $currentCount = 0
    
    foreach ($dx in $dxList) {
        $currentCount++
        $fileName = $dx.FILEPATH.Split('\')[-1]
        Write-Host "[检测] $($dx.DISPLAYVERIONS) - $fileName" -ForegroundColor Cyan
        
        $systemPath = Join-Path (Join-Path $env:SystemRoot "System32") $fileName
        if (-not (Test-Path $systemPath)) {
            Write-Host "[缺失] $fileName" -ForegroundColor Red
            $missingList += $dx
            
            if ($Fix) {
                Write-ProgressBar -Current $currentCount -Total $totalCount -Label "正在修复: $fileName"
                Write-Host "  正在下载..." -ForegroundColor Gray
                
                $downloadUrl = $dx.DOWNLOADDLL
                if (-not $downloadUrl) {
                    $downloadUrl = $dx.DOWNLOAD
                }
                
                $downloadPath = Join-Path $downloadDir $fileName
                
                if (Download-File -Url $downloadUrl -OutputPath $downloadPath) {
                    Write-Host "  正在复制到系统目录..." -ForegroundColor Gray
                    try {
                        Copy-Item -Path $downloadPath -Destination $systemPath -Force
                        Write-Host "  修复成功" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "  复制失败: $_" -ForegroundColor Red
                    }
                    Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
        else {
            Write-Host "[正常] $fileName" -ForegroundColor Green
        }
    }
    
    if ($Fix -and $missingList.Count -gt 0) {
        Write-Host "DirectX修复完成" -ForegroundColor Green
    }
    
    return $missingList
}

function Scan-SystemDLL {
    param([switch]$Fix)
    
    Write-Host ""
    Write-Host "[系统DLL检测]" -ForegroundColor Yellow
    Write-Host "注意: 正在跳过不常用的硬件驱动和键盘布局文件..." -ForegroundColor Gray
    
    $osInfo = Get-OSInfo
    $jsonFile = Join-Path (Join-Path $jsonDir "SystemDllJson") "SystemDll_$($osInfo.OS)_$($osInfo.Arch).json"
    
    if (-not (Test-Path $jsonFile)) {
        Write-Host "未找到配置文件: $jsonFile" -ForegroundColor Red
        return @()
    }
    
    $dllList = Get-Content $jsonFile -Raw | ConvertFrom-Json
    $missingList = @()
    $skippedCount = 0
    
    $skipPatterns = @(
        "^kbd.*\.dll$",
        "^kbd.*\.sys$",
        "^acpi.*\.sys$",
        "^amd.*\.sys$",
        "^intel.*\.sys$",
        "^nv.*\.sys$",
        "^ati.*\.sys$",
        "^nvidia.*\.sys$",
        "^vmware.*\.sys$",
        "^virtualbox.*\.sys$"
    )
    
    foreach ($dll in $dllList) {
        $fileName = $dll.FILENAME.ToLower()
        $skip = $false
        
        foreach ($pattern in $skipPatterns) {
            if ($fileName -match $pattern) {
                $skip = $true
                $skippedCount++
                break
            }
        }
        
        if ($skip) {
            continue
        }
        
        $systemPath = Join-Path (Join-Path $env:SystemRoot "System32") $dll.FILENAME
        if (-not (Test-Path $systemPath)) {
            Write-Host "[缺失] $($dll.FILENAME)" -ForegroundColor Red
            $missingList += $dll
            
            if ($Fix) {
                Write-Host "  正在下载..." -ForegroundColor Gray
                
                $downloadPath = Join-Path $downloadDir $dll.FILENAME
                
                if (Download-File -Url $dll.DOWNLOAD -OutputPath $downloadPath) {
                    Write-Host "  正在复制到系统目录..." -ForegroundColor Gray
                    try {
                        Copy-Item -Path $downloadPath -Destination $systemPath -Force
                        Write-Host "  修复成功" -ForegroundColor Green
                    } catch {
                        Write-Host "  复制失败: $_" -ForegroundColor Red
                    }
                    Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            Write-Host "[正常] $($dll.FILENAME)" -ForegroundColor Green
        }
    }
    
    Write-Host "已跳过 $skippedCount 个不常用文件（硬件驱动/键盘布局等）" -ForegroundColor Gray
    
    return $missingList
}

function Full-Scan {
    param([switch]$Fix)
    
    Write-MenuHeader "全面体检"
    Write-Host "正在进行系统全面检测..." -ForegroundColor Yellow
    
    $vcMissing = Scan-VCRedist
    $dxMissing = Scan-DirectX
    $dllMissing = Scan-SystemDLL
    
    Write-Host ""
    Write-Host "检测完成！" -ForegroundColor Cyan
    
    $vcColor = if ($vcMissing.Count -eq 0) { "Green" } else { "Red" }
    $dxColor = if ($dxMissing.Count -eq 0) { "Green" } else { "Red" }
    $dllColor = if ($dllMissing.Count -eq 0) { "Green" } else { "Red" }
    
    Write-Host "运行库缺失: $($vcMissing.Count) 个" -ForegroundColor $vcColor
    Write-Host "DirectX缺失: $($dxMissing.Count) 个" -ForegroundColor $dxColor
    Write-Host "系统DLL缺失: $($dllMissing.Count) 个" -ForegroundColor $dllColor
    
    if ($Fix) {
        Write-Host ""
        Write-Host "开始修复所有问题..." -ForegroundColor Yellow
        Scan-VCRedist -Fix
        Scan-DirectX -Fix
        Scan-SystemDLL -Fix
        Write-Host ""
        Write-Host "全部修复完成！" -ForegroundColor Green
    }
    
    return (@($vcMissing) + @($dxMissing) + @($dllMissing)).Count
}

function Run-FullScan {
    Write-MenuHeader "全面体检"
    $count = Full-Scan
    if (-not $Auto) {
        Write-Host ""
        Write-Host "按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Run-VCRedistFix {
    Write-MenuHeader "运行库修复"
    Scan-VCRedist -Fix
    if (-not $Auto) {
        Write-Host ""
        Write-Host "按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Run-DirectXFix {
    Write-MenuHeader "DirectX修复"
    Scan-DirectX -Fix
    if (-not $Auto) {
        Write-Host ""
        Write-Host "按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Run-SystemDLLFix {
    Write-MenuHeader "系统DLL修复"
    Scan-SystemDLL -Fix
    if (-not $Auto) {
        Write-Host ""
        Write-Host "按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Run-AllFix {
    Write-MenuHeader "执行全部修复"
    Full-Scan -Fix
    if (-not $Auto) {
        Write-Host ""
        Write-Host "按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

if ($Mode) {
    switch ($Mode.ToLower()) {
        "scan" { Run-FullScan }
        "vcrepair" { Run-VCRedistFix }
        "dx" { Run-DirectXFix }
        "sysdll" { Run-SystemDLLFix }
        "all" { Run-AllFix }
        default {
            Write-Host "未知的模式: $Mode" -ForegroundColor Red
            Write-Host "可用模式: scan, vcrepair, dx, sysdll, all" -ForegroundColor Yellow
        }
    }
    exit
}

do {
    Show-Menu
    $choice = Read-Host "请输入选项 (0-5)"

    switch ($choice) {
        "1" { Run-FullScan }
        "2" { Run-VCRedistFix }
        "3" { Run-DirectXFix }
        "4" { Run-SystemDLLFix }
        "5" { Run-AllFix }
        "0" {
            Write-Host ""
            Write-Host "感谢使用DLL修复工具！" -ForegroundColor Green
            Write-Host ""
            exit
        }
        default {
            Write-Host ""
            Write-Host "无效的选项，请重新选择！" -ForegroundColor Red
            Write-Host ""
            Start-Sleep -Seconds 2
        }
    }
} while ($true)