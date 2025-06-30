#!/data/data/com.termux/files/usr/bin/bash
yes | pkg update
yes | pkg upgrade -y
pkg install -y git make clang libffi-dev openssl-dev zlib-dev bzip2 libbz2 libsqlite libsqlite-dev
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
source ~/.bashrc
pyenv install 3.9.18
pyenv global 3.9.18
python --version