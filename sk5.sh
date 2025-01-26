#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1
# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi
# 获取公网IP
public_ip=$(curl -s ifconfig.me)

if [[ -z "$public_ip" ]]; then
    echo -e "${red}无法获取服务器公网IP，请检查网络设置！${plain}"
    exit 1
fi

echo -e "${green}检测到服务器公网IP：$public_ip${plain}"

# 安装前置依赖
install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar jq -y
    else
        apt install wget curl tar jq -y
    fi
}

#This function will be called when user installed x-ui out of sercurity
config_after_install() {
    echo -e "${yellow}出于安全考虑，安装/更新完成后需要强制修改端口与账户密码${plain}"
    # 自动设置账户名、密码和端口
    config_account="lcc"
    config_password="lcc666"
    config_port="6868"

    echo -e "${yellow}您的账户名将设定为:${config_account}${plain}"
    echo -e "${yellow}您的账户密码将设定为:${config_password}${plain}"
    echo -e "${yellow}您的面板访问端口将设定为:${config_port}${plain}"
    echo -e "${yellow}确认设定,设定中${plain}"

    # 设置账户名和密码
    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
    echo -e "${yellow}账户密码设定完成${plain}"

    # 设置访问端口
    /usr/local/x-ui/x-ui setting -port ${config_port}
    echo -e "${yellow}面板端口设定完成${plain}"
  

    echo -e "${green}成功添加入站规则！${plain}"
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}检测 x-ui 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 x-ui 版本安装${plain}"
            exit 1
        fi
        echo -e "检测到 x-ui 最新版本：${last_version}，开始安装"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "开始安装 x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} 安装完成，面板已启动，"
    echo -e ""
    echo -e "x-ui 管理脚本使用方法: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - 显示管理菜单 (功能更多)"
    echo -e "x-ui start        - 启动 x-ui 面板"
    echo -e "x-ui stop         - 停止 x-ui 面板"
    echo -e "x-ui restart      - 重启 x-ui 面板"
    echo -e "x-ui status       - 查看 x-ui 状态"
    echo -e "x-ui enable       - 设置 x-ui 开机自启"
    echo -e "x-ui disable      - 取消 x-ui 开机自启"
    echo -e "x-ui log          - 查看 x-ui 日志"
    echo -e "x-ui v2-ui        - 迁移本机器的 v2-ui 账号数据至 x-ui"
    echo -e "x-ui update       - 更新 x-ui 面板"
    echo -e "x-ui install      - 安装 x-ui 面板"
    echo -e "x-ui uninstall    - 卸载 x-ui 面板"
    echo -e "----------------------------------------------"
}
requetData(){
  sleep 5  # 等待 10 秒，确保配置文件生成
    # 登录并获取 session
     login_response=$(curl -i -s 'http://'$public_ip':6868/login' \
        -H 'Referer: http://'$public_ip':6868/' \
        -H 'X-Requested-With: XMLHttpRequest' \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
        --data 'username=lcc&password=lcc666')
    #  echo -e "${green}获取到新的数据: $login_response${plain}"
     session=$(echo "$login_response" | grep -i 'Set-Cookie: session=' | awk -F 'session=' '{print $2}' | awk -F ';' '{print $1}')
#   echo -e "${green}获取到新的 session: $session${plain}"
    # new_session=$(echo $login_response | jq -r '.session')

    if [[ -z "$session" ]]; then
        echo -e "${red}无法获取有效的 session，请检查用户名和密码！${plain}"
        exit 1
    fi

    # echo -e "${green}获取到新的 session: $session${plain}"

    # 执行添加入站规则
    curl 'http://'${public_ip}':6868/xui/inbound/add' \
      -H 'Accept: application/json, text/plain, */*' \
      -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' \
      -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
      -H "Cookie: session=${session}" \
      -H 'Origin: http://'${public_ip}':6868' \
      -H 'Proxy-Connection: keep-alive' \
      -H 'Referer: http://'${public_ip}':6868/xui/inbounds' \
      -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
      -H 'X-Requested-With: XMLHttpRequest' \
      --data 'up=0&down=0&total=0&remark=&enable=true&expiryTime=0&listen=&port=6868&protocol=socks&settings=%7B%0A%20%20%22auth%22%3A%20%22password%22%2C%0A%20%20%22accounts%22%3A%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22user%22%3A%20%226%22%2C%0A%20%20%20%20%20%20%22pass%22%3A%20%226%22%0A%20%20%20%20%7D%0A%20%20%5D%2C%0A%20%20%22udp%22%3A%20true%2C%0A%20%20%22ip%22%3A%20%22'$public_ip'%22%0A%7D&streamSettings=%7B%0A%20%20%22network%22%3A%20%22tcp%22%2C%0A%20%20%22security%22%3A%20%22none%22%2C%0A%20%20%22tcpSettings%22%3A%20%7B%0A%20%20%20%20%22header%22%3A%20%7B%0A%20%20%20%20%20%20%22type%22%3A%20%22none%22%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D&sniffing=%7B%7D' \
      --insecure
    echo -e "${green}安装成功！GSY你个大傻逼"

}


# 执行安装函数
echo -e "${green}开始安装${plain}"
install_base
install_x-ui $1
requetData
