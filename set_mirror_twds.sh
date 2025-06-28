#!/bin/bash

backup_file="/etc/apt/sources.list.bak"
sudo cp /etc/apt/sources.list "$backup_file"
echo "[*] 備份舊來源到 $backup_file"

get_distro_info() {
    if command -v lsb_release &>/dev/null; then
        DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        CODENAME=$(lsb_release -cs)
    elif [ -f /etc/os-release ]; then
        DISTRO=$(source /etc/os-release && echo $ID)
        CODENAME=$(source /etc/os-release && echo $VERSION_CODENAME)
    else
        echo "[!] 無法自動偵測發行版"
        exit 1
    fi
}

if [ $# -eq 0 ]; then
    echo "[*] 自動偵測發行版中..."
    get_distro_info
else
    DISTRO=$1
    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
    if [[ "$DISTRO" != "kali" ]]; then
        read -p "請輸入 $DISTRO 版本代號 (例如: noble, bookworm): " CODENAME
    fi
fi

echo "[*] 準備為 $DISTRO ($CODENAME) 設定來源..."

case "$DISTRO" in
    ubuntu)
        sudo tee /etc/apt/sources.list <<EOF
deb http://mirror.twds.com.tw/ubuntu/ $CODENAME main restricted universe multiverse
deb http://mirror.twds.com.tw/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb http://mirror.twds.com.tw/ubuntu/ $CODENAME-security main restricted universe multiverse
deb http://mirror.twds.com.tw/ubuntu/ $CODENAME-backports main restricted universe multiverse
EOF
        ;;
    debian)
        sudo tee /etc/apt/sources.list <<EOF
deb http://mirror.twds.com.tw/debian/ $CODENAME main contrib non-free non-free-firmware
deb http://mirror.twds.com.tw/debian/ $CODENAME-updates main contrib non-free non-free-firmware
deb http://mirror.twds.com.tw/debian-security $CODENAME-security main contrib non-free non-free-firmware
EOF
        ;;
    kali)
        sudo tee /etc/apt/sources.list <<EOF
deb http://mirror.twds.com.tw/kali kali-rolling main non-free non-free-firmware contrib
deb-src http://mirror.twds.com.tw/kali kali-rolling main non-free non-free-firmware contrib
EOF

        echo "[*] 匯入 Kali GPG 金鑰..."
        curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg > /dev/null
        ;;
    *)
        echo "[!] 不支援發行版: $DISTRO"
        exit 1
        ;;
esac

echo "[*] 更新套件清單..."
sudo apt update
echo "[✔] 完成！"
