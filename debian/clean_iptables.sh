#!/bin/bash

# 清理 iptables 规则并停止服务
sudo systemctl stop sing-box

# 清理 iptables 规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

echo "sing-box 服务已停止,iptables 规则已清理."
