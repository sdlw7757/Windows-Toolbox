# 🖥️ Windows 工具箱一键启动

<div align="center">

![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=PowerShell&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows%207%2F8%2F10%2F11-0078D4?style=for-the-badge)

**一个强大的 Windows 系统管理工具箱，一键完成系统清理、激活、优化、DLL修复等多种操作**

</div>

---

## ✨ 功能特性

| 编号 | 功能 | 说明 |
|:---:|:---|:---|
| 1️⃣ | **深度清理** | 智能扫描 Temp/Cache/CrashDumps/LogFiles 目录，释放磁盘空间 |
| 2️⃣ | **用户信息查询** | 查看用户名、账户类型、内网IPv4/IPv6、外网IP及地理位置 |
| 3️⃣ | **KMS 激活** | 自动识别 Windows/Office 批量版本，一键激活（含 Project/Visio） |
| 4️⃣ | **密码重置** | 快速重置当前账户密码 |
| 5️⃣ | **SMB 共享工具** | 便捷配置 SMB 网络共享 |
| 6️⃣ | **SSD 优化** | 开启 TRIM、禁用碎片整理、优化写入策略，延长 SSD 寿命 |
| 7️⃣ | **禁用系统还原** | 关闭系统还原点创建、删除历史还原点、禁用备份服务 |
| 8️⃣ | **硬件检测** | 实时显示 CPU/GPU/内存/存储/显示器/主板等详细硬件信息 |
| 9️⃣ | **DLL 修复** | 运行库/DirectX/系统DLL检测修复，支持VC++运行库自动修复 |

---

## 🚀 快速开始

### 运行方式

**方式一：直接运行**
```powershell
# 右键点击 "一键启动.ps1" → 选择 "使用 PowerShell 运行"
```

**方式二：命令行启动**
```powershell
powershell -ExecutionPolicy Bypass -File "一键启动.ps1"
```

**方式三：CMD 运行**
```cmd
powershell -ExecutionPolicy Bypass -File "一键启动.ps1"
```

---

## 📖 使用说明

### 主菜单界面

运行后将显示简洁的中文交互菜单：

```
============================================================
               Windows 工具箱一键启动
============================================================

  [1] 深度清理 (扫描/删除 Temp、缓存、日志)
  [2] 获取用户信息 (用户名、账户类型、内网IP、外网IP、IPv6)
  [3] KMS 激活 (自动识别 Windows/Office)
  [4] 重置本机用户密码
  [5] SMB 共享工具 (配置 SMB 共享服务)
  [6] SSD 优化 (TRIM、禁用碎片、整理缓存)
  [7] 禁用系统还原 (关闭还原点/删除历史)
  [8] 硬件检测 (含温度：CPU/GPU/内存/显卡/主板/屏幕)
  [9] DLL修复 (运行库/DirectX/系统DLL检测修复)

  [0] 退出程序

============================================================
```

---

## 🔧 功能详情

### 🧹 深度清理
- 实时扫描用户目录，定位垃圾文件
- 扫描系统级 Temp、Prefetch、SoftwareDistribution 目录
- 显示精确扫描路径数量和找到的垃圾目录数
- 清理前显示预估释放空间

### 📡 用户信息查询
- 当前用户名及账户类型（本地/Microsoft 账户）
- 内网 IPv4/IPv6 地址
- 外网 IP 地址及地理位置（通过 ipinfo.io/ip-api.com）
- ISP 信息

### 🔑 KMS 激活
- **支持 Windows**: 7/8/10/11, Server 2012R2/2016/2019/2022
- **支持 Office**: 2010/2013/2016/2019/2021/2024
- **支持产品**: ProPlus、Standard、Project、Visio
- 自动匹配 GVLK 密钥，无需手动输入

### 💻 密码重置
- 快速重置当前账户密码
- 支持本地账户密码修改

### 📂 SMB 共享工具
- 自动下载 SMB 共享配置工具
- 便捷配置网络共享权限
- 支持 SMB 2.0/3.0 协议

### ⚡ SSD 优化
- 开启 TRIM 功能
- 禁用碎片整理计划任务
- 关闭休眠功能
- 禁用 Windows Search 服务
- 禁用 Prefetch/Superfetch
- 禁用系统还原
- 禁用卷影复制 (VSS)
- 优化写入缓存策略

### 🛡️ 禁用系统还原
- 关闭系统还原点创建
- 删除历史还原点
- 禁用备份服务
- 自动配置注册表

### 📊 硬件检测
- **CPU**: 名称、核心数、线程数、频率、架构、缓存、温度、使用率
- **内存**: 总容量、插槽信息（容量/类型/频率/厂商）、使用率
- **存储**: 硬盘型号、接口类型、容量、分区使用情况
- **GPU**: 名称、显存（专用 VRAM）、驱动版本、分辨率、使用率
- **显示器**: 型号、制造商、序列号
- **主板/BIOS**: 制造商、型号、序列号、BIOS 版本及发布日期
- **系统**: 版本、安装日期、最后启动时间、激活状态

### 🔧 DLL 修复
DLL修复工具提供以下功能：

| 功能 | 说明 |
|:---|:---|
| 全面体检 | 检测系统中的DLL和运行库问题 |
| 运行库修复 | 检测并修复VC++运行库（包含 .NET Runtime 检测） |
| DirectX修复 | 检测并修复DirectX组件 |
| 系统DLL修复 | 检测并修复系统核心DLL |
| 执行全部修复 | 执行所有检测和修复功能 |

---

## 🗂️ 项目结构

```
Windows 工具箱一键启动/
├── 一键启动.ps1              # 🏠 主程序 - 工具箱启动器
├── DeepClean_v1.ps1          # 深度清理引擎（独立版）
├── KMS_Activate.ps1          # KMS 激活工具（独立版）
├── GetInfo.ps1               # 用户信息查询（独立版）
├── 硬件检测.ps1              # 硬件信息检测（独立版）
├── ResetPass.ps1             # 密码重置工具（独立版）
├── 禁用系统还原.ps1           # 禁用系统还原（独立版）
├── SSD 优化.bat               # SSD 优化批处理
├── SMB_Share_Tool.ps1        # SMB 共享下载器
├── SMB_Share_Tool.cmd        # SMB 共享工具本体
├── DLL/
│   ├── DLLFixerScript.ps1    # DLL修复工具主程序
│   ├── Json/                 # DLL修复配置文件
│   │   ├── SystemDllJson/    # 系统DLL配置
│   │   └── VCDirectxJson/    # VC运行库/DirectX配置
│   └── *.dll                 # 常用DLL文件库
├── LICENSE                   # MIT 开源许可证
└── README.md                 # 说明文档
```

---

## ⚙️ 系统要求

| 要求 | 说明 |
|:---|:---|
| **操作系统** | Windows 7 / 8 / 10 / 11 或 Windows Server |
| **架构** | x64（部分功能需要 64 位） |
| **权限** | 部分功能需要管理员权限（会自动请求提升） |
| **依赖** | PowerShell 3.0+ |

---

## ⚠️ 注意事项

> [!IMPORTANT]
> 1. **管理员权限**: 大多数功能需要管理员权限运行，程序会自动请求提升
> 2. **KMS 激活**: 仅支持批量授权版本的 Windows 和 Office，零售版无法使用
> 3. **SSD 优化**: 优化项已针对 SSD，如果使用机械硬盘请勿运行
> 4. **系统还原**: 禁用系统还原后无法恢复，建议谨慎操作
> 5. **密码重置**: 只会重置当前账户密码

---

## 🔧 技术细节

### 编码
- 脚本使用 UTF-8 编码，支持中文显示
- 控制台代码页自动切换为 65001

### 权限提升
```powershell
# 自动检测并请求管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
```

### KMS 服务器
- 使用开源 KMS 服务器: `kms.03k.org`
- 激活有效期 180 天，到期后自动续期

### DLL 修复功能
- 支持从本地 DLL 文件夹加载文件（优先）
- 多源下载：dllarchive.com、dll-files.com、dllme.com、dllsite.com
- 自动识别 Windows 版本（Win7/8/10/11）
- 自动适配系统架构（32位/64位）

---

## 📝 更新日志

### v1.1.0
- 🆕 新增 DLL 修复工具
- 新增选项 9：DLL修复 (运行库/DirectX/系统DLL检测修复)
- 包含 VC++ 运行库检测修复
- 包含 .NET Framework/Core 检测
- 包含 DirectX 组件检测修复
- 包含系统核心 DLL 检测修复

### v1.0.0
- 🎉 初始版本发布
- 支持 8 大功能模块
- 独立运行脚本可单独使用

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源许可证。

> **Copyright (c) 2026 Love Yun**
>
> 特此授权，任何人都可免费获取本软件及相关文档，可不受限制地使用、复制、修改、合并、发布、分发、再授权和/或出售本软件，也可向提供本软件的人提供同等权利，但须遵守以下条件：

---

## 👨‍💻 作者信息

- **作者**: Love Yun
- **GitHub**: [sdlw7757/Windows 工具箱一键启动](https://github.com/Cotton059/Light-Help)

---

## 🙏 致谢

感谢每一位使用者的支持！如果您在使用过程中遇到任何问题，欢迎在 GitHub 上提交 Issue。

---

<div align="center">

**如果这个项目对您有帮助，请给一个 ⭐**

*Made with ❤️ by Love Yun*

</div>
