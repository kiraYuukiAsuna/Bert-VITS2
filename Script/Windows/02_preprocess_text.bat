@echo off
REM Bert-VITS2 文本预处理脚本
REM 生成训练和验证数据的文件列表
REM 用法: 02_preprocess_text.bat <dataset_name>

if "%1"=="" (
    echo 错误: 请提供数据集名称
    echo 用法: %0 ^<dataset_name^>
    echo 示例: %0 Elysia
    pause
    exit /b 1
)

set DATASET_NAME=%1

call conda activate bv2.3
python preprocess_text.py --transcription-path dataset/%DATASET_NAME%/filelists/Label.list --train-path dataset/%DATASET_NAME%/filelists/train.list --val-path dataset/%DATASET_NAME%/filelists/val.list --config-path dataset/%DATASET_NAME%/config.json