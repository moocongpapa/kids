"""Read 16-bit PCM RIFF WAVE, including Core Audio's extensible header."""
import array
import struct


def read_pcm(path):
    raw = path.read_bytes()
    if raw[:4] != b'RIFF' or raw[8:12] != b'WAVE':
        raise ValueError('Expected little-endian RIFF WAVE')
    offset, fmt, data = 12, None, None
    while offset + 8 <= len(raw):
        name, length = raw[offset:offset+4], struct.unpack_from('<I', raw, offset+4)[0]
        body = raw[offset+8:offset+8+length]
        if len(body) != length:
            raise ValueError('Truncated WAVE chunk')
        if name == b'fmt ': fmt = body
        if name == b'data': data = body
        offset += 8 + length + length % 2
    if fmt is None or data is None or len(fmt) < 16:
        raise ValueError('Missing WAVE format or samples')
    tag, channels, rate = struct.unpack_from('<HHI', fmt)
    bits = struct.unpack_from('<H', fmt, 14)[0]
    if tag == 65534:
        pcm_guid = bytes.fromhex('0100000000001000800000aa00389b71')
        if len(fmt) < 40 or fmt[24:40] != pcm_guid:
            raise ValueError('Only integer PCM extensible WAVE is supported')
    elif tag != 1:
        raise ValueError('Only integer PCM WAVE is supported')
    if bits != 16 or channels < 1 or rate < 8000 or len(data) % (2*channels):
        raise ValueError('Invalid PCM format')
    samples = array.array('h', data)
    if not samples:
        raise ValueError('No audio samples')
    return rate, channels, samples
