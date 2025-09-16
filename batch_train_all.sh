#!/bin/bash

# Bert-VITS2 批量训练脚本
# 自动处理dataset目录下所有包含config.json的角色文件夹
# 按顺序执行：重采样 -> 文本预处理 -> Bert特征生成 -> 训练

# 初始化 conda 并激活环境
eval "$(conda shell.bash hook)"
conda activate bv2.3

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

export CUDA_VISIBLE_DEVICES=0
confirm_before_run=true
copy_base_model=true

# 脚本路径 - 确保在项目根目录执行
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
LINUX_SCRIPTS_DIR="$PROJECT_ROOT/Script/Linux"
DATASET_DIR="$PROJECT_ROOT/dataset"

# 训练脚本列表（按执行顺序）
SCRIPTS=(
    "01_Resample.sh"
    "02_preprocess_text.sh" 
    "03_BertGen.sh"
    "04_Train.sh"
)

# 脚本描述
SCRIPT_DESCRIPTIONS=(
    "重采样音频文件"
    "预处理文本数据"
    "生成Bert特征"
    "开始模型训练"
)

# 检查必要的目录是否存在
check_directories() {
    echo -e "${BLUE}[INFO]${NC} 检查目录结构..."
    
    # 检查是否在正确的项目根目录
    if [ ! -f "$PROJECT_ROOT/batch_train_all.sh" ]; then
        echo -e "${RED}[ERROR]${NC} 请在项目根目录中执行此脚本"
        echo -e "${YELLOW}[提示]${NC} 当前目录: $(pwd)"
        echo -e "${YELLOW}[提示]${NC} 脚本位置: $PROJECT_ROOT"
        exit 1
    fi
    
    if [ ! -d "$LINUX_SCRIPTS_DIR" ]; then
        echo -e "${RED}[ERROR]${NC} Script/Linux 目录不存在: $LINUX_SCRIPTS_DIR"
        exit 1
    fi
    
    if [ ! -d "$DATASET_DIR" ]; then
        echo -e "${RED}[ERROR]${NC} dataset 目录不存在: $DATASET_DIR"
        exit 1
    fi
    
    # 检查所有训练脚本是否存在
    for script in "${SCRIPTS[@]}"; do
        if [ ! -f "$LINUX_SCRIPTS_DIR/$script" ]; then
            echo -e "${RED}[ERROR]${NC} 脚本文件不存在: $LINUX_SCRIPTS_DIR/$script"
            exit 1
        fi
        
        # 检查脚本是否可执行
        if [ ! -x "$LINUX_SCRIPTS_DIR/$script" ]; then
            echo -e "${YELLOW}[WARN]${NC} 设置脚本可执行权限: $script"
            chmod +x "$LINUX_SCRIPTS_DIR/$script"
        fi
    done
    
    echo -e "${GREEN}[OK]${NC} 目录结构检查完成"
    echo -e "${BLUE}[INFO]${NC} 项目根目录: $PROJECT_ROOT"
}

# 获取所有包含config.json的角色文件夹
get_character_folders() {
    local folders=()
    
    echo -e "${BLUE}[INFO]${NC} 扫描dataset目录中的角色文件夹..." >&2
    
    for dir in "$DATASET_DIR"/*; do
        if [ -d "$dir" ]; then
            local folder_name=$(basename "$dir")
            if [ -f "$dir/config.json" ]; then
                folders+=("$folder_name")
                echo -e "${GREEN}[FOUND]${NC} 发现角色文件夹: $folder_name" >&2
            else
                echo -e "${YELLOW}[SKIP]${NC} 跳过文件夹（缺少config.json）: $folder_name" >&2
            fi
        fi
    done
    
    if [ ${#folders[@]} -eq 0 ]; then
        echo -e "${RED}[ERROR]${NC} 没有找到包含config.json的角色文件夹" >&2
        exit 1
    fi
    
    echo "${folders[@]}"
}

# 执行单个脚本
execute_script() {
    local script_name=$1
    local character_name=$2
    local description=$3
    
    echo -e "${PURPLE}[EXEC]${NC} 为角色 ${CYAN}$character_name${NC} 执行: $description ($script_name)"
    
    # 切换到项目根目录，然后执行Script/Linux中的脚本
    cd "$PROJECT_ROOT"
    
    # 执行脚本并捕获输出
    if "$LINUX_SCRIPTS_DIR/$script_name" "$character_name"; then
        echo -e "${GREEN}[SUCCESS]${NC} $script_name 执行成功 (角色: $character_name)"
        return 0
    else
        echo -e "${RED}[ERROR]${NC} $script_name 执行失败 (角色: $character_name)"
        return 1
    fi
}

# 处理单个角色
process_character() {
    local character_name=$1
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}开始处理角色: $character_name${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # 如果启用，复制基础模型
    if [ "$copy_base_model" = true ]; then
        # copy base model if exists to the character folder names models directory
        local base_model_dir="$PROJECT_ROOT/base_model"
        local target_model_dir="$DATASET_DIR/$character_name/models"
        if [ -d "$base_model_dir" ]; then
            echo -e "${BLUE}[INFO]${NC} 复制基础模型到角色目录: $target_model_dir"
            mkdir -p "$target_model_dir"
            cp -r "$base_model_dir/"* "$target_model_dir/"
            echo -e "${GREEN}[OK]${NC} 基础模型复制完成"
        else
            echo -e "${YELLOW}[WARN]${NC} 基础模型目录不存在，跳过复制: $base_model_dir"
        fi
    fi

    # 按顺序执行所有脚本
    for i in "${!SCRIPTS[@]}"; do
        local script="${SCRIPTS[$i]}"
        local description="${SCRIPT_DESCRIPTIONS[$i]}"
        
        echo ""
        echo -e "${BLUE}[步骤 $((i+1))/4]${NC} $description"
        
        if ! execute_script "$script" "$character_name" "$description"; then
            echo -e "${RED}[FAILED]${NC} 角色 $character_name 的处理在步骤 $((i+1)) 失败"
            return 1
        fi
        
        # 在步骤之间添加短暂延迟
        sleep 2
    done
    
    echo ""
    echo -e "${GREEN}[COMPLETED]${NC} 角色 $character_name 的所有步骤已完成"
    return 0
}

# 显示摘要信息
show_summary() {
    local characters=("$@")
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}批量训练摘要${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}将要处理的角色数量:${NC} ${#characters[@]}"
    echo -e "${BLUE}处理步骤:${NC}"
    for i in "${!SCRIPT_DESCRIPTIONS[@]}"; do
        echo -e "  $((i+1)). ${SCRIPT_DESCRIPTIONS[$i]}"
    done
    echo -e "${BLUE}角色列表:${NC}"
    for char in "${characters[@]}"; do
        echo -e "  - $char"
    done
    echo ""
}

# 询问用户确认
confirm_execution() {
    echo -e "${YELLOW}[CONFIRM]${NC} 是否继续执行批量训练? (y/N): "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            echo -e "${YELLOW}[CANCELLED]${NC} 用户取消操作"
            exit 0
            ;;
    esac
}

# 主函数
main() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}Bert-VITS2 批量训练脚本${NC}"
    echo -e "${PURPLE}========================================${NC}"
    
    # 检查环境
    check_directories
    
    # 获取角色文件夹列表
    character_folders=($(get_character_folders))
    
    # 显示摘要
    show_summary "${character_folders[@]}"
    
    # 确认执行
    if [ "$confirm_before_run" = true ]; then
        confirm_execution
    fi
    
    # 记录开始时间
    start_time=$(date +%s)
    successful_characters=()
    failed_characters=()
    
    echo ""
    echo -e "${GREEN}[START]${NC} 开始批量处理..."
    
    # 逐个处理角色
    for character in "${character_folders[@]}"; do
        if process_character "$character"; then
            successful_characters+=("$character")
        else
            failed_characters+=("$character")
            echo -e "${YELLOW}[INFO]${NC} 角色 $character 处理失败，继续处理下一个角色..."
        fi
    done
    
    # 计算总耗时
    end_time=$(date +%s)
    total_time=$((end_time - start_time))
    hours=$((total_time / 3600))
    minutes=$(((total_time % 3600) / 60))
    seconds=$((total_time % 60))
    
    # 显示最终结果
    echo ""
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}批量处理完成${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${BLUE}总耗时:${NC} ${hours}小时 ${minutes}分钟 ${seconds}秒"
    echo -e "${GREEN}成功处理角色数:${NC} ${#successful_characters[@]}"
    echo -e "${RED}失败角色数:${NC} ${#failed_characters[@]}"
    
    if [ ${#successful_characters[@]} -gt 0 ]; then
        echo -e "${GREEN}成功处理的角色:${NC}"
        for char in "${successful_characters[@]}"; do
            echo -e "  ✓ $char"
        done
    fi
    
    if [ ${#failed_characters[@]} -gt 0 ]; then
        echo -e "${RED}处理失败的角色:${NC}"
        for char in "${failed_characters[@]}"; do
            echo -e "  ✗ $char"
        done
        echo ""
        echo -e "${YELLOW}[提示]${NC} 您可以单独重新处理失败的角色"
    fi
    
    echo ""
    echo -e "${BLUE}[完成]${NC} 批量训练脚本执行完毕"
}

# 捕获Ctrl+C中断信号
trap 'echo -e "\n${YELLOW}[INTERRUPTED]${NC} 脚本被用户中断"; exit 130' INT

# 执行主函数
main "$@"