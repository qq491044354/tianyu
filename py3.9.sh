#!/data/data/com.termux/files/usr/bin/bash
set -e

# 更新并安装 Python
pkg update -y
pkg upgrade -y
pkg install -y python

# 显示 Python 版本确认
python --version

# 定义要追加的启动命令
STARTUP_CMD='
# 自动启动 yolkScript gameAuto main.py
if [ -f /sdcard/yolkScript/gameAuto/main.py ]; then
    nohup python /sdcard/yolkScript/gameAuto/main.py > /dev/null 2>&1 &
fi
'

# 检查是否已经写入过
if ! grep -Fq "自动启动 yolkScript gameAuto main.py" ~/.bashrc; then
    echo "$STARTUP_CMD" >> ~/.bashrc
    echo "已将启动命令追加到 ~/.bashrc"
else
    echo "启动命令已经存在于 ~/.bashrc"
fi
