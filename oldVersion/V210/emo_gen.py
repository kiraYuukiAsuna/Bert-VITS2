import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset
import torchaudio
from transformers import Wav2Vec2Processor
from transformers.models.wav2vec2.modeling_wav2vec2 import (
    Wav2Vec2Model,
    Wav2Vec2PreTrainedModel,
)

from config import config


class RegressionHead(nn.Module):
    r"""Classification head."""

    def __init__(self, config):
        super().__init__()

        self.dense = nn.Linear(config.hidden_size, config.hidden_size)
        self.dropout = nn.Dropout(config.final_dropout)
        self.out_proj = nn.Linear(config.hidden_size, config.num_labels)

    def forward(self, features, **kwargs):
        x = features
        x = self.dropout(x)
        x = self.dense(x)
        x = torch.tanh(x)
        x = self.dropout(x)
        x = self.out_proj(x)

        return x


class EmotionModel(Wav2Vec2PreTrainedModel):
    r"""Speech emotion classifier."""

    def __init__(self, config):
        super().__init__(config)

        self.config = config
        self.wav2vec2 = Wav2Vec2Model(config)
        self.classifier = RegressionHead(config)
        self.init_weights()

    def forward(
        self,
        input_values,
    ):
        outputs = self.wav2vec2(input_values)
        hidden_states = outputs[0]
        hidden_states = torch.mean(hidden_states, dim=1)
        logits = self.classifier(hidden_states)

        return hidden_states, logits


class AudioDataset(Dataset):
    def __init__(self, list_of_wav_files, sr, processor):
        self.list_of_wav_files = list_of_wav_files
        self.processor = processor
        self.sr = sr

    def __len__(self):
        return len(self.list_of_wav_files)

    def __getitem__(self, idx):
        wav_file = self.list_of_wav_files[idx]
        waveform, sample_rate = torchaudio.load(wav_file)

        if sample_rate != self.sr:
            wav = torchaudio.functional.resample(
                waveform, sample_rate, self.sr)
            sr = self.sr
        else:
            wav = waveform
            sr = sample_rate
        audio_data = wav.squeeze(0)  # 如果需要单声道数据
        processed_data = self.processor(audio_data, sampling_rate=self.sr)[
            "input_values"
        ][0]
        return torch.from_numpy(processed_data)


device = config.emo_gen_config.device
model_name = "./emotional/wav2vec2-large-robust-12-ft-emotion-msp-dim"
processor = Wav2Vec2Processor.from_pretrained(model_name)
model = EmotionModel.from_pretrained(model_name).to(device)


def process_func(
    x: np.ndarray,
    sampling_rate: int,
    model: EmotionModel,
    processor: Wav2Vec2Processor,
    device: str,
    embeddings: bool = False,
) -> np.ndarray:
    r"""Predict emotions or extract embeddings from raw audio signal."""
    model = model.to(device)
    y = processor(x, sampling_rate=sampling_rate)
    y = y["input_values"][0]
    y = torch.from_numpy(y).unsqueeze(0).to(device)

    # run through model
    with torch.no_grad():
        y = model(y)[0 if embeddings else 1]

    # convert to numpy
    y = y.detach().cpu().numpy()

    return y


def get_emo(path):
    waveform, sample_rate = torchaudio.load(path)

    if sample_rate != 16000:
        wav = torchaudio.functional.resample(waveform, sample_rate, 16000)
        sr = 16000
    else:
        wav = waveform
        sr = sample_rate
    wav = wav.squeeze(0)  # 如果需要单声道数据
    return process_func(
        np.expand_dims(wav, 0).astype(np.float64),
        sr,
        model,
        processor,
        device,
        embeddings=True,
    ).squeeze(0)
