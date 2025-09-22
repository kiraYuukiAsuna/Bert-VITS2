@echo off
REM Bert-VITS2 Clap特征生成脚本
REM 为训练数据生成Clap特征
REM 用法: 04_ClapGen.bat <dataset_name>

if "%1"=="" (
    echo 错误: 请提供数据集名称
    echo 用法: %0 ^<dataset_name^>
    echo 示例: %0 Elysia
    pause
    exit /b 1
)

set DATASET_NAME=%1

call conda activate bv2.4_zh
python clap_gen.py --config dataset/%DATASET_NAME%/config.json