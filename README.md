# 🖥️ Windows 工具箱一键启动

<div align="center">

![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=PowerShell&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

*一个强大的 Windows 系统管理工具箱，一键完成系统清理、激活、优化等多种操作*

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
  [0] 退出程序

============================================================
```

### 功能详情

#### 🧹 深度清理
- 实时扫描用户目录，定位垃圾文件
- 扫描系统级 Temp、Prefetch、SoftwareDistribution 目录
- 显示精确扫描路径数量和找到的垃圾目录数
- 清理前显示预估释放空间

#### 📡 用户信息查询
- 当前用户名及账户类型（本地/Microsoft 账户）
- 内网 IPv4/IPv6 地址
- 外网 IP 地址及地理位置（通过 ipinfo.io/ip-api.com）
- ISP 信息

#### 🔑 KMS 激活
- **支持 Windows**: 7/8/10/11, Server 2012R2/2016/2019/2022
- **支持 Office**: 2010/2013/2016/2019/2021/2024
- **支持产品**: ProPlus、Standard、Project、Visio
- 自动匹配 GVLK 密钥，无需手动输入

#### 💻 硬件检测
- **CPU**: 名称、核心数、线程数、频率、架构、缓存、温度、使用率
- **内存**: 总容量、插槽信息（容量/类型/频率/厂商）、使用率
- **存储**: 硬盘型号、接口类型、容量、分区使用情况
- **GPU**: 名称、显存（专用 VRAM）、驱动版本、分辨率、使用率
- **显示器**: 型号、制造商、序列号
- **主板/BIOS**: 制造商、型号、序列号、BIOS 版本及发布日期
- **系统**: 版本、安装日期、最后启动时间、激活状态

---

## 🛠️ 工具列表

| 文件名 | 类型 | 说明 |
|:---|:---:|:---|
| `一键启动.ps1` | PowerShell | 🏠 主程序 - 工具箱启动器 |
| `DeepClean_v1.ps1` | PowerShell | 深度清理引擎（独立版） |
| `KMS_Activate.ps1` | PowerShell | KMS 激活工具（独立版） |
| `GetInfo.ps1` | PowerShell | 用户信息查询（独立版） |
| `硬件检测.ps1` | PowerShell | 硬件信息检测（独立版） |
| `ResetPass.ps1` | PowerShell | 密码重置工具（独立版） |
| `禁用系统还原.ps1` | PowerShell | 禁用系统还原（独立版） |
| `SSD 优化.bat` | Batch | SSD 优化批处理 |
| `SMB_Share_Tool.ps1` | PowerShell | SMB 共享下载器 |
| `SMB_Share_Tool.cmd` | Batch | SMB 共享工具本体 |
| `LICENSE` | Text | MIT 开源许可证 |

---

## ⚙️ 系统要求

- **操作系统**: Windows 7 / 8 / 10 / 11 或 Windows Server
- **架构**: x64（部分功能需要 64 位）
- **权限**: 部分功能需要管理员权限（会自动请求提升）
- **依赖**: PowerShell 3.0+

---

## ⚠️ 注意事项

1. **管理员权限**: 大多数功能需要管理员权限运行，程序会自动请求提升
2. **KMS 激活**: 仅支持批量授权版本的 Windows 和 Office，零售版无法使用
3. **SSD 优化**: 优化项已针对 SSD，如果使用机械硬盘请勿运行
4. **系统还原**: 禁用系统还原后无法恢复，建议谨慎操作
5. **密码重置**: 只会重置当前账户密码

---

## 🔧 技术细节

### 编码
- 脚本使用 UTF-8 编码，支持中文显示
- 控制台代码页自动切换为 65001

### 权限提升
```powershell
# 自动检测并请求管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

### KMS 服务器
- 使用开源 KMS 服务器: `kms.03k.org`
- 激活有效期 180 天，到期后自动续期

---

## 📝 更新日志

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

*Made with ❤️ by Love Yun*

</div>
