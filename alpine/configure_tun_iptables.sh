#!/bin/sh

# 配置参数
PROXY_FWMARK=1
PROXY_ROUTE_TABLE=100
INTERFACE=$(ip route show default | awk '/default/ {print $5}')

# 读取当前模式
MODE=$(grep -E '^MODE=' /etc/sing-box/mode.conf | sed 's/^MODE=//')

# 清理 TProxy 模式的 iptables 规则
clearTProxyRules() {
    # 清理 mangle 表
    iptables -t mangle -D PREROUTING -j SINGBOX 2>/dev/null
    iptables -t mangle -D OUTPUT -j SINGBOX_OUTPUT 2>/dev/null
    iptables -t mangle -F SINGBOX 2>/dev/null
    iptables -t mangle -X SINGBOX 2>/dev/null
    iptables -t mangle -F SINGBOX_OUTPUT 2>/dev/null
    iptables -t mangle -X SINGBOX_OUTPUT 2>/dev/null
    
    # 清理路由规则
    ip rule del fwmark $PROXY_FWMARK lookup $PROXY_ROUTE_TABLE 2>/dev/null
    ip route del local default dev "$INTERFACE" table $PROXY_ROUTE_TABLE 2>/dev/null
    
    echo "清理 TProxy 模式的 iptables 规则"
}

if [ "$MODE" = "TUN" ]; then
    echo "应用 TUN 模式下的 iptables 防火墙规则..."

    # 清理 TProxy 模式的防火墙规则
    clearTProxyRules

    # TUN 模式通常只需要基本的 filter 规则
    # 确保 filter 表允许所有流量
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    # 清空现有规则
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X

    # 持久化防火墙规则
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules 2>/dev/null
    fi

    echo "TUN 模式的 iptables 防火墙规则已应用。"
else
    echo "当前模式不是 TUN 模式，跳过防火墙规则配置。" >/dev/null 2>&1
fi
