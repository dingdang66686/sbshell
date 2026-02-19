#!/bin/bash
# 定义主脚本的下载URL
DEBIAN_MAIN_SCRIPT_URL="https://ghfast.top/https://raw.githubusercontent.com/dingdang66686/sbshell/refs/heads/main/debian/menu.sh"
OPENWRT_MAIN_SCRIPT_URL="https://gh-proxy.com/https://raw.githubusercontent.com/dingdang66686/sbshell/refs/heads/main/openwrt/menu.sh"
ALPINE_MAIN_SCRIPT_URL="https://ghfast.top/https://raw.githubusercontent.com/dingdang66686/sbshell/refs/heads/main/alpine/menu.sh"
 
# 脚本下载目录
SCRIPT_DIR="/etc/sing-box/scripts"

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 检查系统是否支持
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}当前系统不支持运行此脚本。${NC}"
    exit 1
fi

# 检测防火墙类型
detect_firewall() {
    if command -v nft &> /dev/null; then
        echo "nftables"
    elif command -v iptables &> /dev/null; then
        echo "iptables"
    else
        echo "none"
    fi
}

# 检查发行版并下载相应的主脚本
if grep -qi 'alpine' /etc/os-release; then
    echo -e "${GREEN}系统为Alpine,支持运行此脚本。${NC}"
    MAIN_SCRIPT_URL="$ALPINE_MAIN_SCRIPT_URL"
    DEPENDENCIES=("wget" "bash" "curl")
    
    # 检查并安装缺失的依赖项
    for DEP in "${DEPENDENCIES[@]}"; do
        CHECK_CMD="$DEP --version"
        
        if ! $CHECK_CMD &> /dev/null; then
            echo -e "${RED}$DEP 未安装。${NC}"
            read -rp "是否安装 $DEP?(y/n): " install_dep
            if [[ "$install_dep" =~ ^[Yy]$ ]]; then
                apk update
                apk add "$DEP"
                if ! $CHECK_CMD &> /dev/null; then
                    echo -e "${RED}安装 $DEP 失败，请手动安装 $DEP 并重新运行此脚本。${NC}"
                    exit 1
                fi
                echo -e "${GREEN}$DEP 安装成功。${NC}"
            else
                echo -e "${RED}由于未安装 $DEP,脚本无法继续运行。${NC}"
                exit 1
            fi
        fi
    done
    
    # 检测并安装防火墙
    FW_TYPE=$(detect_firewall)
    if [ "$FW_TYPE" == "none" ]; then
        echo -e "${YELLOW}未检测到防火墙工具。${NC}"
        read -rp "请选择要安装的防火墙类型 (1:nftables, 2:iptables): " fw_choice
        if [ "$fw_choice" == "1" ]; then
            apk add nftables
            echo "FIREWALL=nftables" > /etc/sing-box/firewall.conf
        elif [ "$fw_choice" == "2" ]; then
            apk add iptables ip6tables
            echo "FIREWALL=iptables" > /etc/sing-box/firewall.conf
        else
            echo -e "${RED}无效选择，默认安装 iptables${NC}"
            apk add iptables ip6tables
            echo "FIREWALL=iptables" > /etc/sing-box/firewall.conf
        fi
    else
        echo "FIREWALL=$FW_TYPE" > /etc/sing-box/firewall.conf
        echo -e "${GREEN}检测到防火墙: $FW_TYPE${NC}"
    fi
elif grep -qi 'debian\|ubuntu\|armbian' /etc/os-release; then
    echo -e "${GREEN}系统为Debian/Ubuntu/Armbian,支持运行此脚本。${NC}"
    MAIN_SCRIPT_URL="$DEBIAN_MAIN_SCRIPT_URL"
    DEPENDENCIES=("wget")

    # 检查 sudo 是否安装
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}sudo 未安装。${NC}"
        read -rp "是否安装 sudo?(y/n): " install_sudo
        if [[ "$install_sudo" =~ ^[Yy]$ ]]; then
            apt-get update
            apt-get install -y sudo
            if ! command -v sudo &> /dev/null; then
                echo -e "${RED}安装 sudo 失败，请手动安装 sudo 并重新运行此脚本。${NC}"
                exit 1
            fi
            echo -e "${GREEN}sudo 安装成功。${NC}"
        else
            echo -e "${RED}由于未安装 sudo,脚本无法继续运行。${NC}"
            exit 1
        fi
    fi

    # 检查并安装缺失的依赖项
    for DEP in "${DEPENDENCIES[@]}"; do
        CHECK_CMD="wget --version"

        if ! $CHECK_CMD &> /dev/null; then
            echo -e "${RED}$DEP 未安装。${NC}"
            read -rp "是否安装 $DEP?(y/n): " install_dep
            if [[ "$install_dep" =~ ^[Yy]$ ]]; then
                sudo apt-get update
                sudo apt-get install -y "$DEP"
                if ! $CHECK_CMD &> /dev/null; then
                    echo -e "${RED}安装 $DEP 失败，请手动安装 $DEP 并重新运行此脚本。${NC}"
                    exit 1
                fi
                echo -e "${GREEN}$DEP 安装成功。${NC}"
            else
                echo -e "${RED}由于未安装 $DEP,脚本无法继续运行。${NC}"
                exit 1
            fi
        fi
    done
    
    # 检测并安装防火墙
    FW_TYPE=$(detect_firewall)
    if [ "$FW_TYPE" == "none" ]; then
        echo -e "${YELLOW}未检测到防火墙工具。${NC}"
        read -rp "请选择要安装的防火墙类型 (1:nftables, 2:iptables): " fw_choice
        if [ "$fw_choice" == "1" ]; then
            sudo apt-get install -y nftables
            echo "FIREWALL=nftables" | sudo tee /etc/sing-box/firewall.conf > /dev/null
        elif [ "$fw_choice" == "2" ]; then
            sudo apt-get install -y iptables
            echo "FIREWALL=iptables" | sudo tee /etc/sing-box/firewall.conf > /dev/null
        else
            echo -e "${RED}无效选择，默认安装 nftables${NC}"
            sudo apt-get install -y nftables
            echo "FIREWALL=nftables" | sudo tee /etc/sing-box/firewall.conf > /dev/null
        fi
    else
        echo "FIREWALL=$FW_TYPE" | sudo tee /etc/sing-box/firewall.conf > /dev/null
        echo -e "${GREEN}检测到防火墙: $FW_TYPE${NC}"
    fi
elif grep -qi 'openwrt' /etc/os-release; then
    echo -e "${GREEN}系统为OpenWRT,支持运行此脚本。${NC}"
    MAIN_SCRIPT_URL="$OPENWRT_MAIN_SCRIPT_URL"
    DEPENDENCIES=()

    # 检测并安装防火墙
    FW_TYPE=$(detect_firewall)
    if [ "$FW_TYPE" == "none" ]; then
        echo -e "${YELLOW}未检测到防火墙工具。${NC}"
        read -rp "请选择要安装的防火墙类型 (1:nftables, 2:iptables): " fw_choice
        if [ "$fw_choice" == "1" ]; then
            opkg update
            opkg install nftables
            echo "FIREWALL=nftables" > /etc/sing-box/firewall.conf
        elif [ "$fw_choice" == "2" ]; then
            opkg update
            opkg install iptables
            echo "FIREWALL=iptables" > /etc/sing-box/firewall.conf
        else
            echo -e "${RED}无效选择，默认安装 nftables${NC}"
            opkg update
            opkg install nftables
            echo "FIREWALL=nftables" > /etc/sing-box/firewall.conf
        fi
    else
        echo "FIREWALL=$FW_TYPE" > /etc/sing-box/firewall.conf
        echo -e "${GREEN}检测到防火墙: $FW_TYPE${NC}"
    fi
else
    echo -e "${RED}当前系统不是Debian/Ubuntu/Armbian/Alpine/OpenWRT,不支持运行此脚本。${NC}"
    exit 1
fi

# 确保脚本目录存在并设置权限
if grep -qi 'openwrt' /etc/os-release; then
    mkdir -p "$SCRIPT_DIR"
    mkdir -p /etc/sing-box
elif grep -qi 'alpine' /etc/os-release; then
    mkdir -p "$SCRIPT_DIR"
    mkdir -p /etc/sing-box
else
    sudo mkdir -p "$SCRIPT_DIR"
    sudo mkdir -p /etc/sing-box
    sudo chown "$(whoami)":"$(whoami)" "$SCRIPT_DIR"
fi

# 下载并执行主脚本
if grep -qi 'openwrt' /etc/os-release; then
    curl -s -o "$SCRIPT_DIR/menu.sh" "$MAIN_SCRIPT_URL"
elif grep -qi 'alpine' /etc/os-release; then
    wget -q -O "$SCRIPT_DIR/menu.sh" "$MAIN_SCRIPT_URL" || curl -s -o "$SCRIPT_DIR/menu.sh" "$MAIN_SCRIPT_URL"
else
    wget -q -O "$SCRIPT_DIR/menu.sh" "$MAIN_SCRIPT_URL"
fi

echo -e "${GREEN}脚本下载中,请耐心等待...${NC}"
echo -e "${YELLOW}注意:安装更新singbox尽量使用代理环境,运行singbox切记关闭代理!${NC}"

if ! [ -f "$SCRIPT_DIR/menu.sh" ]; then
    echo -e "${RED}下载主脚本失败,请检查网络连接。${NC}"
    exit 1
fi

chmod +x "$SCRIPT_DIR/menu.sh"
bash "$SCRIPT_DIR/menu.sh"
