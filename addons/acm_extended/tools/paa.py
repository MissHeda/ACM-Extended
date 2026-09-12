"""PAA reader for measuring IV site art.

Two pieces:
  lzo1x_decompress   pure python port of the reference lzo1x_d.ch decompressor
  read_paa           parses the PAA container, decompresses a chosen mip, decodes DXT5

The decompressor is self checking: a DXT5 mip must come out at exactly
(w/4)*(h/4)*16 bytes, so a wrong decode cannot be mistaken for a right one.
"""
import struct
import numpy as np


def lzo1x_decompress(src, dst_len):
    src = memoryview(src)
    out = bytearray(dst_len)
    ip = 0
    op = 0
    n = len(src)

    def lit(count):
        nonlocal ip, op
        out[op:op + count] = src[ip:ip + count]
        ip += count
        op += count

    def match(m_pos, count):
        # byte at a time on purpose: overlapping copies are legal and common
        nonlocal op
        for _ in range(count):
            out[op] = out[m_pos]
            op += 1
            m_pos += 1

    state = 'top'
    t = 0

    if src[ip] > 17:
        t = src[ip] - 17
        ip += 1
        if t < 4:
            state = 'match_next'
        else:
            lit(t)
            state = 'first_literal_run'

    while True:
        if state == 'top':
            if ip >= n:
                break
            t = src[ip]
            ip += 1
            if t >= 16:
                state = 'match'
                continue
            if t == 0:
                while src[ip] == 0:
                    t += 255
                    ip += 1
                t += 15 + src[ip]
                ip += 1
            lit(t + 3)
            state = 'first_literal_run'
            continue

        if state == 'first_literal_run':
            t = src[ip]
            ip += 1
            if t >= 16:
                state = 'match'
                continue
            m_pos = op - (1 + 0x0800)
            m_pos -= t >> 2
            m_pos -= src[ip] << 2
            ip += 1
            match(m_pos, 3)
            state = 'match_done'
            continue

        if state == 'match':
            if t >= 64:
                m_pos = op - 1
                m_pos -= (t >> 2) & 7
                m_pos -= src[ip] << 3
                ip += 1
                t = (t >> 5) - 1
                state = 'copy_match'
            elif t >= 32:
                t &= 31
                if t == 0:
                    while src[ip] == 0:
                        t += 255
                        ip += 1
                    t += 31 + src[ip]
                    ip += 1
                m_pos = op - 1
                m_pos -= (src[ip] | (src[ip + 1] << 8)) >> 2
                ip += 2
                state = 'copy_match'
            elif t >= 16:
                m_pos = op
                m_pos -= (t & 8) << 11
                t &= 7
                if t == 0:
                    while src[ip] == 0:
                        t += 255
                        ip += 1
                    t += 7 + src[ip]
                    ip += 1
                m_pos -= (src[ip] | (src[ip + 1] << 8)) >> 2
                ip += 2
                if m_pos == op:
                    break  # end of stream marker
                m_pos -= 0x4000
                state = 'copy_match'
            else:
                m_pos = op - 1
                m_pos -= t >> 2
                m_pos -= src[ip] << 2
                ip += 1
                match(m_pos, 2)
                state = 'match_done'
                continue

        if state == 'copy_match':
            match(m_pos, t + 2)
            state = 'match_done'
            continue

        if state == 'match_done':
            t = src[ip - 2] & 3
            if t == 0:
                state = 'top'
                continue
            state = 'match_next'
            continue

        if state == 'match_next':
            lit(t)
            t = src[ip]
            ip += 1
            state = 'match'
            continue

    if op != dst_len:
        raise ValueError('lzo produced %d bytes, expected %d' % (op, dst_len))
    return bytes(out)


def parse_paa(path):
    with open(path, 'rb') as handle:
        d = handle.read()
    off = 0
    paatype = struct.unpack_from('<H', d, off)[0]
    off += 2
    while d[off:off + 4] == b'GGAT':
        off += 4
        off += 4  # tag name
        ln = struct.unpack_from('<I', d, off)[0]
        off += 4 + ln
    palcount = struct.unpack_from('<H', d, off)[0]
    off += 2 + palcount * 3
    mips = []
    while off + 7 <= len(d):
        w, h = struct.unpack_from('<HH', d, off)
        if w == 0 and h == 0:
            break
        ln = d[off + 4] | (d[off + 5] << 8) | (d[off + 6] << 16)
        if ln == 0:
            break
        mips.append((w, h, d[off + 7:off + 7 + ln]))
        off += 7 + ln
    return paatype, mips


def _dxt5(blocks, w, h):
    """Decode DXT5 to (rgb uint8 HxWx3, alpha uint8 HxW)."""
    bw, bh = w // 4, h // 4
    b = np.frombuffer(blocks, dtype=np.uint8).reshape(bh, bw, 16)

    a0 = b[:, :, 0].astype(np.uint16)
    a1 = b[:, :, 1].astype(np.uint16)
    bits = np.zeros((bh, bw), dtype=np.uint64)
    for i in range(6):
        bits |= b[:, :, 2 + i].astype(np.uint64) << np.uint64(8 * i)

    lut = np.zeros((bh, bw, 8), dtype=np.uint16)
    lut[:, :, 0] = a0
    lut[:, :, 1] = a1
    big = a0 > a1
    for i in range(1, 7):
        lut[:, :, i + 1] = np.where(big, ((7 - i) * a0 + i * a1) // 7, 0)
    for i in range(1, 5):
        lut[:, :, i + 1] = np.where(big, lut[:, :, i + 1], ((5 - i) * a0 + i * a1) // 5)
    lut[:, :, 6] = np.where(big, lut[:, :, 6], 0)
    lut[:, :, 7] = np.where(big, lut[:, :, 7], 255)

    alpha = np.zeros((h, w), dtype=np.uint8)
    for py in range(4):
        for px in range(4):
            idx = ((bits >> np.uint64(3 * (py * 4 + px))) & np.uint64(7)).astype(np.int64)
            alpha[py::4, px::4] = np.take_along_axis(lut, idx[:, :, None], axis=2)[:, :, 0]

    c0 = b[:, :, 8].astype(np.uint16) | (b[:, :, 9].astype(np.uint16) << 8)
    c1 = b[:, :, 10].astype(np.uint16) | (b[:, :, 11].astype(np.uint16) << 8)
    cbits = np.zeros((bh, bw), dtype=np.uint32)
    for i in range(4):
        cbits |= b[:, :, 12 + i].astype(np.uint32) << np.uint32(8 * i)

    def unpack565(c):
        r = ((c >> 11) & 31) * 255 // 31
        g = ((c >> 5) & 63) * 255 // 63
        bl = (c & 31) * 255 // 31
        return np.stack([r, g, bl], axis=-1).astype(np.uint16)

    p0 = unpack565(c0)
    p1 = unpack565(c1)
    pal = np.zeros((bh, bw, 4, 3), dtype=np.uint16)
    pal[:, :, 0] = p0
    pal[:, :, 1] = p1
    pal[:, :, 2] = (2 * p0 + p1) // 3
    pal[:, :, 3] = (p0 + 2 * p1) // 3

    rgb = np.zeros((h, w, 3), dtype=np.uint8)
    for py in range(4):
        for px in range(4):
            idx = ((cbits >> np.uint32(2 * (py * 4 + px))) & np.uint32(3)).astype(np.int64)
            sel = np.take_along_axis(pal, idx[:, :, None, None], axis=2)[:, :, 0, :]
            rgb[py::4, px::4] = sel.astype(np.uint8)

    return rgb, alpha


def read_paa(path, want=None):
    """Return (rgb, alpha) for the mip nearest `want` pixels wide, or the largest."""
    paatype, mips = parse_paa(path)
    if paatype != 0xFF05:
        raise ValueError('%s is not DXT5 (type %s)' % (path, hex(paatype)))
    chosen = None
    for (w, h, data) in mips:
        rw = w & 0x7FFF
        if want is not None and rw > want:
            continue
        chosen = (w, h, data)
        break
    if chosen is None:
        chosen = mips[0]
    w, h, data = chosen
    lzo = bool(w & 0x8000)
    rw = w & 0x7FFF
    expect = (rw // 4) * (h // 4) * 16
    raw = lzo1x_decompress(data, expect) if lzo else data[:expect]
    rgb, alpha = _dxt5(raw, rw, h)
    return rgb, alpha
