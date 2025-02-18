#!/bin/bash

# 检查并安装 screen
function check_and_install_screen() {
    if ! command -v screen &> /dev/null; then
        echo "screen 未安装，正在安装..."
        # 直接运行安装命令，无需 sudo
        apt update && apt install -y screen
    else
        echo "screen 已安装。"
    fi
}

# 检查并安装nvm
function check_and_install_nvm() {
    if ! command -v nvm &> /dev/null; then
        echo "正在安装nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # 重新加载nvm环境
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        # 重新加载shell配置
        if [ -f ~/.bashrc ]; then
            source ~/.bashrc
        elif [ -f ~/.zshrc ]; then
            source ~/.zshrc
        fi
        
        # 验证nvm安装
        if ! command -v nvm &> /dev/null; then
            echo "nvm安装失败,请手动安装"
            exit 1
        fi
    fi
    
    echo "nvm已安装,版本: $(nvm --version)"
    
    # 安装并使用Node.js 16.20
    echo "正在安装Node.js 16.20..."
    if ! nvm install 16.20; then
        echo "Node.js 16.20安装失败"
        exit 1
    fi
    
    if ! nvm use 16.20; then
        echo "切换到Node.js 16.20失败"
        exit 1
    fi
    
    echo "Node.js版本: $(node --version)"
}

# 初始化安装
function init_environment() {
    # 检查并安装nvm
    check_and_install_nvm
    
    # 创建工作目录
    echo "创建工作目录..."
    mkdir -p p0tion-tmp
    cd p0tion-tmp

    # 安装phase2cli
    echo "安装 @p0tion/phase2cli..."
    npm install @p0tion/phase2cli
    
    echo "初始化完成!"
    cd ..
}

# 执行认证
function auth_node() {
    cd $HOME/p0tion-tmp 2>/dev/null || {
        echo "错误: 未找到p0tion-tmp目录，请先执行初始化"
        read -n 1 -s -r -p "按任意键返回主菜单..."
        return
    }
    
    echo "执行认证..."
    echo "请注意以下步骤:"
    echo "1. 等待系统生成授权码(auth code)"
    echo "2. 生成授权码后，请访问 https://github.com/login/device"
    echo "3. 在GitHub页面输入生成的授权码"
    echo "4. 点击确认授权"
    echo "================================================================"
    
    npx phase2cli auth
    
    echo "================================================================"
    while true; do
        echo "请确认您是否已完成GitHub授权？"
        echo "1. 已完成授权，继续执行"
        echo "2. 未完成授权，继续等待"
        echo "3. 返回主菜单"
        read -p "请选择 (1/2/3): " auth_choice
        
        case $auth_choice in
            1)  echo "继续执行..."; break ;;
            2)  echo "继续等待30秒..."; sleep 30 ;;
            3)  cd ..; return 1 ;;
            *)  echo "无效选择，请重新输入！" ;;
        esac
    done
    
    cd ..
    return 0
}

# 启动contribute
function start_contribute() {
    cd $HOME/p0tion-tmp 2>/dev/null || {
        echo "错误: 未找到p0tion-tmp目录，请先执行初始化"
        read -n 1 -s -r -p "按任意键返回主菜单..."
        return
    }
    
    echo "启动contribute..."
    npx phase2cli contribute
    
    cd ..
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 完整部署流程
function install_pse() {
    init_environment
    auth_node
    if [ $? -eq 0 ]; then
        start_contribute
    else
        echo "认证流程未完成，无法启动contribute"
        read -n 1 -s -r -p "按任意键返回主菜单..."
    fi
}

# 更新主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区fanyilun0编写，推特 @fanyilun0，免费开源，请勿相信收费"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 完整部署phase2节点"
        echo "3. 仅执行认证"
        echo "4. 仅启动contribute"
        echo "5. 清理节点"
        echo "6. 登出节点"
        echo "7. 退出脚本"
        echo "================================================================"
        read -p "请输入选择 (1-7): " choice

        case $choice in
            1)  install_pse ;;
            2)  auth_node ;;
            3)  start_contribute ;;
            4)  clean_node ;;
            5)  logout_node ;;
            6)  exit_script ;;
            *)  echo "无效选择，请重新输入！"; sleep 2 ;;
        esac
    done
}

# 清理功能
function clean_node() {
    echo "执行清理..."
    cd p0tion-tmp 2>/dev/null
    if [ $? -eq 0 ]; then
        npx phase2cli clean
        cd ..
    else
        echo "未找到p0tion-tmp目录"
    fi
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 登出功能
function logout_node() {
    echo "执行登出..."
    cd p0tion-tmp 2>/dev/null
    if [ $? -eq 0 ]; then
        npx phase2cli logout
        cd ..
    else
        echo "未找到p0tion-tmp目录"
    fi
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 退出脚本
function exit_script() {
    echo "退出脚本..."
    exit 0
}

# 调用主菜单函数
main_menu
