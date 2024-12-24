# ritual-net-node-deployment
一、仓库概述
本仓库包含一个用于自动化安装、管理和维护 Ritual Node 的脚本，旨在为用户提供便捷的方式来处理与 Ritual Node 相关的各种操作，包括安装、更新、配置修改以及卸载等。
二、使用说明
（一）系统要求
运行脚本的系统需支持bash脚本执行环境。
具备apt包管理器（通常为基于 Debian 或 Ubuntu 的系统）。
（二）安装步骤
克隆仓库到本地：
使用命令git clone https://github.com/feiyulc/ritual-node-installer.git将仓库克隆到本地机器。
进入仓库目录：
执行cd ritual-node-installer进入克隆下来的仓库目录。
运行安装脚本：
执行./install.sh（如果脚本没有执行权限，先使用chmod +x install.sh赋予权限）。
根据提示选择相应的操作，如安装基本文件及 Ritual Node、更新 Ritual Node 等。
（三）功能操作
安装 Ritual Node 相关组件
选择菜单中的选项 1、2、3 可分别按照不同步骤进行 Ritual Node 的安装。
安装过程中会自动检查并安装所需的依赖软件，如curl、git、jq、lz4、build-essential、screen、Docker和Docker Compose等。
会从指定的 GitHub 仓库克隆相关文件，并进行一些配置文件的修改和设置。
重启 Ritual Node
若 Ritual Node 停止运行，选择菜单中的选项 4 可进行重启操作。
会先停止相关的 Docker 容器，然后重新启动它们。
更改钱包地址
选择菜单中的选项 5，按照提示输入新的钱包私钥（需以0x开头）。
脚本会自动更新相关配置文件中的钱包地址信息，并重新部署合约。
更改 RPC 地址
选择菜单中的选项 6，输入新的 RPC URL。
脚本会更新配置文件中的 RPC 地址，并重启相关的服务。
更新 Ritual Node
选择菜单中的选项 7，可对 Ritual Node 进行更新操作。
主要是修改一些配置文件中的参数，如snapshot_sync相关参数，然后停止并重新启动 Docker 容器。
卸载 Ritual Node
选择菜单中的选项 8，可彻底卸载 Ritual Node 及其相关组件。
包括删除 Docker 容器、镜像，清除相关的目录和文件，如foundry相关文件、infernet-container-starter目录等。
（四）注意事项
在执行安装或更新操作前，建议备份重要数据，以防数据丢失。
确保系统有足够的磁盘空间、内存等资源来支持 Ritual Node 的运行。
对于修改配置文件（如钱包地址、RPC 地址等）的操作，务必仔细核对输入信息，错误的配置可能导致节点无法正常工作。
若在使用过程中遇到问题，可以查看脚本输出的错误信息，并在仓库的Issues页面查找是否有类似问题或提交新的问题反馈。
三、目录结构
install.sh：主脚本文件，包含了所有的功能实现逻辑。
README.md：本使用说明文件，提供给用户如何使用仓库中的脚本。
四、贡献指南
欢迎用户提交问题反馈和改进建议。如果发现脚本存在问题或有新的功能需求，可以在Issues页面创建新的问题。
对于希望贡献代码的开发者，遵循以下步骤：
克隆仓库到本地开发环境。
创建新的分支用于开发，分支命名建议遵循有意义的命名规范，如feature/新功能名称或bugfix/问题描述。
在新分支上进行代码修改和开发。
开发完成后，提交代码并推送到远程仓库。
创建Pull Request，详细描述所做的修改和改进，等待仓库维护者审核和合并。
