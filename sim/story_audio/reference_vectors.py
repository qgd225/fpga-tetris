"""用 Python 3.11 标准库产生独立 ADPCM 参考；尚不是 RTL 或听感通过证据。"""
import array
import audioop
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURES = ROOT / "fixtures"
BUILD = ROOT / "build"
BUILD.mkdir(exist_ok=True)
manifest = json.loads((FIXTURES / "manifest.json").read_text())
for name, sha in manifest["source_sha256"].items():
    assert hashlib.sha256((FIXTURES / name).read_bytes()).hexdigest() == sha
payload = (FIXTURES / "V0.ima").read_bytes()
raw, state = audioop.adpcm2lin(payload, 2, (manifest["predictor"], manifest["index"]))
expected = array.array("h", raw)
assert len(expected) == manifest["samples"] == 6748
(BUILD / "v0_codes.mem").write_text("".join(f"{n:x}\n" for b in payload for n in (b >> 4, b & 15)))
(BUILD / "v0_expected.mem").write_text("".join(f"{s & 65535:04x}\n" for s in expected))
vectors = []
for predictor in [-32768, -32000, -1, 0, 1, 32000, 32767]:
    for index in range(89):
        for code in range(16):
            pcm, final = audioop.adpcm2lin(bytes([code * 17]), 2, (predictor, index))
            first, second = array.array("h", pcm)
            # 68 位记录：初值16/索引7/code4/前两输出16+16/最终索引7；顶端空2位。
            word = predictor & 65535
            for value, bits in [(index, 7), (code, 4), (first & 65535, 16), (second & 65535, 16), (final[1], 7)]:
                word = (word << bits) | value
            vectors.append(f"{word:017x}\n")
(BUILD / "decoder_cases.mem").write_text("".join(vectors))
print(f"REFERENCE_VECTORS_READY cases={len(vectors)} voice_samples={len(expected)} final_state={state}")
