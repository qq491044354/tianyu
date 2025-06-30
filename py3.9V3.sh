#!/data/data/com.termux/files/usr/bin/bash
set -e

# 更新并安装依赖
pkg update -y
pkg install -y git make clang libffi openssl zlib bzip2 sqlite

# 克隆 pyenv（如果还没有）
if [ ! -d "$HOME/.pyenv" ]; then
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
fi

# 添加环境变量到 .bashrc（如果没加过）
if ! grep -q 'PYENV_ROOT' ~/.bashrc; then
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'export PYTHON_BUILD_MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn/python"' >> ~/.bashrc
    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
fi

# 当前 shell 生效变量
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYTHON_BUILD_MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn/python"
eval "$(pyenv init --path)"

# 安装并设置 Python 3.9.18（若未安装）
if ! pyenv versions | grep -q "3.9.18"; then
    pyenv install 3.9.18
fi

pyenv global 3.9.18
python --version
