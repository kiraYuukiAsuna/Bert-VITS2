#!/bin/bash

# Bert-VITS2 重采样脚本
# 将音频文件重采样为指定采样率
# 用法: ./01_Resample.sh <dataset_name>

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

# 运行重采样
python resample.py --sr 44100 --in_dir dataset/$DATASET_NAME/AudioRaw --out_dir dataset/$DATASET_NAME/wavs

echo "重采样完成: dataset/$DATASET_NAME/wavs"
echo "覆盖原始音频文件"
mv dataset/$DATASET_NAME/AudioRaw dataset/$DATASET_NAME/AudioRaw_Bak
mv dataset/$DATASET_NAME/wavs dataset/$DATASET_NAME/AudioRaw
echo "原始音频文件已覆盖"