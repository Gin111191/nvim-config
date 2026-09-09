#!/usr/bin/env python3
"""Regenerate the cterm00..cterm0F block in lua/plugins/colortheme.lua.

Terminals without 24-bit colour (macOS Terminal.app) cannot use the hex values
in DUSK_NAVY, so base16-nvim needs a second set of numbers: indices into the
xterm 256-colour palette. This picks the nearest one for each colour.

Only indices 16-255 are candidates. 0-15 are whatever the terminal profile
sets them to, so they are not a fixed target; 16-255 are fixed by the xterm
spec and render the same everywhere.

Edited DUSK_NAVY? Run this and paste the block it prints back into
colortheme.lua, replacing the existing cterm lines.

    python3 tools/nearest256.py
"""
import math

CUBE = [0, 95, 135, 175, 215, 255]

# Keep in step with DUSK_NAVY in lua/plugins/colortheme.lua.
DUSK_NAVY = {
    'base00': '#1d2837', 'base01': '#26334a', 'base02': '#3D4A6B', 'base03': '#93a1b3',
    'base04': '#A9AFC6', 'base05': '#EDEEF7', 'base06': '#f2f3f9', 'base07': '#ffffff',
    'base08': '#D18A9E', 'base09': '#E0C05A', 'base0A': '#C9A227', 'base0B': '#8FBFA9',
    'base0C': '#8FBBD4', 'base0D': '#7D9BD4', 'base0E': '#A99AD4', 'base0F': '#B4637A',
}

# Colours a reader has to tell apart: the eight syntax colours, comments, normal
# text. These get distinct indices even when a closer one is already spoken for.
# The rest (backgrounds, the near-whites) may share.
DISTINCT = ['base08', 'base0B', 'base0D', 'base0A', 'base0C', 'base0E', 'base09',
            'base0F', 'base05', 'base03']
REST = ['base00', 'base01', 'base02', 'base04', 'base06', 'base07']


def palette():
    """The fixed part of the xterm-256 palette: 6x6x6 cube, then 24 greys."""
    out = {}
    for i in range(216):
        r, g, b = i // 36, (i // 6) % 6, i % 6
        out[16 + i] = (CUBE[r], CUBE[g], CUBE[b])
    for i in range(24):
        v = 8 + 10 * i
        out[232 + i] = (v, v, v)
    return out


def redmean(c1, c2):
    """Cheap perceptual distance. Beats plain RGB on the mid-tone blues and
    greens this palette is mostly made of."""
    r1, g1, b1 = c1
    r2, g2, b2 = c2
    rm = (r1 + r2) / 2
    dr, dg, db = r1 - r2, g1 - g2, b1 - b2
    return math.sqrt((2 + rm / 256) * dr ** 2 + 4 * dg ** 2 + (2 + (255 - rm) / 256) * db ** 2)


def hex2rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def solve(scheme=DUSK_NAVY):
    pal = palette()
    taken, result = set(), {}
    for name in DISTINCT + REST:
        target = hex2rgb(scheme[name])
        pool = pal.items() if name in REST else ((i, c) for i, c in pal.items() if i not in taken)
        idx, rgb = min(pool, key=lambda kv: redmean(target, kv[1]))
        if name in DISTINCT:
            taken.add(idx)
        result[name] = (idx, rgb)
    return result


def main():
    result = solve()
    for name in sorted(result):
        idx, rgb = result[name]
        print(f"  cterm{name[4:]} = {idx}, -- #{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}")

    # The checks that matter: readable colours never collide, every index is in
    # the fixed range, and a colour that IS in the palette maps to itself.
    assert len({result[n][0] for n in DISTINCT}) == len(DISTINCT), "two readable colours collide"
    assert all(16 <= v[0] <= 255 for v in result.values()), "index outside 16-255"
    assert result['base07'] == (231, (255, 255, 255)), "pure white must map exactly"
    pal = palette()
    assert min(pal, key=lambda i: redmean((95, 175, 215), pal[i])) == 74, "cube lookup broken"
    assert min(pal, key=lambda i: redmean((238, 238, 238), pal[i])) == 255, "grey lookup broken"
    print("\nchecks OK")


if __name__ == '__main__':
    main()
