<#
.SYNOPSIS
    硬件信息查询脚本 - CPU/GPU 使用率、内存实时使用率、硬盘详细信息
.DESCRIPTION
    自动获取管理员权限，通过 WMI/性能计数器/DXDiag 等获取硬件信息。
    显存大小通过 DXDiag 获取专用显存（MB），避免溢出或共享内存干扰。
.NOTES
    需要 PowerShell 3.0+，Windows 7+ (建议 64 位系统)
#>

# 自动提权（强制使用 64 位 PowerShell，保证 WMI 获取其他信息时不受 32 位限制）
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "正在获取管理员权限（64 位）..." -ForegroundColor Yellow
    $powerShellPath = "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe"
    if (-not (Test-Path $powerShellPath)) {
        $powerShellPath = "powershell.exe"
    }
    Start-Process -FilePath $powerShellPath -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "已获取管理员权限（64 位环境），开始查询硬件信息..." -ForegroundColor Green
Write-Host ""

# 头部信息
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        Windows 硬件系统信息查询" -ForegroundColor Cyan
Write-Host "查询时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "计算机名: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "操作系统: $((Get-CimInstance Win32_OperatingSystem).Caption)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ================== 1. CPU 信息 + 使用率 + 温度 ==================
Write-Host "中央处理器 (CPU)：" -ForegroundColor Yellow
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$archName = switch ($cpu.Architecture) {
    0 { "x86" } 1 { "MIPS" } 2 { "Alpha" } 3 { "PowerPC" } 5 { "ARM" }
    6 { "Itanium" } 9 { "x64" } 10 { "x64" } 12 { "ARM64" }
    default { "未知 ($($cpu.Architecture))" }
}
Write-Host "  名称           : $($cpu.Name.Trim())"
Write-Host "  核心数         : $($cpu.NumberOfCores)"
Write-Host "  逻辑处理器数   : $($cpu.NumberOfLogicalProcessors)"
Write-Host "  最大时钟频率   : $($cpu.MaxClockSpeed) MHz"
Write-Host "  架构           : $archName"
Write-Host "  二级缓存       : $($cpu.L2CacheSize) KB"
Write-Host "  三级缓存       : $($cpu.L3CacheSize) KB"
try {
    $cpuCounter = Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction Stop
    $cpuPercent = [math]::Round($cpuCounter.CounterSamples.CookedValue, 2)
    Write-Host "  实时使用率     : $cpuPercent%"
} catch {
    Write-Host "  实时使用率     : 无法获取" -ForegroundColor Gray
}
$cpuTemp = $null
try {
    $thermalZones = Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    if ($thermalZones) {
        $cpuTemp = [math]::Round(($thermalZones.CurrentTemperature - 2732) / 10, 1)
    } else {
        $tempProbe = Get-CimInstance -ClassName Win32_TemperatureProbe -ErrorAction SilentlyContinue | Where-Object { $_.CurrentReading -ne $null }
        if ($tempProbe) { $cpuTemp = [math]::Round($tempProbe.CurrentReading, 1) }
    }
    if ($cpuTemp) { Write-Host "  实时温度       : $cpuTemp°C" }
    else { Write-Host "  实时温度       : 无法获取 (硬件不支持)" -ForegroundColor Gray }
} catch {
    Write-Host "  实时温度       : 无法获取" -ForegroundColor Gray
}
Write-Host ""

# ================== 2. 内存信息 + 使用率 ==================
Write-Host "内存 (RAM)：" -ForegroundColor Yellow
$totalMemory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Host "  总内存         : $($totalMemory) GB"
$memorySlots = Get-CimInstance -ClassName Win32_PhysicalMemory
if ($memorySlots) {
    $slotIndex = 1
    foreach ($mem in $memorySlots) {
        $capacityGB = [math]::Round($mem.Capacity / 1GB, 2)
        $speed = if ($mem.Speed) { "$($mem.Speed) MHz" } else { "未知" }
        $memType = switch ($mem.MemoryType) {
            20 { "DDR" } 21 { "DDR2" } 22 { "DDR2 FB-DIMM" } 24 { "DDR3" }
            26 { "DDR4" } 27 { "DDR5" } default { "$($mem.MemoryType)" }
        }
        $manufacturer = if ($mem.Manufacturer) { $mem.Manufacturer.Trim() } else { "未知厂商" }
        Write-Host "  插槽 $slotIndex  : $capacityGB GB  $memType  $speed  厂商: $manufacturer"
        $slotIndex++
    }
} else {
    Write-Host "  无法获取内存插槽详细信息" -ForegroundColor Gray
}
$usedMem = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
$totalMemKB = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize
$memPercent = if ($totalMemKB -gt 0) { [math]::Round(($usedMem / $totalMemKB) * 100, 2) } else { 0 }
Write-Host "  实时使用率     : $memPercent%"
Write-Host ""

# ================== 3. 存储设备信息 ==================
Write-Host "存储设备信息：" -ForegroundColor Yellow
$disks = Get-CimInstance Win32_DiskDrive
foreach ($disk in $disks) {
    $sizeGB = [math]::Round($disk.Size/1GB,2)
    Write-Host "  型号    : $($disk.Model.Trim())"
    Write-Host "  接口类型: $($disk.InterfaceType)"
    Write-Host "  总容量  : $sizeGB GB"
    $partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition
    foreach ($part in $partitions) {
        $volumes = Get-CimAssociatedInstance -InputObject $part -ResultClassName Win32_LogicalDisk
        foreach ($vol in $volumes) {
            $freeGB = [math]::Round($vol.FreeSpace/1GB,2)
            $usedGB = [math]::Round(($vol.Size-$vol.FreeSpace)/1GB,2)
            Write-Host "    $($vol.DeviceID) : 已用 $usedGB GB / 剩余 $freeGB GB"
        }
    }
    Write-Host ""
}

# ================== 4. 显卡信息 (DXDiag 专用显存，单位 MB) ==================
Write-Host "显示适配器 (GPU)：" -ForegroundColor Yellow

# 定义 DXDiag 提取专用显存的函数（返回 MB 值）
function Get-DedicatedVRAMFromDXDiag {
    $dxdiagFile = "$env:TEMP\dxdiag_temp_$(Get-Random).txt"
    try {
        Start-Process -FilePath "dxdiag.exe" -ArgumentList "/whql:off /t `"$dxdiagFile`"" -NoNewWindow -Wait
        if (-not (Test-Path $dxdiagFile)) { return $null }
        $dxContent = Get-Content $dxdiagFile -Encoding UTF8 -Raw

        # 提取 Display Devices 区块（中/英）
        $section = $null
        if ($dxContent -match "(?si)Display Devices\s*-+\s*(.*?)(?=\r?\n\s*\r?\n\s*\w+\s*:|\Z)") {
            $section = $Matches[1]
        } elseif ($dxContent -match "(?si)显示设备\s*-+\s*(.*?)(?=\r?\n\s*\r?\n\s*\w+\s*:|\Z)") {
            $section = $Matches[1]
        }
        if (-not $section) { return $null }

        # 提取显卡名称（用于展示）
        $nameMatch = [regex]::Match($section, "(?:Card name|显示卡|显卡名称|顯示卡)\s*:\s*(.+?)(?:\r?\n|$)")
        $gpuName = if ($nameMatch.Success) { $nameMatch.Groups[1].Value.Trim() } else { "未知" }

        # 精确提取专用显存（MB）：Dedicated Memory / 专用视频内存 / 專用視訊記憶體
        $dedicatedMatch = [regex]::Match($section, "(?:Dedicated Memory|专用视频内存|專用視訊記憶體)\s*:\s*(\d+)\s*MB", 'IgnoreCase')
        if ($dedicatedMatch.Success) {
            $vramMB = [int]$dedicatedMatch.Groups[1].Value
            return [PSCustomObject]@{
                Name = $gpuName
                VRAM = $vramMB  # 直接返回 MB
            }
        }
        # 无专用显存字段（集成显卡）
        return [PSCustomObject]@{
            Name = $gpuName
            VRAM = $null
        }
    } catch {
        return $null
    } finally {
        if (Test-Path $dxdiagFile) { Remove-Item $dxdiagFile -Force -ErrorAction SilentlyContinue }
    }
}

# 获取主显卡信息（使用 DXDiag）
$gpuInfo = Get-DedicatedVRAMFromDXDiag

if ($gpuInfo) {
    Write-Host "  名称        : $($gpuInfo.Name)"
    if ($gpuInfo.VRAM) {
        Write-Host "  显存        : $($gpuInfo.VRAM) MB (专用)"
    } else {
        Write-Host "  显存        : 未检测到专用显存 (可能为核显或旧显卡)" -ForegroundColor Gray
    }
    # 驱动版本和分辨率仍从 WMI 获取（补充信息，不影响显存）
    $gpuWMI = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Mirror|Remote|Virtual|Indirect Display' } | Select-Object -First 1
    if ($gpuWMI) {
        Write-Host "  驱动版本    : $($gpuWMI.DriverVersion)"
        if ($gpuWMI.CurrentHorizontalResolution -and $gpuWMI.CurrentVerticalResolution) {
            Write-Host "  当前分辨率  : $($gpuWMI.CurrentHorizontalResolution) x $($gpuWMI.CurrentVerticalResolution)"
        }
    }
} else {
    Write-Host "  无法通过 DXDiag 获取显卡信息，尝试 WMI 名称..." -ForegroundColor Gray
    $gpuWMI = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Mirror|Remote|Virtual|Indirect Display' } | Select-Object -First 1
    if ($gpuWMI) {
        Write-Host "  名称        : $($gpuWMI.Name.Trim())"
        Write-Host "  显存        : 无法获取 (DXDiag 失败)" -ForegroundColor Gray
        Write-Host "  驱动版本    : $($gpuWMI.DriverVersion)"
    } else {
        Write-Host "  未检测到显卡" -ForegroundColor Gray
    }
}

# GPU 使用率独立检测（性能计数器或 nvidia-smi 只用于使用率，不参与显存）
$gpuUtil = $null
try {
    $gpuCounters = Get-Counter -ListSet "GPU Engine" -ErrorAction SilentlyContinue
    if ($gpuCounters) {
        $counterPaths = $gpuCounters.CounterPaths | Where-Object { $_ -like "*engtype_3D*" -or $_ -like "*utilization*" }
        if ($counterPaths) {
            $samples = Get-Counter -Counter $counterPaths -ErrorAction SilentlyContinue
            $utils = @()
            foreach ($sample in $samples.CounterSamples) {
                if ($sample.CookedValue -gt 0 -and $sample.CookedValue -le 100) {
                    $utils += $sample.CookedValue
                }
            }
            if ($utils.Count -gt 0) {
                $gpuUtil = [math]::Round(($utils | Measure-Object -Average).Average, 2)
            }
        }
    }
    if (-not $gpuUtil) {
        $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvidiaSmi) {
            $output = & nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>$null
            if ($output) {
                $gpuUtil = [math]::Round([double]$output.Trim(), 2)
            }
        }
    }
} catch { }
if ($gpuUtil) { Write-Host "  GPU 实时使用率 : $gpuUtil%" -ForegroundColor Cyan }
else { Write-Host "  GPU 实时使用率 : 无法获取" -ForegroundColor Gray }
Write-Host ""

# ================== 5. 显示设备信息（显示器） ==================
Write-Host "显示设备：" -ForegroundColor Yellow
$monitors = @()
try {
    $edidMonitors = Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue
    if ($edidMonitors) {
        foreach ($edid in $edidMonitors) {
            $manu = if ($edid.ManufacturerName) { [System.Text.Encoding]::ASCII.GetString($edid.ManufacturerName -ne 0) } else { "未知" }
            $product = if ($edid.ProductCodeID) { [System.Text.Encoding]::ASCII.GetString($edid.ProductCodeID -ne 0) } else { "" }
            $friendly = if ($edid.UserFriendlyName) { [System.Text.Encoding]::ASCII.GetString($edid.UserFriendlyName -ne 0) } else { "" }
            $serial = if ($edid.SerialNumberID) { [System.Text.Encoding]::ASCII.GetString($edid.SerialNumberID -ne 0) } else { "" }
            $model = if ($friendly) { $friendly } elseif ($product) { $product } else { "未知型号" }
            Write-Host "  型号        : $model"
            if ($manu -ne "未知") { Write-Host "  制造商      : $manu" }
            if ($serial) { Write-Host "  序列号      : $serial" }
            Write-Host ""
            $monitors += $model
        }
    }
    if ($monitors.Count -eq 0) {
        $dtMonitors = Get-CimInstance -ClassName Win32_DesktopMonitor -ErrorAction SilentlyContinue
        foreach ($dt in $dtMonitors) {
            if ($dt.Name) {
                Write-Host "  型号        : $($dt.Name)"
                Write-Host ""
                $monitors += $dt.Name
            }
        }
    }
    if ($monitors.Count -eq 0) {
        Write-Host "  无法检测到显示器型号（EDID 信息缺失或未提供）" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    Write-Host "  显示设备查询失败: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
}

# ================== 6. 主板/BIOS 信息 ==================
Write-Host "主板 / BIOS：" -ForegroundColor Yellow
$baseboard = Get-CimInstance Win32_BaseBoard
Write-Host "  制造商   : $($baseboard.Manufacturer)"
Write-Host "  型号     : $($baseboard.Product)"
Write-Host "  序列号   : $($baseboard.SerialNumber)"
Write-Host "  版本     : $($baseboard.Version)"
$bios = Get-CimInstance Win32_BIOS
$biosDate = $bios.ReleaseDate
if ($biosDate -is [datetime]) { $biosDateStr = $biosDate.ToString("yyyy-MM-dd") }
else { $biosDateStr = $biosDate -replace '(\d{4})(\d{2})(\d{2}).*','$1-$2-$3' }
Write-Host "  BIOS版本 : $($bios.Name)"
Write-Host "  BIOS日期 : $biosDateStr"
Write-Host ""

# ================== 7. 系统信息摘要 + 激活 ==================
Write-Host "系统信息摘要：" -ForegroundColor Yellow
$os = Get-CimInstance Win32_OperatingSystem
$installDate = $os.InstallDate -replace '^(\d{4})(\d{2})(\d{2}).*','$1-$2-$3'
$lastBoot = $os.LastBootUpTime -replace '^(\d{4})(\d{2})(\d{2}).*','$1-$2-$3'
Write-Host "  系统版本 : $($os.Caption)"
Write-Host "  版本号   : $($os.Version)"
Write-Host "  安装日期 : $installDate"
Write-Host "  上次启动 : $lastBoot"

try {
    $license = Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey is not null and ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" -ErrorAction Stop
    $active = $license | Where-Object { $_.LicenseStatus -eq 1 } | Select-Object -First 1
    if ($active) {
        Write-Host "  激活状态 : 已激活 (密钥后缀: $($active.PartialProductKey))"
    } else {
        $status = ($license | Select-Object -First 1).LicenseStatus
        if ($status -eq 0) { Write-Host "  激活状态 : 未激活" }
        elseif ($status -eq 2) { Write-Host "  激活状态 : 已过期/失效" }
        else { Write-Host "  激活状态 : 状态未知" }
    }
} catch {
    Write-Host "  激活状态 : 无法获取" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "查询完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "`n按任意键退出..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")