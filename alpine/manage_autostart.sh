#!/bin/sh

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}设置开机自启动...${NC}"
echo "请选择操作(1: 启用自启动, 2: 禁用自启动）"
read -p "(1/2): " autostart_choice

case $autostart_choice in
    1)
        # 检查自启动是否已经开启
        if rc-update show | grep -q "sing-box"; then
            echo -e "${GREEN}自启动已经开启，无需操作。${NC}"
            exit 0
        fi

        echo -e "${GREEN}启用自启动...${NC}"
        
        # 添加 sing-box 到默认运行级别
        rc-update add sing-box default
        
        if rc-update show | grep -q "sing-box"; then
            echo -e "${GREEN}自启动已成功启用。${NC}"
        else
            echo -e "${RED}启用自启动失败。${NC}"
        fi
        ;;
    2)
        # 检查自启动是否已经禁用
        if ! rc-update show | grep -q "sing-box"; then
            echo -e "${GREEN}自启动已经禁用，无需操作。${NC}"
            exit 0
        fi

        echo -e "${RED}禁用自启动...${NC}"
        
        # 从默认运行级别移除 sing-box
        rc-update del sing-box default
        
        if ! rc-update show | grep -q "sing-box"; then
            echo -e "${GREEN}自启动已成功禁用。${NC}"
        else
            echo -e "${RED}禁用自启动失败。${NC}"
        fi
        ;;
    *)
        echo -e "${RED}无效的选择，请重新输入。${NC}"
        exit 1
        ;;
esac

[Unit]
Description=Apply nftables rules for Sing-Box
After=network.target

[Service]
ExecStart=/etc/sing-box/scripts/manage_autostart.sh apply_firewall
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF'

        # 修改 sing-box.service 文件
        bash -c "sed -i '/After=network.target nss-lookup.target network-online.target/a After=nftables-singbox.service' /usr/lib/systemd/system/sing-box.service"
        bash -c "sed -i '/^Requires=/d' /usr/lib/systemd/system/sing-box.service"
        bash -c "sed -i '/

\[Unit\]

/a Requires=nftables-singbox.service' /usr/lib/systemd/system/sing-box.service"

        # 启用并启动服务
        systemctl daemon-reload
        rc-update add nftables-singbox.service sing-box.service
        rc-service nftables-singbox.service sing-box.service
        cmd_status=$?

        if [ "$cmd_status" -eq 0 ]; then
            echo -e "${GREEN}自启动已成功启用。${NC}"
        else
            echo -e "${RED}启用自启动失败。${NC}"
        fi
        ;;
    2)
        # 检查自启动是否已经禁用
        if ! systemctl is-enabled sing-box.service >/dev/null 2>&1 && ! systemctl is-enabled nftables-singbox.service >/dev/null 2>&1; then
            echo -e "${GREEN}自启动已经禁用，无需操作。${NC}"
            exit 0  # 返回主菜单
        fi

        echo -e "${RED}禁用自启动...${NC}"
        
        # 禁用并停止服务
        rc-update del sing-box.service
        rc-update del nftables-singbox.service
        rc-service sing-box.service
        rc-service nftables-singbox.service

        # 删除 nftables-singbox.service 文件
        rm -f /etc/systemd/system/nftables-singbox.service

        # 还原 sing-box.service 文件
        bash -c "sed -i '/After=nftables-singbox.service/d' /usr/lib/systemd/system/sing-box.service"
        bash -c "sed -i '/Requires=nftables-singbox.service/d' /usr/lib/systemd/system/sing-box.service"

        # 重新加载 systemd
        systemctl daemon-reload
        cmd_status=$?

        if [ "$cmd_status" -eq 0 ]; then
            echo -e "${GREEN}自启动已成功禁用。${NC}"
        else
            echo -e "${RED}禁用自启动失败。${NC}"
        fi
        ;;
    *)
        echo -e "${RED}无效的选择${NC}"
        ;;
esac

# 调用应用防火墙规则的函数
if [ "$1" = "apply_firewall" ]; then
    apply_firewall
fi
