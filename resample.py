import os
import argparse
from multiprocessing import Pool, cpu_count

import soundfile
import torchaudio
from tqdm import tqdm

from config import config

def process(item):
    wav_name, args = item
    wav_path = os.path.join(args.in_dir, wav_name)
    if os.path.exists(wav_path) and wav_path.lower().endswith(".wav"):
        try:
            waveform, sample_rate = torchaudio.load(wav_path)

            if sample_rate != args.sr:
                wav = torchaudio.functional.resample(
                    waveform, sample_rate, args.sr)
                sr = args.sr
            else:
                wav = waveform
                sr = sample_rate
            wav = wav.squeeze(0)  # 如果需要单声道数据

            soundfile.write(os.path.join(
                args.out_dir, wav_name), wav, sr)
            return "success", wav_name
        except Exception as e:
            print(f"Error processing {wav_path}: {e}")
            if os.path.exists(os.path.join(args.out_dir, wav_name)):
                os.remove(os.path.join(args.out_dir, wav_name))
            return "fail", wav_name


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--sr",
        type=int,
        default=config.resample_config.sampling_rate,
        help="sampling rate",
    )
    parser.add_argument(
        "--in_dir",
        type=str,
        default=config.resample_config.in_dir,
        help="path to source dir",
    )
    parser.add_argument(
        "--out_dir",
        type=str,
        default=config.resample_config.out_dir,
        help="path to target dir",
    )
    parser.add_argument(
        "--processes",
        type=int,
        default=0,
        help="cpu_processes",
    )
    args, _ = parser.parse_known_args()
    # autodl 无卡模式会识别出46个cpu
    if args.processes == 0:
        processes = cpu_count() - 2 if cpu_count() > 4 else 1
    else:
        processes = args.processes
    pool = Pool(processes=processes)

    tasks = []

    for dirpath, _, filenames in os.walk(args.in_dir):
        if not os.path.isdir(args.out_dir):
            os.makedirs(args.out_dir, exist_ok=True)
        for filename in filenames:
            if filename.lower().endswith(".wav"):
                twople = (filename, args)
                tasks.append(twople)

    successCount = 0
    failCount = 0
    failed_files = []
    for result in tqdm(
        pool.imap_unordered(process, tasks),
    ):
        status, wav_name = result
        if status == "success":
            successCount += 1
        else:
            failCount += 1
            failed_files.append(wav_name)


    pool.close()
    pool.join()

    print("音频重采样完毕!")
    print(f"成功处理音频数: {successCount}")
    print(f"处理失败音频数: {failCount}")
    if failCount > 0:
        print("处理失败的音频文件:")
        for f in failed_files:
            print(f)
