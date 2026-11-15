#!/usr/bin/env python3
"""
add_ears.py

Heuristic estimation of \l_ear and \r_ear from \head, \neck,
\l_shoulder, and \r_shoulder.

Input format example:
[\neck,0.45358437299728,0.1971271187067,0.67185008525848],
[\head,0.47389602661133,0.06588026881218,0.80839574337006],

Output: same frames, with \l_ear and \r_ear appended for frames
that contain a \head joint.
"""

import re
import argparse
import math
from typing import List, Tuple, Dict, Optional

Vec3 = Tuple[float, float, float]
Frame = List[Tuple[str, Vec3]]

# Parses entries like:
# [\neck,0.45,0.19,0.67],
# [\l_shoulder,0.50,0.19,0.68],
ENTRY_RE = re.compile(
    r'\[\s*\\?([A-Za-z_][A-Za-z0-9_]*)\s*,\s*'
    r'([-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?)\s*,\s*'
    r'([-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?)\s*,\s*'
    r'([-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?)\s*\]'
)


def vadd(*vs: Vec3) -> Vec3:
    return (sum(v[0] for v in vs), sum(v[1] for v in vs), sum(v[2] for v in vs))


def vsub(a: Vec3, b: Vec3) -> Vec3:
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def vscale(a: Vec3, s: float) -> Vec3:
    return (a[0] * s, a[1] * s, a[2] * s)


def vdot(a: Vec3, b: Vec3) -> float:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def vcross(a: Vec3, b: Vec3) -> Vec3:
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def vnorm(a: Vec3) -> float:
    return math.sqrt(vdot(a, a))


def vnormalize(a: Vec3) -> Optional[Vec3]:
    n = vnorm(a)
    if n < 1e-12:
        return None
    return (a[0] / n, a[1] / n, a[2] / n)


def project_perp(v: Vec3, axis: Vec3) -> Optional[Vec3]:
    """Project v onto the plane perpendicular to axis, then normalize."""
    d = vdot(v, axis)
    p = vsub(v, vscale(axis, d))
    return vnormalize(p)


def get_joint(frame: Frame, name: str) -> Optional[Vec3]:
    for n, p in frame:
        if n == name:
            return p
    return None


def parse_frames(text: str) -> List[Frame]:
    frames: List[Frame] = []
    cur: Frame = []

    for m in ENTRY_RE.finditer(text):
        name = m.group(1)
        p = (float(m.group(2)), float(m.group(3)), float(m.group(4)))

        # In this log, a new frame starts at each \neck entry.
        if name == "neck" and cur:
            frames.append(cur)
            cur = []

        cur.append((name, p))

    if cur:
        frames.append(cur)

    return frames


def estimate_ears(
    frame: Frame,
    lateral_ratio: float,
    vertical_ratio: float,
    forward_ratio: float,
) -> Optional[Tuple[Vec3, Vec3]]:
    head = get_joint(frame, "head")
    neck = get_joint(frame, "neck")
    ls = get_joint(frame, "l_shoulder")
    rs = get_joint(frame, "r_shoulder")

    if head is None or neck is None or ls is None or rs is None:
        return None

    shoulder_vec = vsub(ls, rs)
    shoulder_width = vnorm(shoulder_vec)
    if shoulder_width < 1e-9:
        return None

    # "up" is from neck toward head. In this data y is roughly downward,
    # so this vector usually has a negative y component.
    up = vnormalize(vsub(head, neck))
    if up is None:
        up = (0.0, -1.0, 0.0)

    # "left" is derived from shoulder line, projected perpendicular to up.
    left = project_perp(shoulder_vec, up)
    if left is None:
        left = (1.0, 0.0, 0.0)

    # A third axis for a small front/back ear offset.
    forward = vnormalize(vcross(up, left))
    if forward is None:
        forward = (0.0, 0.0, 1.0)

    # Offsets are in shoulder-width units.
    # Tune these constants if the ears look too wide/narrow or too far forward.
    lateral = lateral_ratio * shoulder_width
    vertical = vertical_ratio * shoulder_width
    forward_off = forward_ratio * shoulder_width

    base = vadd(head, vscale(up, vertical), vscale(forward, forward_off))

    l_ear = vadd(base, vscale(left, lateral))
    r_ear = vadd(base, vscale(left, -lateral))

    return l_ear, r_ear


def write_frames(
    frames: List[Frame],
    out_path: str,
    lateral_ratio: float,
    vertical_ratio: float,
    forward_ratio: float,
) -> None:
    n_with_head = 0

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("[\n")

        for frame in frames:
            for name, p in frame:
                f.write(
                    f"[\\{name},{p[0]:.8f},{p[1]:.8f},{p[2]:.8f}],\n"
                )

            ears = estimate_ears(
                frame,
                lateral_ratio=lateral_ratio,
                vertical_ratio=vertical_ratio,
                forward_ratio=forward_ratio,
            )

            if ears is not None:
                n_with_head += 1
                l_ear, r_ear = ears
                f.write(
                    f"[\\l_ear,{l_ear[0]:.8f},{l_ear[1]:.8f},{l_ear[2]:.8f}],\n"
                )
                f.write(
                    f"[\\r_ear,{r_ear[0]:.8f},{r_ear[1]:.8f},{r_ear[2]:.8f}],\n"
                )

        f.write("]\n")

    print(f"Frames total: {len(frames)}")
    print(f"Frames with estimated ears: {n_with_head}")
    print(f"Wrote: {out_path}")


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Estimate \\l_ear and \\r_ear from head/neck/shoulders."
    )
    ap.add_argument("input", help="Input joints log file")
    ap.add_argument("output", help="Output joints log file")
    ap.add_argument(
        "--lateral-ratio",
        type=float,
        default=0.18,
        help="Ear lateral offset as fraction of shoulder width. Default: 0.18",
    )
    ap.add_argument(
        "--vertical-ratio",
        type=float,
        default=0.0,
        help="Ear vertical offset along neck->head as fraction of shoulder width. Default: 0.0",
    )
    ap.add_argument(
        "--forward-ratio",
        type=float,
        default=0.0,
        help="Ear forward/back offset as fraction of shoulder width. Default: 0.0",
    )
    args = ap.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        text = f.read()

    frames = parse_frames(text)
    write_frames(
        frames=frames,
        out_path=args.output,
        lateral_ratio=args.lateral_ratio,
        vertical_ratio=args.vertical_ratio,
        forward_ratio=args.forward_ratio,
    )


if __name__ == "__main__":
    main()