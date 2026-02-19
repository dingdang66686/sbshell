#!/bin/sh

CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "正在检测sing-box最新版本..."

if command -v sing-box &> /dev/null; then
    current_version=$(sing-box version | grep 'sing-box version' | awk '{print $3}')
    echo -e "${CYAN}当前安装的sing-box版本为:${NC} $current_version"
    
    # On Alpine, sing-box is typically installed from releases, not package manager
    echo -e "${CYAN}请访问 https://github.com/SagerNet/sing-box/releases 查看最新版本${NC}"
    echo -e "${CYAN}使用安装脚本更新到最新版本${NC}"
else
    echo -e "${RED}sing-box 未安装${NC}"
fi
