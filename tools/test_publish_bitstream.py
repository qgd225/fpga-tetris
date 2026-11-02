"""Release conversion, idempotency, archive and rollback checks (no FPGA rebuild)."""
from pathlib import Path
import argparse
import json
import tempfile
from unittest.mock import patch
import publish_bitstream as pub


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--vivado-reference', type=Path, required=True)
    a = p.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = a.output.resolve()
    if not output.is_relative_to(root/'temporary'):
        raise ValueError('Test output must stay under temporary/')
    output.mkdir(parents=True, exist_ok=True)
    bit = (root/'bit/Tetris.bit').read_bytes()
    binary, _ = pub.bit_payload(bit)
    assert binary == a.vivado_reference.read_bytes()
    checks = ['byte-exact match to Vivado write_cfgmem SPIx1']
    for bad in [b'', bit[:10], bit[:-1], bit+b'x', b'xx'+bit[2:]]:
        try:
            pub.bit_payload(bad)
        except (ValueError, UnicodeError):
            continue
        raise AssertionError('Malformed bitstream accepted')
    checks.append('reject malformed/truncated/trailing payloads')
    with tempfile.TemporaryDirectory(dir=output) as directory:
        r = Path(directory)
        src = r/'candidate.bit'; src.write_bytes(bit)
        first = pub.publish(src, r)
        assert len(first['changed']) == 2 and not first['archives']
        targets = [r/'bit/Tetris.bit', r/'bit/Tetris.bin']
        times = [q.stat().st_mtime_ns for q in targets]
        again = pub.publish(src, r)
        assert not again['changed'] and not again['archives']
        assert times == [q.stat().st_mtime_ns for q in targets]
        checks += ['first paired publish', 'identical pair preserves timestamps/no archive']
        # Synthetic changed payload is confined to this temporary fault fixture.
        changed = bit[:-1] + bytes([bit[-1] ^ 1])
        src.write_bytes(changed)
        result = pub.publish(src, r)
        assert len(result['archives']) == 2
        assert sorted(q.read_bytes() for q in (r/'bit').glob('Tetris_*.bit')) == [bit]
        assert sorted(q.read_bytes() for q in (r/'bit').glob('Tetris_*.bin')) == [binary]
        checks.append('different pair archives each exact previous file')
        targets[1].unlink()
        result = pub.publish(targets[0], r)
        assert result['changed'] == ['Tetris.bin']
        assert pub.bit_payload(targets[0].read_bytes())[0] == targets[1].read_bytes()
        checks.append('unchanged latest bit repairs absent bin')
        before = [q.read_bytes() for q in targets]
        src.write_bytes(bit)
        replace = pub.os.replace
        failed = False

        def fault(source, target):
            nonlocal failed
            if Path(target).name == 'Tetris.bin' and not failed:
                failed = True
                raise PermissionError('Injected second-file replacement failure')
            return replace(source, target)

        try:
            with patch.object(pub.os, 'replace', side_effect=fault):
                pub.publish(src, r)
        except PermissionError:
            pass
        else:
            raise AssertionError('Injected replacement failure was ignored')
        assert before == [q.read_bytes() for q in targets]
        assert not list((r/'bit').glob('*.tmp'))
        checks.append('second replacement failure rolls back pair and cleans staging')
        src.write_bytes(bit[:-1])
        try:
            pub.publish(src, r)
        except ValueError:
            pass
        else:
            raise AssertionError('Malformed candidate was published')
        assert before == [q.read_bytes() for q in targets]
        checks.append('invalid candidate leaves published pair intact')
    result = {'pass': True, 'checks': checks, 'bit_sha256': pub.sha(bit),
              'bin_sha256': pub.sha(binary), 'bin_bytes': len(binary)}
    (output/'tests.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print('BIT_BIN_TESTS_PASS', len(checks))


if __name__ == '__main__':
    main()
