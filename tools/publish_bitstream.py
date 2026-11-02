"""Publish a verified .bit and its byte-exact, headerless SPI .bin together.

Hardware/timing acceptance belongs to the calling build entry. This module
does not synthesize hardware, modify configuration packets or program Flash.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import os
import struct
import tempfile


def sha(data):
    return hashlib.sha256(data).hexdigest()


def bit_payload(data):
    """Strictly decode a Xilinx .bit header; never search for a sync substring."""
    pos = 0

    def take(n):
        nonlocal pos
        if pos + n > len(data):
            raise ValueError('Truncated Xilinx bitstream')
        value = data[pos:pos+n]
        pos += n
        return value

    def u16():
        return struct.unpack('>H', take(2))[0]

    if take(u16()) != bytes.fromhex('0ff00ff00ff00ff000'):
        raise ValueError('Invalid Xilinx bitstream magic')
    if u16() != 1:
        raise ValueError('Invalid Xilinx bitstream first-key length')
    fields = {}
    for key in b'abcd':
        if take(1) != bytes([key]):
            raise ValueError('Invalid Xilinx bitstream header sequence')
        value = take(u16())
        if not value.endswith(b'\0'):
            raise ValueError('Unterminated Xilinx bitstream header field')
        fields[chr(key)] = value[:-1].decode('ascii')
    if take(1) != b'e':
        raise ValueError('Missing Xilinx configuration payload')
    length = struct.unpack('>I', take(4))[0]
    payload = take(length)
    if pos != len(data) or not length or length % 4:
        raise ValueError('Invalid Xilinx configuration payload length')
    if bytes.fromhex('aa995566') not in payload[:256]:
        raise ValueError('Missing unswapped configuration sync word')
    return payload, fields


def publish(source, root):
    source, root = Path(source).resolve(), Path(root).resolve()
    bit = source.read_bytes()
    binary, fields = bit_payload(bit)
    if not fields['b'].lower().startswith(('7a35t', 'xc7a35t')):
        raise ValueError('Bitstream is not for the project XC7A35T device')
    directory = root / 'bit'
    directory.mkdir(parents=True, exist_ok=True)
    target_data = {directory/'Tetris.bit': bit, directory/'Tetris.bin': binary}
    old = {p: p.read_bytes() if p.exists() else None for p in target_data}
    changed = [p for p in target_data if old[p] != target_data[p]]
    stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    staged, installed, archives = {}, [], []
    try:
        # Finish conversion, parsing and staging before touching either latest file.
        for p in changed:
            with tempfile.NamedTemporaryFile(dir=directory, prefix=p.name+'.', suffix='.tmp', delete=False) as f:
                staged[p] = Path(f.name)
                f.write(target_data[p]); f.flush(); os.fsync(f.fileno())
        for p in changed:
            if old[p] is not None:
                archive = directory / ('Tetris_'+stamp+'_'+sha(old[p])[:12]+p.suffix)
                if archive.exists():
                    if archive.read_bytes() != old[p]:
                        raise ValueError('Archive hash-prefix collision')
                else:
                    with archive.open('xb') as f:
                        f.write(old[p])
                archives.append(archive.name)
        for p in changed:
            os.replace(staged[p], p)
            installed.append(p)
    except BaseException:
        # Roll back the first replacement if the second file cannot be installed.
        for p in reversed(installed):
            if old[p] is None:
                p.unlink(missing_ok=True)
            else:
                with tempfile.NamedTemporaryFile(dir=directory, suffix='.tmp', delete=False) as f:
                    rollback = Path(f.name); f.write(old[p])
                os.replace(rollback, p)
        raise
    finally:
        for p in staged.values():
            p.unlink(missing_ok=True)
    assert (directory/'Tetris.bit').read_bytes() == bit
    assert (directory/'Tetris.bin').read_bytes() == binary
    return {'pass': True, 'bit_sha256': sha(bit), 'bin_sha256': sha(binary),
            'bit_bytes': len(bit), 'bin_bytes': len(binary), 'part': fields['b'],
            'format': 'Raw SPI configuration bytes, unswapped, .bit header removed',
            'start_address': '0x00000000', 'archives': archives,
            'changed': [p.name for p in changed]}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('source', type=Path)
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument('--report', type=Path)
    a = p.parse_args()
    result = publish(a.source, a.root)
    if a.report:
        a.report.parent.mkdir(parents=True, exist_ok=True)
        a.report.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print('BIT_BIN_PUBLISH_PASS '+json.dumps(result))


if __name__ == '__main__':
    main()
