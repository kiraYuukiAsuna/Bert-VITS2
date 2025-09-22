@echo off
REM Bert-VITS2 重采样脚本
REM 将音频文件重采样为指定采样率
REM 用法: 01_Resample.bat <dataset_name>

if "%1"=="" (
    echo 错误: 请提供数据集名称
    echo 用法: %0 ^<dataset_name^>
    echo 示例: %0 Elysia
    pause
    exit /b 1
)

set DATASET_NAME=%1

call conda activate bv2.4_zh
python resample.py --sr 44100 --in_dir dataset/%DATASET_NAME%/AudioRaw --out_dir dataset/%DATASET_NAME%/wavs

echo "重采样完成: dataset/%DATASET_NAME%/wavs"
echo "覆盖原始音频文件"

if exist dataset\%DATASET_NAME%\AudioRaw_Bak (
    rmdir /s /q dataset\%DATASET_NAME%\AudioRaw_Bak
    echo "已删除旧的备份目录 AudioRaw_Bak"
)

rename dataset\%DATASET_NAME%\AudioRaw dataset\%DATASET_NAME%\AudioRaw_Bak
rename dataset\%DATASET_NAME%\wavs dataset\%DATASET_NAME%\AudioRaw
echo "原始音频文件已覆盖"
