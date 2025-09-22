#!/bin/bash

# Bert-VITS2 模型训练脚本
# 开始训练模型
# 用法: ./04_Train.sh <dataset_name>

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
conda activate bv2.4_jp

# 运行训练
python train_ms.py --config dataset/$DATASET_NAME/config.json --model dataset/$DATASET_NAME