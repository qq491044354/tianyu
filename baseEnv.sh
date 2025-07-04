#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "📦 正在更新系统并安装依赖..."
pkg update -y && pkg upgrade -y
yes | pkg install clang make libffi zlib readline openssl curl tar

echo "📥 正在下载 Python 3.9.13 源码..."
cd ~
curl -O https://www.python.org/ftp/python/3.9.13/Python-3.9.13.tgz

echo "📂 正在解压源码..."
tar -xf Python-3.9.13.tgz
cd Python-3.9.13

echo "⚙️ 正在配置编译参数..."
./configure --prefix=$HOME/python-3.9 --enable-optimizations

echo "🔨 正在编译（根据设备性能可能需要几分钟）..."
make -j$(nproc)

echo "📦 正在安装到 $HOME/python-3.9 ..."
make install

echo "🛠️ 正在配置环境变量..."
if ! grep -q 'export PATH="$HOME/python-3.9/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/python-3.9/bin:$PATH"' >> ~/.bashrc
fi

echo "✅ 安装完成。请运行以下命令应用环境变量："
echo "    source ~/.bashrc"
echo "然后运行："
echo "    python3 --version"
echo "以验证安装是否成功（应输出 Python 3.9.13）"

