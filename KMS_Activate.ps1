#requires -RunAsAdministrator
<#
.SYNOPSIS
    全自动KMS激活脚本 - 自动识别Windows和Office批量版本，无需手动输入密钥
.DESCRIPTION
    使用开源KMS服务器 kms.03k.org，自动匹配GVLK密钥并激活。
    支持Windows 7/8/10/11/Server及Office 2010~2024（含Project/Visio）。
#>

# 防止闪退：错误捕获后暂停
trap {
    Write-Host "`n[错误] $_" -ForegroundColor Red
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# 设置控制台编码（支持中文）
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$OutputEncoding = [Console]::OutputEncoding

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "请以管理员身份运行此脚本。`n即将自动重启..." -ForegroundColor Red
    Start-Sleep -Seconds 2
    $psPath = (Get-Process -Id $pid).Path
    Start-Process $psPath -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# KMS服务器地址（开源）
$kmsServer = "kms.03k.org"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "          全自动KMS激活工具 (开源服务器)              " -ForegroundColor Green
Write-Host "          服务器: $kmsServer" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------- 自动激活Windows -----------------------------
function Activate-Windows {
    Write-Host "[1/2] 正在检测Windows版本..." -ForegroundColor Magenta
    $winCaption = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    Write-Host "检测到: $winCaption" -ForegroundColor Cyan

    # Windows GVLK密钥映射表（使用更灵活的匹配规则）
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

    $selectedKey = $null
    foreach ($entry in $winKeys) {
        if ($winCaption -match $entry.Pattern) {
            $selectedKey = $entry.Key
            Write-Host "匹配密钥: $selectedKey" -ForegroundColor DarkCyan
            break
        }
    }

    if (-not $selectedKey) {
        Write-Host "未能自动匹配GVLK密钥，请手动输入（或按Enter跳过Windows激活）:" -ForegroundColor Yellow
        $selectedKey = Read-Host "密钥"
        if (-not $selectedKey) { return }
    }

    Write-Host "正在安装产品密钥..." -ForegroundColor Yellow
    Start-Process -FilePath "cscript" -ArgumentList "$env:windir\system32\slmgr.vbs /ipk $selectedKey" -NoNewWindow -Wait
    Write-Host "正在设置KMS服务器..." -ForegroundColor Yellow
    Start-Process -FilePath "cscript" -ArgumentList "$env:windir\system32\slmgr.vbs /skms $kmsServer" -NoNewWindow -Wait
    Write-Host "正在激活..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath "cscript" -ArgumentList "$env:windir\system32\slmgr.vbs /ato" -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host "Windows激活成功！" -ForegroundColor Green
    } else {
        Write-Host "Windows激活失败（错误代码 $($proc.ExitCode)），请检查网络或服务器状态。" -ForegroundColor Red
    }
}

# ----------------------------- 自动激活Office -----------------------------
function Activate-Office {
    Write-Host "[2/2] 正在检测Office批量版本..." -ForegroundColor Magenta

    # 查找OSPP.VBS
    $officePaths = @(
        "${env:ProgramFiles}\Microsoft Office\Office16",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
        "${env:ProgramFiles}\Microsoft Office\Office15",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
        "${env:ProgramFiles}\Microsoft Office\Office14",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office14"
    )
    $osppPath = $null
    foreach ($path in $officePaths) {
        $test = Join-Path $path "OSPP.VBS"
        if (Test-Path $test) {
            $osppPath = $test
            break
        }
    }

    if (-not $osppPath) {
        Write-Host "未找到Office批量许可版本（未安装或为零售版），跳过Office激活。" -ForegroundColor Red
        return
    }
    Write-Host "找到Office脚本: $osppPath" -ForegroundColor Cyan

    # 通过 /dstatus 获取当前安装的产品信息（如果已有GVLK则能显示）
    $status = & cscript //nologo $osppPath /dstatus 2>$null
    $installedProducts = @()
    $currentProduct = $null
    foreach ($line in $status) {
        if ($line -match "Product Name: (.+)") { $currentProduct = $Matches[1].Trim() }
        if ($line -match "Last 5 characters of installed product key: (.+)") {
            $keySuffix = $Matches[1].Trim()
            if ($currentProduct) {
                $installedProducts += [PSCustomObject]@{ Name = $currentProduct; KeySuffix = $keySuffix }
                $currentProduct = $null
            }
        }
    }

    # 预定义Office GVLK映射表（产品名称关键词 -> GVLK）
    $officeKeyMap = @{
        # Office 2010
        "Office 14" = @{ "ProPlus" = "VYBBJ-TRJPB-QFQRF-QFT4D-H3GVB"; "Standard" = "V7QKV-4XVVR-XYV4D-F7DFM-8R6BM" }
        # Office 2013
        "Office 15" = @{ "ProPlus" = "YC7DK-G2NP3-2QQC3-J6H88-GVGXT"; "Standard" = "KBKQT-2NM3J-RR79Y-4XGJM-MC4QT" }
        # Office 2016
        "Office 16" = @{ "ProPlus" = "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99"; "Standard" = "JNRGM-WHDWX-FJJG3-K47QV-DRTFM"; "ProjectPro" = "WGT24-HCNMF-FQ7XH-6M8K7-DRTW9"; "VisioPro" = "B7N8W-FV3YX-48TMD-8GGG9-7C8XT" }
        # Office 2019
        "Office 2019" = @{ "ProPlus" = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP"; "Standard" = "6NWWJ-YQWMR-QKGCB-6T7V3-6D69X"; "ProjectPro" = "B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B"; "VisioPro" = "9BGNQ-K37YR-RQHF2-38RQ3-7VCBB" }
        # Office 2021
        "Office 2021" = @{ "ProPlus" = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"; "Standard" = "KDX7X-BNVR8-TXXGX-4Q7Y8-78VT3"; "ProjectPro" = "FTNWT-C6WBT-8HMGF-K9PRX-QV9H8"; "VisioPro" = "KNH8D-FGHT4-T8RK3-CTDYJ-K2HT4" }
        # Office 2024 (LTSC)
        "Office 2024" = @{ "ProPlus" = "2TDPW-NDQ7G-FMG99-DXQ7M-TX3T2"; "Standard" = "6J7MX-PJ9D8-4Q84C-6RRQT-4QX8W"; "ProjectPro" = "GNF3V-HBMV8-4WT74-8KPPT-8VH99"; "VisioPro" = "J4JYF-JG6X4-6V387-FJ4RX-XGFG7" }
    }

    # 根据已安装产品匹配GVLK
    function Get-OfficeKeyFromProductName($productName) {
        # 粗略识别年份
        if ($productName -match "2010") { $year = "Office 14" }
        elseif ($productName -match "2013") { $year = "Office 15" }
        elseif ($productName -match "2016") { $year = "Office 16" }
        elseif ($productName -match "2019") { $year = "Office 2019" }
        elseif ($productName -match "2021") { $year = "Office 2021" }
        elseif ($productName -match "2024") { $year = "Office 2024" }
        else { return $null }

        $edition = ""
        if ($productName -match "ProPlus|Professional Plus") { $edition = "ProPlus" }
        elseif ($productName -match "Standard") { $edition = "Standard" }
        elseif ($productName -match "Project") { $edition = "ProjectPro" }
        elseif ($productName -match "Visio") { $edition = "VisioPro" }
        else { return $null }

        if ($officeKeyMap.ContainsKey($year) -and $officeKeyMap[$year].ContainsKey($edition)) {
            return $officeKeyMap[$year][$edition]
        }
        return $null
    }

    $selectedOfficeKey = $null
    if ($installedProducts.Count -gt 0) {
        Write-Host "检测到以下已安装的Office产品:" -ForegroundColor Cyan
        foreach ($prod in $installedProducts) {
            Write-Host "  - $($prod.Name) (密钥尾号: $($prod.KeySuffix))" -ForegroundColor Gray
            $key = Get-OfficeKeyFromProductName $prod.Name
            if ($key -and -not $selectedOfficeKey) {
                $selectedOfficeKey = $key
                Write-Host "    自动匹配GVLK: $key" -ForegroundColor DarkCyan
            }
        }
    }

    if (-not $selectedOfficeKey) {
        Write-Host "无法自动识别Office版本，请手动选择要激活的产品:" -ForegroundColor Yellow
        Write-Host "  [1] Office 2010 专业增强版"
        Write-Host "  [2] Office 2013 专业增强版"
        Write-Host "  [3] Office 2016 专业增强版"
        Write-Host "  [4] Office 2019 专业增强版"
        Write-Host "  [5] Office 2021 专业增强版"
        Write-Host "  [6] Office 2024 专业增强版（预览）"
        Write-Host "  [7] Project 2016/2019/2021 专业版"
        Write-Host "  [8] Visio 2016/2019/2021 专业版"
        Write-Host "  [9] 手动输入GVLK密钥"
        $opt = Read-Host "请输入数字"
        switch ($opt) {
            "1" { $selectedOfficeKey = "VYBBJ-TRJPB-QFQRF-QFT4D-H3GVB" }
            "2" { $selectedOfficeKey = "YC7DK-G2NP3-2QQC3-J6H88-GVGXT" }
            "3" { $selectedOfficeKey = "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99" }
            "4" { $selectedOfficeKey = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP" }
            "5" { $selectedOfficeKey = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH" }
            "6" { $selectedOfficeKey = "2TDPW-NDQ7G-FMG99-DXQ7M-TX3T2" }
            "7" { $selectedOfficeKey = "WGT24-HCNMF-FQ7XH-6M8K7-DRTW9" }
            "8" { $selectedOfficeKey = "B7N8W-FV3YX-48TMD-8GGG9-7C8XT" }
            "9" { $selectedOfficeKey = Read-Host "请输入完整的GVLK密钥" }
            default { Write-Host "无效选择，跳过Office激活"; return }
        }
    }

    Write-Host "正在安装Office产品密钥..." -ForegroundColor Yellow
    Start-Process -FilePath "cscript" -ArgumentList "$osppPath /inpkey:$selectedOfficeKey" -NoNewWindow -Wait
    Write-Host "正在设置KMS服务器..." -ForegroundColor Yellow
    Start-Process -FilePath "cscript" -ArgumentList "$osppPath /sethst:$kmsServer" -NoNewWindow -Wait
    Write-Host "正在激活Office..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath "cscript" -ArgumentList "$osppPath /act" -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host "Office激活成功！" -ForegroundColor Green
    } else {
        Write-Host "Office激活失败（错误代码 $($proc.ExitCode)），请检查版本是否为批量许可版。" -ForegroundColor Red
    }
}

# ----------------------------- 主流程 -----------------------------
Activate-Windows
Write-Host ""
Activate-Office

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "所有操作执行完毕。按任意键退出..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")