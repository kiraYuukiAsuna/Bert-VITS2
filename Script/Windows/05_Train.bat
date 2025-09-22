@echo off
REM Bert-VITS2 模型训练脚本
REM 开始训练模型
REM 用法: 04_Train.bat <dataset_name>

if "%1"=="" (
    echo 错误: 请提供数据集名称
    echo 用法: %0 ^<dataset_name^>
    echo 示例: %0 Elysia
    pause
    exit /b 1
)

set DATASET_NAME=%1

call conda activate bv2.4_jp
python train_ms.py --config dataset/%DATASET_NAME%/config.json --model dataset/%DATASET_NAME%
