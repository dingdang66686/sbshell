#!/bin/sh

# 检测防火墙类型
if [ -f /etc/sing-box/firewall.conf ]; then
    FIREWALL=$(grep -E '^FIREWALL=' /etc/sing-box/firewall.conf | sed 's/^FIREWALL=//')
else
    # 默认检测
    if command -v nft >/dev/null 2>&1; then
        FIREWALL="nftables"
    elif command -v iptables >/dev/null 2>&1; then
        FIREWALL="iptables"
    else
        FIREWALL="nftables"
    fi
fi

# 根据防火墙类型调用相应的脚本
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [ "$FIREWALL" = "iptables" ]; then
    sh "$SCRIPT_DIR/clean_iptables.sh"
    exit $?
fi

# 以下是 nftables 的清理实现

nft list table inet sing-box >/dev/null 2>&1 && nft delete table inet sing-box

echo "sing-box 服务已停止, sing-box 相关的防火墙规则已清理."
