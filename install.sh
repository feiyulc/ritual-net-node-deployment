#!/bin/bash

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
NC='\033[0m'

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ritual基本文件安装及相关操作
install_ritual() {
    echo -e "${CYAN}sudo apt update${NC}"
    sudo apt update

    echo -e "${CYAN}sudo apt upgrade -y${NC}"
    sudo apt upgrade -y

    echo -e "${CYAN}sudo apt autoremove -y${NC}"
    sudo apt autoremove -y

    echo -e "${CYAN}sudo apt -qy install curl git jq lz4 build-essential screen${NC}"
    sudo apt -qy install curl git jq lz4 build-essential screen

    echo -e "${BOLD}${CYAN}检查Docker安装情况...${NC}"
    if ! command_exists docker; then
        echo -e "${RED}Docker未安装。正在安装Docker...${NC}"
        sudo apt install docker.io -y
        echo -e "${CYAN}Docker安装成功。${NC}"
    else
        echo -e "${CYAN}Docker已安装。${NC}"
    fi

    echo -e "${CYAN}docker version${NC}"
    docker version

    echo -e "${CYAN}sudo apt-get update${NC}"
    sudo apt-get update

    if ! command_exists docker-compose; then
        echo -e "${RED}Docker Compose未安装。正在安装Docker Compose...${NC}"
        sudo curl -L https://github.com/docker/compose/releases/download/$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
        sudo chmod 755 /usr/bin/docker-compose
        echo -e "${CYAN}Docker Compose安装成功。${NC}"
    else
        echo -e "${CYAN}Docker Compose已安装。${NC}"
    fi

    echo -e "${CYAN}install docker compose CLI plugin${NC}"
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

    echo -e "${CYAN}make plugin executable${NC}"
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

    echo -e "${CYAN}docker-compose version${NC}"
    docker-compose version

    # 安装Ritual
    echo -e "${CYAN}git clone https://github.com/ritual-net/infernet-container-starter${NC}"
    git clone https://github.com/ritual-net/infernet-container-starter

    docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
    sed -i 's/image: ritualnetwork\/infernet-node:1.3.1/image: ritualnetwork\/infernet-node:1.2.0/' "$docker_yaml"
    echo -e "${BOLD}${CYAN}docker-compose.yaml（docker版本）已回退到1.2.0${NC}"

    echo -e "${MAGENTA}${BOLD}'screen -S ritual'输入后，再输入'cd ~/infernet-container-starter && project=hello-world make deploy-container'${NC}"
    echo -e "${MAGENTA}${BOLD}看到大的绿色RITUAL后，按Ctrl+A+D退出。${NC}"
}

install_ritual_2() {
    # 从用户获取新的RPC URL和私钥
    echo -ne "${BOLD}${MAGENTA}请输入新的RPC URL：${NC}"
    read -e rpc_url1

    echo -ne "${BOLD}${MAGENTA}请输入新的私钥（前面加上0x）：${NC}"
    read -e private_key1

    # 修改文件的路径
    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json

    # 创建临时文件
    temp_file=$(mktemp)

    # 使用jq修改RPC URL和私钥并保存到临时文件
    jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
        '.chain.rpc_url = $rpc |
      .chain.wallet.private_key = $priv |
      .chain.trail_head_blocks = 3 |
      .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
      .chain.snapshot_sync.sleep = 3 |
      .chain.snapshot_sync.batch_size = 950 |
      .chain.snapshot_sync.starting_sub_id = 200000 |
      .chain.snapshot_sync.sync_period = 15' $json_1 > $temp_file

    # 用临时文件覆盖原文件并删除临时文件
    mv $temp_file $json_1

    # 对第二个文件应用相同的更改
    jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
        '.chain.rpc_url = $rpc |
      .chain.wallet.private_key = $priv |
      .chain.trail_head_blocks = 3 |
      .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
      .chain.snapshot_sync.sleep = 3 |
      .chain.snapshot_sync.batch_size = 9500 |
      .chain.snapshot_sync.starting_sub_id = 200000 |
      .chain.snapshot_sync.sync_period = 15' $json_2 > $temp_file

    mv $temp_file $json_2

    # 删除临时文件
    rm -f $temp_file

    echo -e "${BOLD}${MAGENTA}RPC URL和私钥已更新${NC}"

    # 修改文件的路径
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile

    # 使用sed修改sender和RPC_URL的值
    sed -i "s|sender :=.*|sender := $private_key1|" "$makefile"
    sed -i "s|RPC_URL :=.*|RPC_URL := $rpc_url1|" "$makefile"

    echo -e "${BOLD}${CYAN}Makefile已更新${NC}"

    # 设置docker-compose_yaml
    docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
    sed -i 's/image: ritualnetwork\/infernet-node:1.2.0/image: ritualnetwork\/infernet-node:1.4.0/' "$docker_yaml"
    echo -e "${BOLD}${CYAN}docker-compose.yaml已更新到1.4.0${NC}"

    echo -e "${CYAN}docker compose down${NC}"
    cd $HOME/infernet-container-starter/deploy
    docker compose down

    echo -e "${CYAN}docker restart hello-world${NC}"
    docker restart hello-world

    echo -e "${BOLD}${MAGENTA}docker ps${NC}"
    docker ps

    echo -e "${BOLD}${MAGENTA}现在在终端输入'cd ~/infernet-container-starter/deploy && docker compose up'${NC}"
    echo -e "${BOLD}${MAGENTA}输入命令后，当文本快速滚动时，不要按任何键，关闭终端，然后打开新终端重新登录控制台。${NC}"
}

# 其他安装步骤（Foundry、Rust、Node.js、NPM依赖等）
install_foundry() {
    echo -e "${CYAN}安装Foundry工具...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    echo -e "${CYAN}Foundry安装完成！${NC}"
}

install_rust() {
    echo -e "${CYAN}安装Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    echo -e "${CYAN}Rust安装完成！${NC}"
}

install_nodejs() {
    echo -e "${CYAN}安装Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo -e "${CYAN}Node.js安装完成！${NC}"
}

install_npm_dependencies() {
    echo -e "${CYAN}安装NPM依赖...${NC}"
    cd ~/infernet-container-starter
    npm install
    echo -e "${CYAN}NPM依赖安装完成！${NC}"
}

start_project() {
    echo -e "${CYAN}启动项目...${NC}"
    cd ~/infernet-container-starter/deploy
    docker-compose up -d
    echo -e "${CYAN}项目启动完成！${NC}"
}

build_project() {
    echo -e "${CYAN}编译项目...${NC}"
    cd ~/infernet-container-starter
    npm run build
    echo -e "${CYAN}项目编译完成！${NC}"
}

# 菜单函数
display_menu() {
    echo -e "${GREEN}欢迎使用Ritual安装脚本${NC}"
    echo -e "1. 安装基础依赖和Docker"
    echo -e "2. 配置RPC URL和私钥"
    echo -e "3. 安装Foundry"
    echo -e "4. 安装Rust"
    echo -e "5. 安装Node.js"
    echo -e "6. 安装NPM依赖"
    echo -e "7. 启动项目"
    echo -e "8. 编译项目"
    echo -e "请选择你需要执行的操作（1-8）："
    read -p "选择: " choice
}

# 调用菜单函数，获取用户输入并执行对应操作
display_menu

case $choice in
    1) install_ritual ;;
    2) install_ritual_2 ;;
    3) install_foundry ;;
    4) install_rust ;;
    5) install_nodejs ;;
    6) install_npm_dependencies ;;
    7) start_project ;;
    8) build_project ;;
    *) echo -e "${RED}无效的选择，请重新选择！${NC}" ;;
esac
