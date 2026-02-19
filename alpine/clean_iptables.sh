#!/bin/sh

# 清理 iptables 规则并停止服务
if command -v rc-service >/dev/null 2>&1; then
    rc-service sing-box stop 2>/dev/null || true
elif command -v systemctl >/dev/null 2>&1; then
    systemctl stop sing-box 2>/dev/null || true
fi

# 清理 iptables 规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

echo "sing-box 服务已停止,iptables 规则已清理."
