#!/bin/bash

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
NC='\033[0m'

# Ritual基本文件安装及相关操作
install_ritual() {
    # 安装基本软件包
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    echo -e "${CYAN}sudo apt update${NC}"
    sudo apt update

    echo -e "${CYAN}sudo apt upgrade -y${NC}"
    sudo apt upgrade -y

    echo -e "${CYAN}sudo apt autoremove -y${NC}"
    sudo apt autoremove -y

    echo -e "${CYAN}sudo apt -qy install curl git jq lz4 build-essential screen${NC}"
    sudo apt -qy install curl git jq lz4 build-essential screen

    echo -e "${BOLD}${CYAN}检查Docker安装情况...${NC}"
    if! command_exists docker; then
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

    if! command_exists docker-compose; then
        echo -e "${RED}Docker Compose未安装。正在安装Docker Compose...${NC}"
        # Docker Compose的最新版本下载URL
        sudo curl -L https://github.com/docker/compose/releases/download/$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq.name -r)/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
        sudo chmod 755 /usr/bin/docker-compose
        echo -e "${CYAN}Docker Compose安装成功。${NC}"
    else
        echo -e "${CYAN}Docker Compose已安装。${NC}"
    endif

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

    # 修改deploy.s.sol
    deploy_s_sol=~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol  #目前此处有问题
    old_registry="0x663F3ad617193148711d28f5334eE4Ed07016602"
    new_registry="0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"

    echo -e "${CYAN}deploy.s.sol修改完成${NC}"
    sed -i "s|$old_registry|$new_registry|" "$deploy_s_sol"

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

install_ritual_3() {
    # 安装foundry
    echo -e "${CYAN}cd $HOME${NC}"
    cd $HOME

    echo -e "${CYAN}mkdir foundry${NC}"
    mkdir foundry

    echo -e "${CYAN}cd $HOME/foundry${NC}"
    cd $HOME/foundry

    echo -e "${CYAN}curl -L https://foundry.paradigm.xyz | bash${NC}"
    curl -L https://foundry.paradigm.xyz | bash

    export PATH="/root/.foundry/bin:$PATH"

    echo -e "${CYAN}source ~/.bashrc${NC}"
    source ~/.bashrc

    echo -e "${CYAN}foundryup${NC}"
    foundryup

    echo -e "${CYAN}cd ~/infernet-container-starter/projects/hello-world/contracts${NC}"
    cd ~/infernet-container-starter/projects/hello-world/contracts

    echo -e "${CYAN}rm -rf lib${NC}"
    rm -rf lib

    echo -e "${CYAN}forge install --no-commit foundry-rs/forge-std${NC}"
    forge install --no-commit foundry-rs/forge-std

    echo -e "${CYAN}forge install --no-commit ritual-net/infernet-sdk${NC}"
    forge install --no-commit ritual-net/infernet-sdk

    export PATH="/root/.foundry/bin:$PATH"

    # 最终签约
    echo -e "${CYAN}cd $HOME/infernet-container-starter${NC}"
    cd $HOME/infernet-container-starter

    echo -e "${CYAN}project=hello-world make deploy-contracts${NC}"
    project=hello-world make deploy-contracts

    # 修改call-contract
    echo -e "${CYAN}向上滚动查看Logs${NC}"
    echo -ne "${CYAN}准确输入deployed Sayshello Sayshello: ${NC}"
    read -e says_gm

    callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"

    echo -e "${CYAN}/root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol修改${NC}"
    sed "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath" | sudo tee "$callcontractpath" > /dev/null

    # 完成签约
    echo -e "${CYAN}project=hello-world make call-contract${NC}"
    project=hello-world make call-contract

    echo -e "${BOLD}${MAGENTA}Ritual安装完成。辛苦了。（说实话，你们辛苦啥？辛苦的是我吧 哈哈;;）${NC}"
}

restart_ritual() {
    echo -e "${CYAN}docker compose down${NC}"
    cd $HOME/infernet-container-starter/deploy
    docker compose down

    echo -e "${BOLD}${MAGENTA}docker ps${NC}"
    docker ps

    echo -e "${BOLD}${MAGENTA}现在在终端输入'cd ~/infernet-container-starter/deploy && docker compose up'${NC}"
    echo -e "${BOLD}${MAGENTA}输入命令后，当文本快速滚动时，不要按任何键，关闭终端。${NC}"
}

change_Wallet_Address() {
    # 从用户获取新的私钥
    echo -ne "${BOLD}${MAGENTA}请输入新的私钥（前面加上0x）：${NC}"
    read -e private_key1

    # 修改文件的路径
    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile

    # 创建临时文件
    temp_file=$(mktemp)

    # 使用jq修改私钥并保存到临时文件
    jq --arg priv "$private_key1" \
        '.chain.wallet.private_key = $priv' $json_1 > $temp_file

    # 用临时文件覆盖原文件并删除临时文件
    mv $temp_file $json_1

    # 对第二个文件应用相同的更改
    jq --arg priv "$private_key1" \
        '.chain.wallet.private_key = $priv' $json_2 > $temp_file

    mv $temp_file $json_2

    # 删除临时文件
    rm -f $temp_file

    echo -e "${BOLD}${MAGENTA}私钥已更新${NC}"

    # 使用sed修改sender的值
    sed -i "s|sender :=.*|sender := $private_key1|" "$makefile"

    echo -e "${BOLD}${MAGENTA}makefile的私钥已更新${NC}"

    # 重新签约
    echo -e "${CYAN}cd $HOME/infernet-container-starter${NC}"
    cd $HOME/infernet-container-starter

    echo -e "${CYAN}project=hello-world make deploy-contracts${NC}"
    project=hello-world make deploy-contracts

    # 修改call-contract
    echo -e "${CYAN}向上滚动查看Logs${NC}"
    echo -ne "${CYAN}准确输入deployed Sayshello Sayshello: ${NC}"
    read -e says_gm

    callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"

    echo -e "${CYAN}/root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol修改${NC}"
    sed "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath" | sudo tee "$callcontractpath" > /dev/null

    # 完成签约
    echo -e "${CYAN}project=hello-world make call-contract${NC}"
    project=hello-world make call-contract

    echo -e "${BOLD}${MAGENTA}钱包地址更改完成。${NC}"
}

change_RPC_Address() {
    # 从用户获取新的RPC URL
    echo -ne "${BOLD}${MAGENTA}请输入新的RPC URL：${NC}"
    read -e rpc_url1

    # 修改文件的路径
    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile

    # 创建临时文件
    temp_file=$(mktemp)

    # 使用jq修改RPC URL并保存到临时文件
    jq --arg rpc "$rpc_url1" \
        '.chain.rpc_url = $rpc' $json_1 > $temp_file

    # 用临时文件覆盖原文件并删除临时文件
    mv $temp_file $json_1

    # 对第二个文件应用相同的更改
    jq --arg rpc "$rpc_url1" \
        '.chain.rpc_url = $rpc' $json_2 > $temp_file

    mv $temp_file $json_2

    # 删除临时文件
    rm -f $temp_file

    echo -e "${BOLD}${MAGENTA}RPC URL已更新${NC}"

    # 使用sed修改RPC_URL的值
    sed -i "s|RPC_URL :=.*|RPC_URL := $rpc_url1|" "$makefile"

    echo -e "${BOLD}${MAGENTA}makefile的RPC URL已更新${NC}"

    echo -e "${CYAN}docker restart infernet-anvil${NC}"
    docker restart infernet-anvil

    echo -e "${CYAN}docker restart hello-world${NC}"
    docker restart hello-world

    echo -e "${CYAN}docker restart infernet-node${NC}"
    docker restart infernet-node

    echo -e "${CYAN}docker restart infernet-fluentbit${NC}"
    docker restart infernet-fluentbit

    echo -e "${CYAN}docker restart infernet-redis${NC}"
    docker restart infernet-redis

    echo -e "${BOLD}${MAGENTA}RPC URL修改完成。${NC}"
    echo -e "${BOLD}${MAGENTA}如果RPC URL修改后仍不生效，请再次输入命令并执行4次。
update_ritual() {
    echo -e "${BOLD}${RED}Ritual更新（10/31）开始。${NC}"

    # 要修改的文件路径
    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json

    # 创建临时文件
    temp_file=$(mktemp)

    # 修改第一个文件
    jq '.chain.snapshot_sync.sleep = 3 |
      .chain.snapshot_sync.batch_size = 9500 |
      .chain.snapshot_sync.starting_sub_id = 200000 |
      .chain.snapshot_sync.sync_period = 15' "$json_1" > "$temp_file"
    mv "$temp_file" "$json_1"

    # 修改第二个文件
    jq '.chain.snapshot_sync.sleep = 3 |
      .chain.snapshot_sync.batch_size = 9500 |
      .chain.snapshot_sync.starting_sub_id = 200000 |
      .chain.snapshot_sync.sync_period = 15' "$json_2" > "$temp_file"
    mv "$temp_file" "$json_2"

    # 删除临时文件
    rm -f $temp_file

    echo -e "${YELLOW}停止Docker。${NC}"
    cd ~/infernet-container-starter/deploy && docker compose down

    echo -e "${YELLOW}现在输入'${NC}${RED}cd ~/infernet-container-starter/deploy && docker compose up'${NC}${YELLOW}来重新启动Docker。${NC}"
}
uninstall_ritual() {
    # 删除所有Ritual相关的Docker容器
    echo -e "${BOLD}${CYAN}删除Ritual Docker容器...${NC}"
    docker stop infernet-anvil
    docker stop infernet-node
    docker stop hello-world
    docker stop infernet-redis
    docker stop infernet-fluentbit

    docker rm -f infernet-anvil
    docker rm -f infernet-node
    docker rm -f hello-world
    docker rm -f infernet-redis
    docker rm -f infernet-fluentbit

    cd ~/infernet-container-starter/deploy && docker compose down

    # 删除Ritual相关的Docker镜像
    echo -e "${BOLD}${CYAN}删除Ritual Docker镜像...${NC}"
    docker image ls -a | grep "infernet" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "infernet" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "fluent-bit" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "redis" | awk '{print $3}' | xargs docker rmi -f

    # 删除foundry相关文件
    echo -e "${CYAN}删除$HOME/foundry目录${NC}"
    rm -rf $HOME/foundry

    echo -e "${CYAN}删除~/.bashrc中关于/root/.foundry/bin的配置${NC}"
    sed -i '/\/root\/.foundry\/bin/d' ~/.bashrc

    echo -e "${CYAN}删除~/infernet-container-starter/projects/hello-world/contracts/lib目录${NC}"
    rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib

    echo -e "${CYAN}执行forge clean命令${NC}"
    forge clean

    # 删除Ritual节点文件
    echo -e "${BOLD}${CYAN}删除infernet-container-starter目录...${NC}"
    cd $HOME
    sudo rm -rf infernet-container-starter
    cd $HOME

    echo -e "${BOLD}${CYAN}与Ritual Node相关的文件已删除。以防万一，没有删除Docker命令，因为可能还有其他Docker在使用。${NC}"
}
# 主菜单
echo && echo -e "${BOLD}${MAGENTA}Ritual Node自动安装脚本${NC} by 币爱你（这里对原作者名做了一种通俗化的翻译示意，可按需调整）
 ${CYAN}选择你想要执行的操作并运行它就可以了。${NC}
 ———————————————————————
 ${GREEN}1. 安装基本文件及Ritual Node（版本1.4.0）第1步${NC}
 ${GREEN}2. Ritual Node安装（版本1.4.0）第2步${NC}
 ${GREEN}3. Ritual Node安装（版本1.4.0）第3步${NC}
 ${GREEN}4. Ritual Node停止运行了！重新启动它${NC}
 ${GREEN}5. 想要更改Ritual Node的钱包地址${NC}
 ${GREEN}6. 想要更改Ritual Node的RPC地址${NC}
 ${GREEN}7. 想要更新Ritual Node（12/15）${NC}
 ${GREEN}8. 想要从系统中删除Ritual Node${NC}
 ———————————————————————" && echo

# 等待用户输入
echo -ne "${BOLD}${MAGENTA}你想要执行什么操作？请参考上述选项并输入数字：${NC}"
read -e num

case "$num" in
1)
    install_ritual
    ;;
2)
    install_ritual_2
    ;;
3)
    install_ritual_3
    ;;
4)
    restart_ritual
    ;;
5)
    change_Wallet_Address
    ;;
6)
    change_RPC_Address
    ;;
7)
    update_ritual
    ;;
8)
    uninstall_ritual
    ;;
*)
    echo -e "${BOLD}${RED}哎呀，烦死了，不想骂人，就想让你消失。${NC}"
    ;;
esac
