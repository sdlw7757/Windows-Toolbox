# 自动请求管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $powerShellPath = if (Test-Path "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe") {
        "$env:SystemRoot\SysNative\WindowsPowerShell\v1.0\powershell.exe"
    } else {
        "powershell.exe"
    }
    Start-Process -FilePath $powerShellPath -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

chcp 65001 > $null 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'

$ScriptDir = Split-Path -Parent $PSCommandPath

do {
    [Console]::Clear()
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "               Windows 工具箱一键启动                 " -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 深度清理 (扫描/删除 Temp、缓存、日志等)" -ForegroundColor Yellow
    Write-Host "  [2] 获取用户信息 (用户名/账户类型/内外网IP/归属地/IPv6)" -ForegroundColor Yellow
    Write-Host "  [3] KMS 激活 (自动激活 Windows/Office)" -ForegroundColor Yellow
    Write-Host "  [4] 重置本地用户密码" -ForegroundColor Yellow
    Write-Host "  [5] SMB 共享工具 (启用 SMB 并设置共享)" -ForegroundColor Yellow
    Write-Host "  [6] SSD 优化 (TRIM/禁用休眠/索引等)" -ForegroundColor Yellow
    Write-Host "  [7] 禁用系统还原 (关闭还原点/删除历史)" -ForegroundColor Yellow
    Write-Host "  [8] 硬件检测 (完整版：CPU/GPU/内存/硬盘/主板/温度等)" -ForegroundColor Yellow
    Write-Host "  [0] 退出工具箱" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    $choice = Read-Host "请输入选项数字并按回车"

    switch ($choice) {
        "1" {
            Write-Host "`n>>> 启动深度清理引擎 V1..." -ForegroundColor Cyan
            $script:foundTargets = @()
            $script:totalScanned = 0
            $targetKeywords = "Temp|Cache|CrashDumps|LogFiles"
            $baseScanPath = $env:USERPROFILE
            function Invoke-RealTimeScan($CurrentPath) {
                try {
                    $dirs = Get-ChildItem -Path $CurrentPath -Directory -Force -ErrorAction SilentlyContinue
                    foreach ($dir in $dirs) {
                        $script:totalScanned++
                        Write-Host " [Scan] $($dir.FullName)" -ForegroundColor DarkGray
                        if ($dir.Name -match $targetKeywords) {
                            Write-Host " [>>>] TARGET LOCKED: $($dir.FullName)" -ForegroundColor Yellow
                            $script:foundTargets += $dir
                        }
                        Invoke-RealTimeScan $dir.FullName
                    }
                } catch {}
            }
            Invoke-RealTimeScan $baseScanPath
            $systemJunkPaths = @("$env:TEMP", "$env:WINDIR\Temp", "$env:WINDIR\Prefetch", "$env:WINDIR\SoftwareDistribution\Download")
            foreach ($sp in $systemJunkPaths) {
                $script:totalScanned++
                if (Test-Path $sp) {
                    $item = Get-Item $sp
                    Write-Host " [>>>] SYSTEM TARGET: $($item.FullName)" -ForegroundColor Red
                    $script:foundTargets += $item
                }
            }
            if ($script:foundTargets.Count -eq 0) {
                Write-Host "`n[V] 未找到垃圾文件夹。" -ForegroundColor Green
            } else {
                $formatted = "{0:N0}" -f $script:totalScanned
                Write-Host "`n[*] 扫描完成！共扫描 $formatted 个路径，锁定 $($script:foundTargets.Count) 个垃圾区域。" -ForegroundColor Green
                $confirm = Read-Host ">>> 确认立即清理？[Y/n] (默认 Y)"
                if ($confirm -eq "" -or $confirm -match "^[Yy]$") {
                    Write-Host "`n[*] 正在清理..." -ForegroundColor Cyan
                    $totalFreed = 0
                    foreach ($folder in $script:foundTargets) {
                        Write-Host "  -> 清理: $($folder.FullName)" -ForegroundColor DarkGray
                        $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                        if ($null -ne $size) { $totalFreed += $size }
                        Remove-Item -Path "$($folder.FullName)\*" -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    $freedMB = [math]::Round($totalFreed / 1MB, 2)
                    $freedGB = [math]::Round($totalFreed / 1GB, 2)
                    Write-Host "`n[OK] 清理完成！" -ForegroundColor Green
                    if ($totalFreed -gt 1GB) { Write-Host "已释放: $freedGB GB" -ForegroundColor Yellow }
                    elseif ($freedMB -gt 0) { Write-Host "已释放: $freedMB MB" -ForegroundColor Yellow }
                    else { Write-Host "系统已优化，未释放额外空间。" -ForegroundColor Gray }
                } else { Write-Host "已取消清理。" -ForegroundColor Gray }
            }
            Read-Host "按 Enter 返回主菜单"
        }

        "2" {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host "                   用户信息查询                          " -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host ""

            # 本地账户信息
            try {
                $CurrentLoggedUser = Get-LocalUser -Name $env:USERNAME
                $accountType = $CurrentLoggedUser.PrincipalSource
                $accountNote = if ($accountType -ne "Local") { "Microsoft 关联账户" } else { "本地账户" }
            } catch {
                $accountType = "未知"
                $accountNote = "无法判断"
            }

            # 内网 IPv4（过滤虚拟/回环）
            $innerIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
                $_.IPAddress -notmatch "^127\." -and
                $_.IPAddress -notmatch "^169\.254\." -and
                $_.InterfaceAlias -notlike "*Loopback*" -and
                $_.InterfaceAlias -notlike "*Virtual*" -and
                $_.InterfaceAlias -notlike "*Hyper-V*"
            } | Select-Object -ExpandProperty IPAddress
            if (-not $innerIPs) { $innerIPs = @("无内网IPv4") }
            $innerIPDisplay = ($innerIPs | Sort-Object) -join " / "

            # ========== 新增：内网 IPv6 地址 ==========
            $innerIPv6s = Get-NetIPAddress -AddressFamily IPv6 | Where-Object {
                # 过滤回环 (::1) 和链路本地 (fe80::/10)
                $_.IPAddress -notmatch "^::1$" -and
                $_.IPAddress -notmatch "^fe80:" -and
                $_.InterfaceAlias -notlike "*Loopback*" -and
                $_.InterfaceAlias -notlike "*Virtual*" -and
                $_.InterfaceAlias -notlike "*Hyper-V*" -and
                $_.IPAddress -notmatch "^::"
            } | Select-Object -ExpandProperty IPAddress
            if (-not $innerIPv6s) { $innerIPv6s = @("无IPv6地址") }
            $innerIPv6Display = ($innerIPv6s | Sort-Object) -join " / "
            # ========================================

            # 外网 IP + 归属地（优先 ipinfo.io，备用 ip-api.com）
            $outerIP = $null
            $geoCountry = $null
            $geoCity = $null
            $geoIsp = $null
            $geoRaw = $null

            Write-Host "正在查询外网信息，请稍候..." -ForegroundColor Cyan
            # 方法 A：ipinfo.io（一次获取所有信息）
            try {
                $ipinfo = Invoke-RestMethod -Uri "https://ipinfo.io/json" -TimeoutSec 5 -ErrorAction Stop
                if ($ipinfo.ip) {
                    $outerIP = $ipinfo.ip
                    $geoCountry = $ipinfo.country
                    $geoCity = $ipinfo.city
                    $geoIsp = $ipinfo.org
                    Write-Host "使用 ipinfo.io 查询成功" -ForegroundColor Green
                } else {
                    throw "No IP"
                }
            } catch {
                Write-Host "ipinfo.io 失败，切换备用接口..." -ForegroundColor Yellow
                # 方法 B：备用方案（先获取 IP，再查归属地）
                try {
                    $outerIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 5).Content.Trim()
                } catch {
                    try {
                        $outerIP = (Invoke-WebRequest -Uri "https://icanhazip.com" -UseBasicParsing -TimeoutSec 5).Content.Trim()
                    } catch {
                        $outerIP = "无法获取外网IP"
                    }
                }
                if ($outerIP -and $outerIP -notmatch "无法获取") {
                    try {
                        $geoResponse = Invoke-RestMethod -Uri "http://ip-api.com/json/$outerIP?lang=zh-CN" -TimeoutSec 5
                        if ($geoResponse.status -eq "success") {
                            $geoCountry = $geoResponse.country
                            $geoCity = $geoResponse.city
                            $geoIsp = $geoResponse.isp
                        } else {
                            $geoRaw = "查询失败"
                        }
                    } catch {
                        $geoRaw = "归属地查询失败"
                    }
                } else {
                    $geoRaw = "无外网IP，无法查询归属地"
                }
            }

            Write-Host ""
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "                      用户信息一览                        " -ForegroundColor Green
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  用户名       : $env:USERNAME"
            Write-Host "  账户类型     : $accountType ($accountNote)"
            Write-Host "  内网 IPv4    : $innerIPDisplay"
            Write-Host "  内网 IPv6    : $innerIPv6Display"
            Write-Host "  外网 IP      : $outerIP"

            if ($geoCountry -or $geoCity -or $geoIsp) {
                Write-Host "  归属地       : $geoCountry $geoCity"
                Write-Host "  运营商       : $geoIsp"
            } elseif ($geoRaw) {
                Write-Host "  归属地       : $geoRaw"
            } else {
                Write-Host "  归属地       : 无法获取"
            }
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""

            Read-Host "按 Enter 返回主菜单"
        }

        "3" {
            Write-Host "`n>>> 启动 KMS 激活工具..." -ForegroundColor Cyan
            $kmsServer = "kms.03k.org"
            Write-Host "使用 KMS 服务器: $kmsServer" -ForegroundColor Yellow

            Write-Host "[1/2] 检测 Windows 版本..." -ForegroundColor Magenta
            $winCaption = (Get-WmiObject -Class Win32_OperatingSystem).Caption
            Write-Host "检测到: $winCaption"
            $winKeys = @(
                @{ Pattern = "Windows 7.*专业版";       Key = "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4" }
                @{ Pattern = "Windows 7.*企业版";       Key = "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH" }
                @{ Pattern = "Windows 8.*专业版";       Key = "NG4HW-VH26C-733KW-K6F98-J8CK4" }
                @{ Pattern = "Windows 8.*企业版";       Key = "NKB3R-R2F8T-3XCDP-7Q2FG-XR2WD" }
                @{ Pattern = "Windows 10.*专业工作站版"; Key = "NRG8B-VKK3Q-CXVCJ-9G2XF-3Q84Y" }
                @{ Pattern = "Windows 10.*专业教育版";   Key = "8PTT6-RNW4C-6V7J2-C2D3X-MHBPB" }
                @{ Pattern = "Windows 10.*教育版";       Key = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2" }
                @{ Pattern = "Windows 10.*企业版";       Key = "NPPR9-FWDCX-D2C8J-H872K-2YT43" }
                @{ Pattern = "Windows 10.*专业版";       Key = "W269N-WFGWX-YVC9B-4J6C9-T83GX" }
                @{ Pattern = "Windows 11.*专业工作站版"; Key = "NRG8B-VKK3Q-CXVCJ-9G2XF-3Q84Y" }
                @{ Pattern = "Windows 11.*专业教育版";   Key = "8PTT6-RNW4C-6V7J2-C2D3X-MHBPB" }
                @{ Pattern = "Windows 11.*教育版";       Key = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2" }
                @{ Pattern = "Windows 11.*企业版";       Key = "NPPR9-FWDCX-D2C8J-H872K-2YT43" }
                @{ Pattern = "Windows 11.*专业版";       Key = "W269N-WFGWX-YVC9B-4J6C9-T83GX" }
                @{ Pattern = "Server 2012 R2.*标准";     Key = "D2N9P-3P6X9-2R39C-7RTCD-MDVJX" }
                @{ Pattern = "Server 2016.*标准";        Key = "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY" }
                @{ Pattern = "Server 2019.*标准|Server 2022.*标准"; Key = "N69G4-B89J2-4G8F4-WWYCC-J464C" }
                @{ Pattern = "Server 2019.*数据中心|Server 2022.*数据中心"; Key = "WMDGN-G9PQG-XVVXX-R3X43-63DFG" }
            )
            $selectedWinKey = $null
            foreach ($e in $winKeys) { if ($winCaption -match $e.Pattern) { $selectedWinKey = $e.Key; break } }
            if (-not $selectedWinKey) { $selectedWinKey = Read-Host "未自动匹配密钥，请输入 Windows GVLK 密钥 (跳过请留空)" }
            if ($selectedWinKey) {
                Start-Process -FilePath "cscript" -ArgumentList "$env:windir\system32\slmgr.vbs /ipk $selectedWinKey" -NoNewWindow -Wait
                Start-Process -FilePath "cscript" -ArgumentList "$env:windir\system32\slmgr.vbs /skms $kmsServer" -NoNewWindow -Wait
                $proc = Start-Process -FilePath "cscript" -ArgumentList "$env:windir\system32\slmgr.vbs /ato" -NoNewWindow -Wait -PassThru
                if ($proc.ExitCode -eq 0) { Write-Host "Windows 激活成功！" -ForegroundColor Green }
                else { Write-Host "Windows 激活失败 (错误代码 $($proc.ExitCode))" -ForegroundColor Red }
            }

            Write-Host "`n[2/2] 检测 Office 批量版本..." -ForegroundColor Magenta
            $officePaths = @(
                "${env:ProgramFiles}\Microsoft Office\Office16",
                "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
                "${env:ProgramFiles}\Microsoft Office\Office15",
                "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
                "${env:ProgramFiles}\Microsoft Office\Office14",
                "${env:ProgramFiles(x86)}\Microsoft Office\Office14"
            )
            $ospp = $null
            foreach ($p in $officePaths) { if (Test-Path "$p\OSPP.VBS") { $ospp = "$p\OSPP.VBS"; break } }
            if (-not $ospp) { Write-Host "未找到 Office 批量版脚本，跳过。" -ForegroundColor Red }
            else {
                $selectedOfficeKey = $null
                $status = & cscript //nologo $ospp /dstatus 2>$null
                $latestProduct = ""
                foreach ($line in $status) {
                    if ($line -match "Product Name: (.+)") { $latestProduct = $Matches[1].Trim() }
                    if ($line -match "Last 5 characters of installed product key: (.+)") {
                        $prodName = $latestProduct
                        if ($prodName -match "2016") { $selectedOfficeKey = "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99" }
                        elseif ($prodName -match "2019") { $selectedOfficeKey = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP" }
                        elseif ($prodName -match "2021") { $selectedOfficeKey = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH" }
                        elseif ($prodName -match "2024") { $selectedOfficeKey = "2TDPW-NDQ7G-FMG99-DXQ7M-TX3T2" }
                        elseif ($prodName -match "2010") { $selectedOfficeKey = "VYBBJ-TRJPB-QFQRF-QFT4D-H3GVB" }
                        elseif ($prodName -match "2013") { $selectedOfficeKey = "YC7DK-G2NP3-2QQC3-J6H88-GVGXT" }
                        if ($prodName -match "Project") { $selectedOfficeKey = "WGT24-HCNMF-FQ7XH-6M8K7-DRTW9" }
                        if ($prodName -match "Visio") { $selectedOfficeKey = "B7N8W-FV3YX-48TMD-8GGG9-7C8XT" }
                    }
                }
                if (-not $selectedOfficeKey) {
                    Write-Host "无法自动识别 Office，请手动选择或输入密钥：" -ForegroundColor Yellow
                    $sel = Read-Host "[1]2016 [2]2019 [3]2021 [4]手动输入 (跳过请留空)"
                    switch ($sel) {
                        "1" { $selectedOfficeKey = "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99" }
                        "2" { $selectedOfficeKey = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP" }
                        "3" { $selectedOfficeKey = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH" }
                        "4" { $selectedOfficeKey = Read-Host "输入密钥" }
                    }
                }
                if ($selectedOfficeKey) {
                    Start-Process -FilePath "cscript" -ArgumentList "$ospp /inpkey:$selectedOfficeKey" -NoNewWindow -Wait
                    Start-Process -FilePath "cscript" -ArgumentList "$ospp /sethst:$kmsServer" -NoNewWindow -Wait
                    $proc = Start-Process -FilePath "cscript" -ArgumentList "$ospp /act" -NoNewWindow -Wait -PassThru
                    if ($proc.ExitCode -eq 0) { Write-Host "Office 激活成功！" -ForegroundColor Green }
                    else { Write-Host "Office 激活失败 (错误代码 $($proc.ExitCode))" -ForegroundColor Red }
                }
            }
            Read-Host "按 Enter 返回主菜单"
        }

        "4" {
            Write-Host "`n>>> 重置本地用户密码..." -ForegroundColor Cyan
            $User = $env:USERNAME
            $Password = Read-Host "为 $User 输入新密码" -AsSecureString
            try {
                Set-LocalUser -Name $User -Password $Password
                Write-Host "成功：用户 [$User] 的密码已更新。" -ForegroundColor Green
            } catch {
                Write-Host "错误：密码更新失败。请确认以管理员身份运行。"
            }
            Read-Host "按 Enter 返回主菜单"
        }

        "5" {
            Write-Host "`n>>> SMB 共享工具..." -ForegroundColor Cyan
            $localSMBPath = Join-Path $ScriptDir "SMB_Share_Tool.cmd"
            $tempPath = "$env:TEMP\SMB_Share_Tool_$(Get-Random).cmd"

            if (Test-Path $localSMBPath) {
                Write-Host "检测到本地脚本，直接运行..." -ForegroundColor Green
                $scriptToRun = $localSMBPath
            } else {
                Write-Host "未找到本地脚本，尝试从 GitHub 下载..." -ForegroundColor Yellow
                try {
                    $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Cotton059/Light-Help/main/SMB_Share_Tool.cmd" -UseBasicParsing
                    Set-Content -Path $tempPath -Value $response.Content
                    Write-Host "下载成功，正在执行..." -ForegroundColor Green
                    $scriptToRun = $tempPath
                } catch {
                    Write-Host "下载失败，无法运行 SMB 共享工具。" -ForegroundColor Red
                    Read-Host "按 Enter 返回主菜单"
                    continue
                }
            }

            Start-Process -FilePath $scriptToRun -Wait
            if ($scriptToRun -eq $tempPath) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
            Write-Host "SMB 共享工具已执行完毕。" -ForegroundColor Cyan
            Read-Host "按 Enter 返回主菜单"
        }

        "6" {
            Write-Host "`n>>> SSD 优化 (执行批处理任务)..." -ForegroundColor Cyan
            $batContent = @'
@echo off
title SSD Optimization
fltmc >nul 2>&1 || ( powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs" & exit /b )
echo 1. 启用 TRIM...
fsutil behavior set DisableDeleteNotify 0
echo 2. 删除磁盘碎片整理计划...
schtasks /delete /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /f >nul 2>&1
echo 3. 禁用休眠...
powercfg -h off
echo 4. 禁用 Windows Search 索引...
sc config WSearch start= disabled >nul 2>&1
net stop WSearch /y >nul 2>&1
echo 5. 禁用 Prefetch 和 Superfetch...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f >nul 2>&1
echo 6. 禁用系统还原...
wmic /namespace:\\root\cimv2 path win32systemrestore set restoreenabled=false >nul 2>&1
echo 7. 禁用卷影复制 (VSS)...
sc config VSS start= disabled >nul 2>&1
net stop VSS /y >nul 2>&1
echo 8. 禁用自动碎片整理...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v OptimizeHardDiskOn /t REG_DWORD /d 0 /f >nul 2>&1
echo 9. 启用写入缓存 (如果可用)...
reg add "HKLM\SYSTEM\CurrentControlSet\Enum\STORAGE\Disk" /v WriteCacheEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo ==============================================
echo [OK] SSD 优化完成！
echo TRIM 已启用，写入减少，SSD 寿命延长，启动更快。
echo ==============================================
pause
'@
            $rand = Get-Random -Maximum 99999999
            $tempBat = "$env:TEMP\SSD_Optimize_$rand.cmd"
            Set-Content -Path $tempBat -Value $batContent -Encoding Default
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c $tempBat" -Wait
            Remove-Item $tempBat -Force
            Read-Host "按 Enter 返回主菜单"
        }

        "7" {
            Write-Host "`n>>> 禁用系统备份与还原..." -ForegroundColor Cyan
            Write-Host "1. 关闭系统还原点创建..."
            Disable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            Write-Host "2. 删除现有还原点..."
            Get-ComputerRestorePoint -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-ComputerRestorePoint -RestorePoint $_.SequenceNumber -ErrorAction SilentlyContinue
            }
            Write-Host "3. 禁用相关服务..."
            @("VSS", "srservice", "BackupRestore") | ForEach-Object { Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue }
            Write-Host "4. 注册表禁止手动开启..."
            $regs = @(
                @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore"; Name = "DisableSR"; Value = 1}
                @{Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"; Name = "DisableConfig"; Value = 1}
                @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\FileHistory"; Name = "Disabled"; Value = 1}
            )
            foreach ($r in $regs) {
                if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }
                Set-ItemProperty -Path $r.Path -Name $r.Name -Value $r.Value -Type DWord -Force -ErrorAction SilentlyContinue
            }
            Write-Host "操作完成！系统还原已禁用。" -ForegroundColor Green
            Read-Host "按 Enter 返回主菜单"
        }

        "8" {
            Write-Host "`n>>> 硬件检测 (完整版)..." -ForegroundColor Cyan
            $hwScript = Join-Path $ScriptDir "硬件检测.ps1"
            if (Test-Path $hwScript) {
                Write-Host "正在调用硬件检测脚本，请稍候..." -ForegroundColor Green
                & $hwScript
            } else {
                Write-Host "错误：未找到硬件检测脚本 `"$hwScript`"" -ForegroundColor Red
                Write-Host "请确保 `"硬件检测.ps1`" 与 `"一键启动.ps1`" 在同一目录下。" -ForegroundColor Yellow
            }
            Read-Host "`n按 Enter 返回主菜单"
        }

        "0" {
            Write-Host "`n感谢使用 Windows 工具箱！" -ForegroundColor Green
            Start-Sleep -Seconds 1
            exit
        }

        default {
            Write-Host "无效选项，请重新输入。"
            Start-Sleep -Seconds 1
        }
    }
} while ($true)