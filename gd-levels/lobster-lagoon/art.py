"""Reusable decoration builders for Lobster Lagoon.

Everything here is NoTouch decoration (key 121), so it can sit behind the
player without affecting gameplay. Shapes are built from convex polygons that
gdkit.Level.poly converts into squares + decorative slopes.
"""

import math
import random

import gdkit as K

# colour channels (set up in build_level.py)
ROCK, ROCK_GLOW, RED, RED_DARK, RED_LIGHT = 1, 2, 3, 4, 5
KELP, KELP_DARK, BUBBLE, RAYS, HAZARD = 6, 7, 8, 9, 10
WOOD, ROPE, BLACK, FAR_ROCK, SAND = 11, 12, 13, 14, 15
STEEL, FIRE, STEAM, WHITE, CORAL = 16, 17, 18, 19, 20
STAR, GOLD, TOP_EDGE, FAR_LOBSTER, NET = 21, 22, 23, 24, 25
WOOD_DARK, STEEL_DARK, HEAT_GLOW, FISH = 26, 27, 28, 29


def _xf(pts, ox, oy, s, flip):
    f = -1 if flip else 1
    return [(ox + f * x * s, oy + y * s) for x, y in pts]


def lobster(lv, ox, oy, s=1.0, flip=False, z_layer=K.B2, z=0, palette=None,
            groups=None, claw_group=None, claw_pivot=None, detail=True):
    """Side-view lobster, facing right (or left with flip). (ox, oy) is the
    middle of the carapace; one lobster unit = `s` GD units. The full body is
    about 140 units long and 60 tall (antennae included).

    If claw_group/claw_pivot are given, the movable pincer of the near claw
    goes into claw_group and a tiny pivot object into claw_pivot so a Rotate
    trigger can make it snap."""
    red, dark, light = palette or (RED, RED_DARK, RED_LIGHT)
    g = list(groups or [])

    def P(pts, col, dz=0, extra=None):
        gg = g + (extra or [])
        return lv.poly(_xf(pts, ox, oy, s, flip), col, z_layer=z_layer,
                       z_order=z + dz, groups=gg or None)

    def E(cx, cy, rx, ry, col, rot=0.0, dz=0, n=None):
        f = -1 if flip else 1
        return lv.ellipse(ox + f * cx * s, oy + cy * s, rx * s, ry * s, col,
                          rot=rot * f, n=n, z_layer=z_layer, z_order=z + dz,
                          groups=g or None)

    def L(x0, y0, x1, y1, t, col, dz=0, extra=None):
        f = -1 if flip else 1
        gg = g + (extra or [])
        return lv.segment(ox + f * x0 * s, oy + y0 * s, ox + f * x1 * s,
                          oy + y1 * s, max(t * s, 1.2), col, z_layer=z_layer,
                          z_order=z + dz, groups=gg or None)

    # far-side claw and legs (darker, behind the body)
    for i, lx in enumerate((-2, 5, 12, 19)):
        L(lx, -5, lx - 3, -13, 1.6, dark, -3)
        L(lx - 3, -13, lx - 6, -19, 1.3, dark, -3)
    L(18, 0, 30, 4, 4.2, dark, -3)
    L(30, 4, 40, 10, 3.6, dark, -3)
    E(50, 12, 10, 5.2, dark, rot=18, dz=-3)
    P([(56, 16), (70, 21), (57, 12.5)], dark, -3)
    P([(56, 11), (69, 14), (55, 8)], dark, -3)

    # tail fan
    P([(-44, 2), (-58, 6), (-60, 0), (-44, -3)], dark, 1)
    P([(-45, 2.5), (-55, 12), (-60, 8), (-50, 1)], red, 1)
    P([(-45, -3), (-55, -11), (-59.5, -7), (-50, -1.5)], red, 1)
    P([(-46, 0.5), (-60, 4), (-61.5, -2.5), (-46, -2)], light, 2)

    # abdomen: five segments that taper and curl slightly down
    segs = [(-44, -36, 6.0, -3.5), (-36, -28, 7.6, -4.6), (-28, -20, 8.8, -5.4),
            (-20, -12, 9.8, -6.0), (-12, -4, 10.4, -6.4)]
    for i, (a, b, top, bot) in enumerate(segs):
        pts = [(a, bot + 0.6), (a + 1.2, bot - 0.4), (b - 1.0, bot - 0.6),
               (b, bot + 0.4), (b, top - 0.6), (b - 1.4, top + 0.3),
               (a + 1.2, top + 0.1), (a, top - 0.8)]
        P(pts, red, 3 + i)
        P([(a + 1.4, top - 2.6), (b - 1.4, top - 2.2), (b - 1.8, top - 0.4),
           (a + 1.8, top - 0.8)], light, 4 + i)
        P([(a + 0.6, bot + 0.2), (b - 0.6, bot), (b - 1, bot + 2.0),
           (a + 1, bot + 2.2)], dark, 4 + i)
        # swimmerets
        L((a + b) / 2, bot, (a + b) / 2 - 1.5, bot - 3.5, 1.0, dark, 2)

    # carapace
    E(8, 3.5, 21, 11.5, red, rot=-4, dz=10)
    E(6, 7.5, 16, 5.2, light, rot=-5, dz=11)
    E(9, -3.5, 18, 4.0, dark, rot=-2, dz=11)
    if detail:
        L(-6, 10, 2, -4, 1.0, dark, 12)          # cervical groove
        for sx, sy in ((14, 6), (19, 3), (10, 1), (3, 5)):
            E(sx, sy, 1.3, 1.0, dark, dz=12, n=8)
    # head + rostrum
    P([(24, 9), (41, 6.5), (40, 5.0), (25, 1.5)], red, 12)
    P([(26, 7.5), (39, 6.2), (26, 5.0)], light, 13)
    # eye stalk + eye
    L(25, 8, 28, 12, 2.2, dark, 13)
    E(28.5, 12.8, 2.3, 2.3, BLACK, dz=14, n=10)
    E(29.2, 13.6, 0.75, 0.75, WHITE, dz=15, n=8)

    # antennae: one long sweeping back, one forward
    pts = [(30, 9), (38, 15), (45, 24), (48, 35), (46, 46), (40, 56)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        L(x0, y0, x1, y1, 1.4, dark, 9)
    pts = [(31, 7), (44, 13), (58, 17), (72, 18), (86, 16)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        L(x0, y0, x1, y1, 1.2, red, 9)
    L(32, 6, 40, 9, 0.9, dark, 9)
    L(32, 6, 39, 4, 0.9, dark, 9)

    # near walking legs
    for i, lx in enumerate((0, 7, 14, 21)):
        L(lx, -6, lx + 3, -14, 1.9, red, 14)
        L(lx + 3, -14, lx + 1, -21, 1.5, dark, 14)

    # near claw: arm, wrist, claw body, fixed finger, movable finger
    L(20, -3, 32, -9, 4.6, red, 16)
    L(32, -9, 43, -4, 4.2, red, 16)
    E(55, -2, 12.5, 6.4, red, rot=12, dz=17)
    E(54, 0.2, 9, 2.4, light, rot=12, dz=18)
    P([(62, 3.2), (79, 6.8), (78, 4.6), (63, -0.8)], red, 18)
    P([(66, 3.0), (77, 5.6), (66, 1.6)], dark, 19)
    pivot_xy = (ox + (-1 if flip else 1) * 63 * s, oy - 3.0 * s)
    finger = [(63, -1.5), (79, -2.2), (78, -4.3), (62, -6.4)]
    P(finger, red, 18, extra=[claw_group] if claw_group else None)
    P([(66, -3.3), (76, -3.0), (66, -4.8)], dark, 19,
      extra=[claw_group] if claw_group else None)
    if claw_pivot:
        lv.rect(pivot_xy[0], pivot_xy[1], 2, 2, red, z_layer=z_layer,
                z_order=z + 17, groups=g + [claw_pivot])
    return pivot_xy


def kelp(lv, x, y0, height, z_layer=K.B3, z=0, groups=None, seed=0,
         thick=5.0, colors=(KELP, KELP_DARK)):
    rnd = random.Random(seed)
    col, dark = colors
    n = max(3, int(height / 22))
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append((x + math.sin(t * 5.2 + seed) * 7 * t, y0 + height * t))
    for i, ((x0, y_0), (x1, y_1)) in enumerate(zip(pts, pts[1:])):
        w = thick * (1.0 - 0.45 * i / n)
        lv.segment(x0, y_0, x1, y_1 + 1, w, dark if i % 2 else col,
                   z_layer=z_layer, z_order=z, groups=groups)
        if i % 1 == 0 and i > 0:
            side = 1 if i % 2 else -1
            ang = 35 + rnd.uniform(-10, 10)
            ln = rnd.uniform(14, 22) * (1.0 - 0.3 * i / n)
            cx = x0 + side * math.cos(math.radians(ang)) * ln / 2
            cy = y_0 + math.sin(math.radians(ang)) * ln / 2
            lv.ellipse(cx, cy, ln / 2, 3.0, col, rot=side * ang, n=10,
                       z_layer=z_layer, z_order=z + 1, groups=groups)


def rock(lv, cx, y0, w, h, col=FAR_ROCK, z_layer=K.B4, z=0, seed=0,
         groups=None):
    rnd = random.Random(seed)
    pts = [(cx - w / 2, y0), (cx + w / 2, y0)]
    top = []
    k = 7
    for i in range(k):
        a = math.pi * (i + 0.5) / k
        r = 1 + rnd.uniform(-0.12, 0.12)
        top.append((cx + math.cos(a) * w / 2 * r, y0 + math.sin(a) * h * r))
    pts = [(cx - w / 2, y0), (cx + w / 2, y0)] + top
    pts = _convex_hull(pts)
    lv.poly(pts, col, z_layer=z_layer, z_order=z, groups=groups)


def _convex_hull(points):
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def light_ray(lv, x, top, length, width, ang=-70, z_layer=K.B4,
              groups=None):
    a = math.radians(ang)
    x1, y1 = x + math.cos(a) * length, top + math.sin(a) * length
    lv.segment(x, top, x1, y1, width, RAYS, z_layer=z_layer, z_order=-20,
               groups=groups)


def bubble(lv, x, y, r, groups=None, z_layer=K.T1):
    o = lv.add(K.HOLLOW_CIRCLE, x, y, "deco", scale=round(r / 15, 3),
               color=BUBBLE, z_layer=z_layer, groups=groups, no_touch=True,
               editor_layer=1)
    return o


def bubble_column(lv, x, y0, count, seed, groups, spread=18, z_layer=K.T1):
    rnd = random.Random(seed)
    for i in range(count):
        bubble(lv, x + rnd.uniform(-spread, spread), y0 + i * rnd.uniform(16, 30),
               rnd.uniform(2.2, 6.5), groups=groups, z_layer=z_layer)


def starfish(lv, cx, cy, r, rot=0, z_layer=K.B1, col=STAR):
    for i in range(5):
        a = math.radians(rot + 90 + 72 * i)
        b1, b2 = a - math.radians(20), a + math.radians(20)
        pts = [(cx + math.cos(a) * r, cy + math.sin(a) * r),
               (cx + math.cos(b2) * r * 0.32, cy + math.sin(b2) * r * 0.32),
               (cx, cy),
               (cx + math.cos(b1) * r * 0.32, cy + math.sin(b1) * r * 0.32)]
        lv.poly(pts, col, z_layer=z_layer, z_order=2)
    lv.ellipse(cx, cy, r * 0.3, r * 0.3, col, n=10, z_layer=z_layer, z_order=3)


def shell(lv, cx, y0, w, z_layer=K.B1):
    h = w * 0.7
    for i in range(5):
        a0 = math.pi * i / 5
        a1 = math.pi * (i + 1) / 5
        pts = [(cx, y0), (cx + math.cos(a0) * w / 2, y0 + math.sin(a0) * h),
               (cx + math.cos(a1) * w / 2, y0 + math.sin(a1) * h)]
        lv.poly(pts, CORAL if i % 2 else STAR, z_layer=z_layer, z_order=2)


def coral(lv, x, y0, h, seed=0, z_layer=K.B3, col=CORAL):
    rnd = random.Random(seed)

    def branch(x0, y_0, ang, ln, t, depth):
        x1 = x0 + math.cos(math.radians(ang)) * ln
        y1 = y_0 + math.sin(math.radians(ang)) * ln
        lv.segment(x0, y_0, x1, y1, t, col, z_layer=z_layer, z_order=0)
        lv.ellipse(x1, y1, t * 0.55, t * 0.55, col, n=8, z_layer=z_layer,
                   z_order=1)
        if depth > 0:
            for d in (-28, 26):
                branch(x1, y1, ang + d + rnd.uniform(-8, 8),
                       ln * rnd.uniform(0.62, 0.78), t * 0.72, depth - 1)
    branch(x, y0, 90, h * 0.45, max(3.0, h * 0.09), 3)


def fish(lv, cx, cy, s, flip=False, groups=None, z_layer=K.B2, col=FISH):
    f = -1 if flip else 1
    lv.ellipse(cx, cy, 12 * s, 5 * s, col, n=14, z_layer=z_layer, groups=groups)
    lv.poly([(cx - f * 10 * s, cy), (cx - f * 19 * s, cy + 6 * s),
             (cx - f * 19 * s, cy - 6 * s)], col, z_layer=z_layer,
            groups=groups)
    lv.ellipse(cx + f * 6 * s, cy + 1.2 * s, 1.2 * s, 1.2 * s, BLACK, n=8,
               z_layer=z_layer, z_order=2, groups=groups)


def flame(lv, cx, y0, h, w, groups=None, z_layer=K.B1):
    lv.poly([(cx - w / 2, y0), (cx + w / 2, y0), (cx + w * 0.18, y0 + h * 0.6),
             (cx, y0 + h), (cx - w * 0.25, y0 + h * 0.55)], FIRE,
            z_layer=z_layer, z_order=5, groups=groups)
    lv.poly([(cx - w / 4, y0), (cx + w / 4, y0), (cx + w * 0.06, y0 + h * 0.5),
             (cx - w * 0.1, y0 + h * 0.42)], GOLD, z_layer=z_layer,
            z_order=6, groups=groups)


def crown(lv, cx, y0, w, z_layer=K.B2, z=40):
    h = w * 0.55
    lv.poly([(cx - w / 2, y0), (cx + w / 2, y0), (cx + w / 2, y0 + h * 0.35),
             (cx - w / 2, y0 + h * 0.35)], GOLD, z_layer=z_layer, z_order=z)
    for i in range(5):
        px = cx - w / 2 + w * i / 4
        lv.poly([(px - w * 0.11, y0 + h * 0.3), (px + w * 0.11, y0 + h * 0.3),
                 (px, y0 + h)], GOLD, z_layer=z_layer, z_order=z)
        lv.ellipse(px, y0 + h, w * 0.045, w * 0.045, WHITE, n=8,
                   z_layer=z_layer, z_order=z + 1)
    for i in range(3):
        lv.ellipse(cx - w / 3 + w / 3 * i, y0 + h * 0.18, w * 0.05, w * 0.05,
                   CORAL if i != 1 else ROCK_GLOW, n=8, z_layer=z_layer,
                   z_order=z + 1)
