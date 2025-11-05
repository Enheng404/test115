# test115 安装器模板

本仓库包含：

- `install.ps1` — 安全安装器脚本（自动下载并执行 payload）
- `payload.ps1` — 主脚本（执行逻辑可自定义）
- `README.md` — 说明

## 运行：powershell
iwr https://raw.githubusercontent.com/Enheng404/test115/main/install.ps1 -useb | iex
