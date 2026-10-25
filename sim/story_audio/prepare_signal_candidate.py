"""从已有 V0 准备轻噪声/词间停顿候选；不覆盖源素材，不自动接入工程。"""
import array
import audioop
import hashlib
import json
import math
import random
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "sim/story_audio/fixtures/V0_clean.wav"
OUT = ROOT / "docs/assets/story_audio"
OUT.mkdir(parents=True, exist_ok=True)
with wave.open(str(SOURCE), "rb") as w:
    assert (w.getframerate(), w.getnchannels(), w.getsampwidth()) == (8000, 1, 2)
    original = array.array("h", w.readframes(w.getnframes()))
# 0.26--0.28 秒处为原样音两词之间的低能量段；保留每一个原采样。
pause_at, pause_length = 2160, 1280
before, after = original[pause_at-1], original[pause_at]
bridge = [round(before * (1-i/40)) if i<40 else
          (round(after * ((i-(pause_length-40))/40)) if i>=pause_length-40 else 0)
          for i in range(pause_length)]
expanded = list(original[:pause_at]) + bridge + list(original[pause_at:])
rng = random.Random(7)
filtered = 0.0
signal = []
for i, value in enumerate(expanded):
    filtered = 0.75 * filtered + 0.25 * rng.uniform(-96, 96)
    envelope = min(1.0, i/40, (len(expanded)-1-i)/40)
    signal.append(max(-32768, min(32767, value + round(filtered*envelope))))
clean = array.array("h", signal)
payload, _ = audioop.lin2adpcm(clean.tobytes(), 2, (0, 0))
raw, _ = audioop.adpcm2lin(payload, 2, (0, 0))
decoded = array.array("h", raw)
assert len(decoded) == len(original)+pause_length == 8028 <= 8192
with wave.open(str(OUT / "V0_signal_preview.wav"), "wb") as w:
    w.setparams((1, 2, 8000, 0, "NONE", "not compressed")); w.writeframes(raw)
(OUT / "V0_signal_candidate.ima").write_bytes(payload)
noise = sum((a-b)**2 for a,b in zip(clean, decoded))
manifest = {"id":"V0", "text":"YOU CAME.", "status":"offline_signal_candidate_not_integrated_not_auditioned",
    "voice":"Microsoft Zira Desktop", "rate_hz":8000, "predictor":0, "index":0, "nibble_order":"high_first",
    "samples":len(decoded), "seconds":len(decoded)/8000, "word_count":2,
    "noise_profile":"seed7 lowpass white +/-96, 5ms edge fade; no syllable deletion",
    "pause_markers":[{"source_sample":pause_at, "added_samples":pause_length, "seconds":pause_length/8000}],
    "peak":max(abs(x) for x in decoded), "payload_bytes":len(payload), "ramb36_payload_tiles":1,
    "snr_db_vs_precompression":round(10*math.log10(sum(x*x for x in clean)/max(1,noise)),2),
    "source_sha256":hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    "payload_sha256":hashlib.sha256(payload).hexdigest()}
(OUT / "V0_signal_candidate.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
print(json.dumps(manifest))
