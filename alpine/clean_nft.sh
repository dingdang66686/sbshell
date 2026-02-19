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
        FIREWALL="iptables"
    fi
fi

# 根据防火墙类型调用相应的脚本
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [ "$FIREWALL" = "iptables" ]; then
    sh "$SCRIPT_DIR/clean_iptables.sh"
    exit $?
fi

# 以下是 nftables 的清理实现

# 清理防火墙规则并停止服务
if command -v rc-service >/dev/null 2>&1; then
    rc-service sing-box stop 2>/dev/null || true
elif command -v systemctl >/dev/null 2>&1; then
    systemctl stop sing-box 2>/dev/null || true
fi
nft flush ruleset

echo "sing-box 服务已停止,防火墙规则已清理."
