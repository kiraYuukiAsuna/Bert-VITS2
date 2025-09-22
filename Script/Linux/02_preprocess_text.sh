#!/bin/bash

# Bert-VITS2 文本预处理脚本
# 生成训练和验证数据的文件列表
# 用法: ./02_preprocess_text.sh <dataset_name>

# 检查参数
if [ $# -eq 0 ]; then
    echo "错误: 请提供数据集名称"
    echo "用法: $0 <dataset_name>"
    echo "示例: $0 Elysia"
    exit 1
fi

DATASET_NAME=$1

# 初始化 conda 并激活环境
eval "$(conda shell.bash hook)"
conda activate bv2.4_zh

# 运行文本预处理
python preprocess_text.py --transcription-path dataset/$DATASET_NAME/filelists/Label.list --train-path dataset/$DATASET_NAME/filelists/train.list --val-path dataset/$DATASET_NAME/filelists/val.list --config-path dataset/$DATASET_NAME/config.json