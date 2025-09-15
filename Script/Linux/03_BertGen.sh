#!/bin/bash

# Bert-VITS2 Bert特征生成脚本
# 为训练数据生成Bert特征
# 用法: ./03_BertGen.sh <dataset_name>

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
conda activate bv2.3

# 运行Bert特征生成
python bert_gen.py --config dataset/$DATASET_NAME/config.json