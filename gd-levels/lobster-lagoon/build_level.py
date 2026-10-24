"""Builds "Lobster Lagoon" - a lobster-themed Geometry Dash 2.2 level.

    python3 build_level.py                    # writes Lobster_Lagoon.gmd + level_string.txt
    python3 build_level.py --creator YourName # sets the creator shown in the .gmd

Song: "The Seven Seas" by F-777 (official song, 140 BPM). Every jump, flip and
portal is placed on the beat grid; gameplay is laid out from the player's
physical trajectory (physics.py) so the geometry is guaranteed to clear.
"""

import math
import random
import sys

import art as A
import gdkit as K
import physics as P
from art import (BLACK, BUBBLE, CORAL, FAR_LOBSTER, FAR_ROCK, FIRE, FISH,
                 GOLD, HAZARD, HEAT_GLOW, KELP, KELP_DARK, NET, RAYS, RED,
                 RED_DARK, RED_LIGHT, ROCK, ROCK_GLOW, ROPE, SAND, STAR,
                 STEAM, STEEL, STEEL_DARK, TOP_EDGE, WHITE, WOOD, WOOD_DARK)

NAME = "Lobster Lagoon"
SONG_ID = 23            # "The Seven Seas" (F-777) in the official song enum
BPM = 140.0
BEAT = 60.0 / BPM

S_TRAP, S_CLAW, S_KELP, S_DROP, S_ESC, S_OUT, S_END = 32, 64, 96, 120, 152, 184, 200
SPEED_SEGMENTS = [(0, 1), (S_DROP, 2), (S_ESC, 1)]


def bx(b):
    """x position of the player at beat b (speed changes are on beats)."""
    x = 0.0
    for i, (b0, sp) in enumerate(SPEED_SEGMENTS):
        b1 = SPEED_SEGMENTS[i + 1][0] if i + 1 < len(SPEED_SEGMENTS) else 1e9
        if b <= b0:
            break
        x += (min(b, b1) - b0) * BEAT * P.SPEED[sp]
    return x


class Plan:
    """Reference inputs for the verifier (one per gameplay section)."""

    def __init__(self):
        self.presses = []          # x positions of discrete clicks
        self.ship = []             # (x0, x1, target(x))
        self.ufo = []
        self.ufo_gates = []        # (x, gap centre, half gap)
        self.ufo_coins = []
        self.wave = []             # (x0, x1, path(x))
        self.notes = []

    def press(self, x, note=""):
        self.presses.append(x)
        if note:
            self.notes.append((x, note))


# ---------------------------------------------------------------- trajectories

def arc_times(rel, vy0, g=P.G_CUBE):
    """Times when a jump starting at height 0 with vy0 is at height rel."""
    disc = vy0 * vy0 - 2 * g * rel
    if disc < 0:
        return None
    r = math.sqrt(disc)
    return (vy0 - r) / g, (vy0 + r) / g


class Cube:
    """Lays out a cube section from the jump physics, one click per move.

    The builder tracks the floor the cube is standing on (height h, ending at
    `end`) and refuses layouts whose safety margin is under `min_margin`
    units."""

    SPIKE_TOP = 24.0       # conservative spike hitbox top above its base
    SPIKE_HALF = 4.5 + 15  # spike half width + cube half width

    def __init__(self, lv, plan, x, h=0.0, speed=1, rock=ROCK):
        self.lv, self.plan = lv, plan
        self.v = P.SPEED[speed]
        self.vy = P.CUBE_JUMP[speed]
        self.h = h
        self.end = 1e9               # current platform ends here (if h > 0)
        self.land = x                # x where the cube is next on the ground
        self.rock = rock
        self.min_margin = 9.0
        self.report = []

    def _check_press(self, xp, what):
        # a click held for a few ticks re-jumps on landing, so a press up to
        # 3 units before touchdown still works (this is how holding works in GD)
        if xp < self.land - 3:
            raise ValueError(f"{what}: press at {xp:.0f} before landing at {self.land:.0f}")
        if self.h > 0 and xp > self.end - 2:
            raise ValueError(f"{what}: press at {xp:.0f} is off the platform end {self.end:.0f}")

    def _spike_row(self, x_first, n, base):
        for i in range(n):
            self.lv.spike(x_first + 30 * i, base + 15, HAZARD)

    def _spike_window(self, xp, rel_base, n, vy0=None, y0_rel=0.0):
        """Allowed centre range of the first of n spikes (base at rel_base
        relative to the jump start height) for a jump at xp."""
        vy0 = vy0 or self.vy
        t = arc_times(rel_base + self.SPIKE_TOP - y0_rel, vy0)
        lo = xp + self.v * t[0] + self.SPIKE_HALF
        hi = xp + self.v * t[1] - self.SPIKE_HALF - 30 * (n - 1)
        return lo, hi

    def spikes(self, beat, n=1, note=""):
        xp = bx(beat)
        self._check_press(xp, f"spikes@{beat}")
        lo, hi = self._spike_window(xp, 0.0, n)
        margin = (hi - lo) / 2
        assert margin >= self.min_margin, (beat, n, margin)
        self._spike_row((lo + hi) / 2, n, self.h)
        self.plan.press(xp, note)
        self.land = xp + self.v * arc_times(0.0, self.vy)[1]
        self.report.append((beat, f"{n} spike(s)", margin))

    def up(self, beat, dh, length, note=""):
        """Jump onto a platform dh blocks higher that is `length` units long."""
        xp = bx(beat)
        self._check_press(xp, f"up@{beat}")
        rel = dh * 30.0
        t1, t2 = arc_times(rel, self.vy)
        lo, hi = xp + self.v * t1 + 15, xp + self.v * t2 + 15
        xb = lo + (hi - lo) * 0.42
        margin = min(xb - lo, hi - xb)
        assert margin >= self.min_margin, (beat, margin)
        top = self.h + rel
        self.plat = self.lv.block(xb, 0, xb + length, top, self.rock)
        self.h, self.end = top, xb + length
        self.plan.press(xp, note)
        self.land = xp + self.v * t2
        self.report.append((beat, f"up {dh} block(s)", margin))
        return xb

    def down(self, beat, to_h=0.0, spikes=0, note=""):
        """Jump off the end of the current platform down to height to_h, with
        a row of spikes on the lower floor under the arc."""
        xp = bx(beat)
        self._check_press(xp, f"down@{beat}")
        drop = self.h - to_h
        if self.end > xp + 24 and getattr(self, "plat", None) is not None:
            # trim the platform so it ends just after the take-off point
            o = self.plat
            left = o.x - K.BLOCK * o["scale_x"] / 2
            self.end = xp + 24
            o.props[2] = (left + self.end) / 2
            o.props[128] = round((self.end - left) / K.BLOCK, 4)
        t_land = arc_times(-drop, self.vy)[1]
        x_land = xp + self.v * t_land
        if x_land - 15 < self.end + 2:
            raise ValueError(f"down@{beat}: lands back on the platform")
        if spikes:
            t = arc_times(-drop + self.SPIKE_TOP, self.vy)
            lo = max(xp + self.v * t[0], self.end + 5) + self.SPIKE_HALF
            hi = xp + self.v * t[1] - self.SPIKE_HALF - 30 * (spikes - 1)
            margin = (hi - lo) / 2
            assert margin >= self.min_margin, (beat, margin)
            self._spike_row((lo + hi) / 2, spikes, to_h)
            self.report.append((beat, f"drop over {spikes} spike(s)", margin))
        self.h, self.end = to_h, 1e9
        self.plan.press(xp, note)
        self.land = x_land

    def pad(self, beat, spikes=3, kind=K.YELLOW_PAD, onto=None, length=0):
        """Pad on the floor so the launch happens on the beat. With `onto`
        (blocks above the current floor) the arc lands on a new platform."""
        xl = bx(beat)
        if xl < self.land - 3:
            raise ValueError(f"pad@{beat} before landing")
        xpad = xl + 27
        self.lv.add(kind, xpad, self.h + 15, "pad", editor_layer=0)
        vy0 = P.PAD_VY[kind]
        if onto:
            rel = onto * 30.0
            t1, t2 = arc_times(rel, vy0)
            lo, hi = xl + self.v * t1 + 15, xl + self.v * t2 + 15
            xb = lo + (hi - lo) * 0.45
            if spikes:
                ts = arc_times(self.SPIKE_TOP, vy0)
                slo = xpad + 30
                shi = min(xb - 20, xl + self.v * ts[1] - self.SPIKE_HALF)
                n = int((shi - slo) // 30) + 1
                self._spike_row(slo, max(0, min(spikes, n)), self.h)
            top = self.h + rel
            self.plat = self.lv.block(xb, 0, xb + length, top, self.rock)
            self.report.append((beat, f"pad onto +{onto}", min(xb - lo, hi - xb)))
            self.h, self.end = top, xb + length
            self.land = xl + self.v * t2
            return xb
        t = arc_times(self.SPIKE_TOP, vy0)
        lo = max(xl + self.v * t[0] + self.SPIKE_HALF, xpad + 32)
        hi = xl + self.v * t[1] - self.SPIKE_HALF - 30 * (spikes - 1)
        margin = (hi - lo) / 2
        assert margin >= self.min_margin, (beat, margin)
        self._spike_row((lo + hi) / 2, spikes, self.h)
        self.land = xl + self.v * arc_times(0.0, vy0)[1]
        self.report.append((beat, f"pad over {spikes}", margin))
        return xl + self.v * vy0 / P.G_CUBE   # apex x

    def orb(self, beat, spikes=4, kind=K.YELLOW_ORB, coin=False):
        """Jump on the beat, hit an orb at the top of the arc, clear a pit."""
        xp = bx(beat)
        self._check_press(xp, f"orb@{beat}")
        t_apex = self.vy / P.G_CUBE
        apex_h = self.vy ** 2 / (2 * P.G_CUBE)
        xo, yo = xp + self.v * t_apex, self.h + apex_h + 15
        self.lv.add(kind, xo, yo, "orb", editor_layer=0)
        vy2 = self.vy * P.ORB_MULT[kind]
        # second arc starts at apex height
        t2 = arc_times(-apex_h + self.SPIKE_TOP, vy2)
        lo = xp + self.v * arc_times(self.SPIKE_TOP, self.vy)[0] + self.SPIKE_HALF
        last = xo + self.v * t2[1] - self.SPIKE_HALF   # right bound, last spike
        n = min(spikes, int((last - lo) // 30) + 1)
        first = (lo + last - 30 * (n - 1)) / 2
        margin = first - lo
        assert margin >= self.min_margin, (beat, margin)
        self._spike_row(first, n, self.h)
        self.plan.press(xp, f"jump into orb @{beat}")
        self.plan.press(xo - 6, "orb click")
        t_land = arc_times(-apex_h, vy2)[1]
        self.land = xo + self.v * t_land
        self.report.append((beat, f"orb over {n} spikes", margin))
        if coin:
            # coin at the top of the second arc
            t_top = vy2 / P.G_CUBE
            self.lv.add(K.USER_COIN, xo + self.v * t_top,
                        yo + vy2 ** 2 / (2 * P.G_CUBE), "coin", editor_layer=0)
        return xo, yo

    def coin_jump(self, beat):
        xp = bx(beat)
        self._check_press(xp, f"coin@{beat}")
        t_apex = self.vy / P.G_CUBE
        self.lv.add(K.USER_COIN, xp + self.v * t_apex,
                    self.h + self.vy ** 2 / (2 * P.G_CUBE) + 15, "coin",
                    editor_layer=0)
        self.plan.press(xp, "coin jump")
        self.land = xp + self.v * arc_times(0.0, self.vy)[1]


# ---------------------------------------------------------------- palette

PALETTES = {
    "sea": {K.BG: (10, 38, 82), K.GROUND: (34, 60, 92), K.GROUND2: (24, 44, 72),
            K.LINE: (120, 210, 255), ROCK: (20, 40, 72), ROCK_GLOW: (70, 190, 255),
            FAR_ROCK: (16, 50, 96), TOP_EDGE: (120, 225, 255), RAYS: (110, 200, 255),
            HAZARD: (34, 12, 56), FAR_LOBSTER: (70, 30, 52)},
    "trap": {K.BG: (7, 28, 62), K.GROUND: (30, 50, 78), K.GROUND2: (20, 36, 60),
             K.LINE: (230, 190, 120), FAR_ROCK: (12, 40, 80), RAYS: (90, 170, 230),
             HAZARD: (40, 18, 10), TOP_EDGE: (240, 200, 140)},
    "claw": {K.BG: (28, 12, 42), K.GROUND: (42, 22, 52), K.GROUND2: (30, 14, 40),
             K.LINE: (255, 120, 90), ROCK: (36, 16, 44), ROCK_GLOW: (255, 90, 80),
             FAR_ROCK: (44, 20, 58), TOP_EDGE: (255, 150, 120), RAYS: (200, 90, 160),
             HAZARD: (20, 6, 24)},
    "kelp": {K.BG: (6, 42, 52), K.GROUND: (20, 62, 60), K.GROUND2: (12, 46, 46),
             K.LINE: (120, 255, 190), ROCK: (10, 50, 46), ROCK_GLOW: (90, 255, 170),
             FAR_ROCK: (10, 60, 64), TOP_EDGE: (140, 255, 200), RAYS: (100, 230, 200),
             HAZARD: (8, 30, 20)},
    "boil": {K.BG: (64, 10, 6), K.GROUND: (40, 10, 8), K.GROUND2: (28, 6, 6),
             K.LINE: (255, 150, 40), ROCK: (30, 26, 30), ROCK_GLOW: (255, 110, 30),
             FAR_ROCK: (92, 20, 10), TOP_EDGE: (255, 170, 80), RAYS: (255, 120, 40),
             HAZARD: (10, 0, 0), RED: (255, 72, 40), RED_LIGHT: (255, 170, 110)},
    "escape": {K.BG: (14, 62, 122), K.GROUND: (52, 88, 124), K.GROUND2: (36, 66, 98),
               K.LINE: (170, 235, 255), ROCK: (24, 54, 96), ROCK_GLOW: (110, 230, 255),
               FAR_ROCK: (26, 82, 142), TOP_EDGE: (170, 240, 255), RAYS: (160, 230, 255),
               HAZARD: (30, 14, 50), RED: (214, 58, 38), RED_LIGHT: (255, 128, 84)},
    "outro": {K.BG: (34, 104, 164), K.GROUND: (88, 120, 146), K.GROUND2: (66, 96, 122),
              K.LINE: (255, 240, 200), FAR_ROCK: (40, 112, 170), RAYS: (255, 240, 200),
              ROCK: (40, 74, 116)},
}

BLENDING = {K.LINE, ROCK_GLOW, RAYS, BUBBLE, FIRE, HEAT_GLOW}
OPACITY = {RAYS: 0.22, BUBBLE: 0.75, NET: 0.55, HEAT_GLOW: 0.6}

BASE_COLORS = {
    RED: (214, 58, 38), RED_DARK: (138, 26, 22), RED_LIGHT: (255, 128, 84),
    KELP: (44, 150, 92), KELP_DARK: (22, 92, 62), BUBBLE: (190, 235, 255),
    WOOD: (122, 78, 42), WOOD_DARK: (78, 46, 24), ROPE: (214, 190, 140),
    BLACK: (12, 10, 14), SAND: (70, 84, 104), STEEL: (64, 66, 80),
    STEEL_DARK: (36, 36, 46), FIRE: (255, 110, 30), STEAM: (214, 170, 160),
    WHITE: (255, 255, 255), CORAL: (236, 92, 140), STAR: (255, 156, 60),
    GOLD: (255, 206, 60), NET: (200, 176, 130), FISH: (190, 200, 210),
    HEAT_GLOW: (255, 80, 20),
}


def setup_channels(lv):
    for ch, rgb in BASE_COLORS.items():
        lv.channel(ch, rgb, OPACITY.get(ch, 1.0), ch in BLENDING)
    for ch, rgb in PALETTES["sea"].items():
        lv.channel(ch, rgb, OPACITY.get(ch, 1.0), ch in BLENDING)
    lv.channel(K.OBJ, (255, 255, 255))


def palette_change(lv, x, name, dur):
    for ch, rgb in PALETTES[name].items():
        lv.color_trigger(x, ch, rgb, dur, OPACITY.get(ch, 1.0), ch in BLENDING)


# ---------------------------------------------------------------- decoration

def decorate_solid(lv, o, style):
    """Edge art on a gameplay block: glow strip on top, dark inner shade."""
    w = K.BLOCK * (o["scale_x"] or 1)
    h = K.BLOCK * (o["scale_y"] or 1)
    x0, y0 = o.x - w / 2, o.y - h / 2
    x1, y1 = x0 + w, y0 + h
    if style == "rock":
        lv.rect(o.x, y1 - 1.5, w, 3, TOP_EDGE, z_layer=K.T1, z_order=5)
        lv.rect(o.x, y1 - 9, w + 6, 14, ROCK_GLOW, z_layer=K.B1, z_order=-5)
        if h > 40:
            lv.rect(o.x, (y0 + y1) / 2 - 6, max(w - 14, 4), max(h - 26, 4),
                    FAR_ROCK, z_layer=K.T1, z_order=2)
    elif style == "wood":
        lv.rect(o.x, y1 - 1.5 if y0 > 1 else y1 - 1.5, w, 3, TOP_EDGE,
                z_layer=K.T1, z_order=5)
        lv.rect(o.x, y0 + 1.5, w, 3, WOOD_DARK, z_layer=K.T1, z_order=5)
        for k in range(int(h // 30)):
            lv.rect(o.x, y0 + 15 + 30 * k, w - 6, 1.6, WOOD_DARK,
                    z_layer=K.T1, z_order=4)
    elif style == "steel":
        lv.rect(o.x, (y0 + y1) / 2, w, h, STEEL_DARK, z_layer=K.B1, z_order=-6)


def seafloor_deco(lv, x0, x1, seed, rays=True, lobsters=True, density=1.0):
    rnd = random.Random(seed)
    x = x0
    while x < x1:
        w = rnd.uniform(160, 340)
        A.rock(lv, x + w / 2, -2, w, rnd.uniform(70, 170), FAR_ROCK, K.B5,
               -30, seed=rnd.randint(0, 1 << 30))
        x += w * rnd.uniform(0.55, 0.9)
    x = x0 + rnd.uniform(0, 60)
    while x < x1:
        A.kelp(lv, x, -2, rnd.uniform(70, 190), K.B4, -10,
               seed=rnd.randint(0, 999), thick=rnd.uniform(4, 6.5),
               colors=(KELP_DARK, KELP_DARK))
        x += rnd.uniform(90, 200) / density
    x = x0 + 40
    while x < x1:
        oid = rnd.choice(K.GRASS_PATCHES)
        lv.add(oid, x, 6, "deco", color=KELP, z_layer=K.B1, z_order=3,
               scale=round(rnd.uniform(0.7, 1.2), 2), no_touch=True,
               editor_layer=1)
        x += rnd.uniform(40, 110) / density
    if rays:
        x = x0 + rnd.uniform(0, 120)
        while x < x1:
            A.light_ray(lv, x, 330, rnd.uniform(260, 380), rnd.uniform(18, 46),
                        ang=-72 + rnd.uniform(-5, 5))
            x += rnd.uniform(160, 300)
    x = x0 + rnd.uniform(100, 300)
    while x < x1:
        if rnd.random() < 0.5:
            A.starfish(lv, x, 5, rnd.uniform(6, 10), rot=rnd.uniform(0, 70),
                       z_layer=K.B1)
        else:
            A.shell(lv, x, 0, rnd.uniform(10, 16), z_layer=K.B1)
        x += rnd.uniform(240, 520)


def bubbles(lv, x0, x1, trigger_x, seed, rise=420, dur=7.0, every=110,
            y0=-10, z_layer=K.T1):
    rnd = random.Random(seed)
    g = lv.new_group()
    x = x0
    while x < x1:
        A.bubble_column(lv, x, y0 + rnd.uniform(0, 80), rnd.randint(3, 6),
                        rnd.randint(0, 1 << 20), [g], z_layer=z_layer)
        x += rnd.uniform(every * 0.6, every * 1.4)
    lv.move(trigger_x, g, 0, rise, dur, K.EASE_IN)
    return g


def walking_lobster(lv, x, y, s, walk, dur, trigger_x, flip=False,
                    z_layer=K.B2, z=0, palette=None, bob=None):
    g = lv.new_group()
    A.lobster(lv, x, y, s, flip=flip, z_layer=z_layer, z=z, groups=[g],
              palette=palette)
    if walk:
        lv.move(trigger_x, g, walk, 0, dur)
    if bob:
        for i, bxx in enumerate(bob):
            lv.move(bxx, g, 0, 3 if i % 2 == 0 else -3, BEAT * 0.9,
                    K.EASE_SINE_IN_OUT)
    return g


def swaying_kelp(lv, x, y0, h, seed, beats, amp=7, z_layer=K.B3,
                 colors=(KELP, KELP_DARK), thick=6.0):
    g, pivot = lv.new_group(), lv.new_group()
    A.kelp(lv, x, y0, h, z_layer, 0, [g], seed, thick=thick, colors=colors)
    lv.rect(x, y0 + 2, 2, 2, colors[1], z_layer=z_layer, groups=[pivot])
    sign = 1
    for b in beats:
        lv.rotate(bx(b), g, pivot, amp * sign, BEAT * 2, K.EASE_SINE_IN_OUT)
        sign = -sign
    return g


# ---------------------------------------------------------------- sections

def section_seafloor(lv, plan):
    x0, x1 = 0, bx(S_TRAP)
    c = Cube(lv, plan, 0.0)
    for b, n in ((4, 1), (5, 1), (6, 2)):
        c.spikes(b, n)
    c.up(8, 1, 3.2 * 133.5)
    c.spikes(9, 1)
    c.spikes(10, 2)
    c.up(11, 1, 2.3 * 133.5)
    c.spikes(12, 1)
    c.down(13, 0.0, spikes=3)
    c.spikes(15, 2)
    apex = c.pad(16, spikes=3)
    c.orb(18, spikes=5)
    c.spikes(20, 1)
    c.spikes(21, 2)
    c.up(22, 1, 2.2 * 133.5)
    c.spikes(23, 1)
    xa = c.up(24, 1, 78)
    xb = c.up(25, 1, 72)
    c.down(26, 0.0, spikes=3)
    # spike pit in the gap between the two pillars
    for sx in range(int(xa + 78 + 15), int(xb - 12), 30):
        lv.spike(sx, 15, HAZARD)
    c.spikes(28, 1)
    c.spikes(29, 2)
    c.spikes(30, 1)

    # coin 1: sits at the top of the pad arc, tucked under a hanging buoy
    lv.add(K.USER_COIN, apex, P.PAD_VY[K.YELLOW_PAD] ** 2 / (2 * P.G_CUBE) + 15,
           "coin", editor_layer=0)

    # --- decoration -----------------------------------------------------------
    seafloor_deco(lv, -200, x1 + 100, seed=11)
    lv.text(330, 205, "LOBSTER LAGOON", scale=1.25, color=WHITE)
    lv.text(330, 172, "a crustacean adventure", scale=0.55, color=TOP_EDGE)
    for i, (lx, ly, s, walk, flip) in enumerate((
            (700, 26, 0.9, 900, False), (1500, 30, 1.05, 700, False),
            (2600, 24, 0.85, -600, True), (3500, 28, 1.0, 600, False))):
        walking_lobster(lv, lx, ly, s, walk, 9.0, max(0, lx - 600), flip=flip,
                        z_layer=K.B3, z=0,
                        palette=(FAR_LOBSTER, RED_DARK, RED))
    # a big lobster on a rock behind the second platform group
    A.rock(lv, 1950, -2, 260, 120, ROCK, K.B3, -2, seed=4)
    A.lobster(lv, 1960, 150, 1.25, z_layer=K.B3, z=0)
    for i, kx in enumerate((420, 1180, 2280, 3080, 3900)):
        swaying_kelp(lv, kx, -2, 200 + 30 * (i % 2), seed=i * 7,
                     beats=range(i % 2, S_TRAP + 2, 2))
    bubbles(lv, 0, x1, 10, seed=3)
    bubbles(lv, 1800, x1 + 600, 1400, seed=5, y0=-40)
    for o in [o for o in lv.objects if o.kind == "solid"]:
        decorate_solid(lv, o, "rock")
    # guide arrows on the first pad (helps readability)
    return c


def section_trap(lv, plan):
    x0, x1 = bx(S_TRAP), bx(S_CLAW)
    lv.portal("ship", x0, 45)
    roof0, floor_top = 270.0, 30.0
    lv.block(x0 + 90, roof0, x1 - 45, 300, WOOD)
    lv.block(x0 + 150, 0, x1 - 140, floor_top, WOOD)

    keys = [(x0, 30.0), (x0 + 150, 120.0)]
    gates = []
    hi_lo = [195, 105]
    for i, b in enumerate(range(S_TRAP + 2, S_TRAP + 16, 2)):
        yc = hi_lo[i % 2]
        keys.append((bx(b), yc))
        gates.append((bx(b), yc, 64, False))
    hi_lo2 = [172, 112]
    for i, b in enumerate(range(S_TRAP + 16, S_TRAP + 26)):
        yc = hi_lo2[i % 2]
        keys.append((bx(b), yc))
        gates.append((bx(b), yc, 70, True))
    # funnel down to the ball portal
    xf0, xf1 = bx(S_TRAP + 26.5), bx(S_CLAW - 1.2)
    keys += [(xf0, 150.0), (xf1, 60.0), (x1 + 60, 60.0)]

    def target(x):
        for (xa, ya), (xb, yb) in zip(keys, keys[1:]):
            if xa <= x <= xb:
                t = (x - xa) / (xb - xa)
                t = (1 - math.cos(math.pi * t)) / 2
                return ya + (yb - ya) * t
        return keys[-1][1]

    for gx, yc, half_gap, spiked in gates:
        if yc > 150:   # path is high: slat rises from the floor
            top = yc - half_gap - (30 if spiked else 0)
            lv.block(gx - 15, floor_top, gx + 15, top, WOOD)
            if spiked:
                lv.spike(gx, top + 15, HAZARD)
        else:
            bot = yc + half_gap + (30 if spiked else 0)
            lv.block(gx - 15, bot, gx + 15, roof0, WOOD)
            if spiked:
                lv.spike(gx, bot - 15, HAZARD, flip=True)

    # funnel: stair-stepped walls 3.6 blocks apart
    step = 30
    xs = xf0 - 60
    while xs < xf1 + 30:
        lo = min(target(xs), target(xs + step))
        hi_ = max(target(xs), target(xs + step))
        if lo - 54 > floor_top + 3:
            lv.block(xs, floor_top, xs + step, lo - 54, WOOD)
        if hi_ + 54 < roof0 - 3:
            lv.block(xs, hi_ + 54, xs + step, roof0, WOOD)
        xs += step
    plan.ship.append((x0, x1, target))

    # coin 2: inside the bait box in the middle of the trap
    cx = bx(S_TRAP + 14.5)
    lv.add(K.USER_COIN, cx, target(cx), "coin", editor_layer=0)

    # --- decoration: the inside of a lobster trap -------------------------------
    for sx in range(int(x0 + 120), int(x1 - 60), 120):
        lv.rect(sx, 150, 9, 240, WOOD_DARK, z_layer=K.B4, z_order=-12)
    # net mesh behind everything, clipped to the trap's wooden frame
    left, right = x0 + 90, x1 - 45
    for k in range(int(left - 240) // 40, int(right) // 40 + 1):
        for xa, xb in ((k * 40, k * 40 + 240), (k * 40 + 240, k * 40)):
            ta = (left - xa) / (xb - xa)
            tb = (right - xa) / (xb - xa)
            t0, t1 = max(0.0, min(ta, tb)), min(1.0, max(ta, tb))
            if t1 - t0 < 0.02:
                continue
            lv.segment(xa + (xb - xa) * t0, 30 + 240 * t0,
                       xa + (xb - xa) * t1, 30 + 240 * t1, 1.6, NET,
                       z_layer=K.B5, z_order=-25)
    # bait bag with fish hanging in the middle
    bag_x = bx(S_TRAP + 14.5)
    lv.segment(bag_x, 270, bag_x, 230, 2, ROPE, z_layer=K.B2)
    A.fish(lv, bag_x - 20, 214, 1.2, groups=None)
    A.fish(lv, bag_x + 22, 206, 1.0, flip=True)
    # trapped lobsters in the background, claws pressed against the net
    for i, lx in enumerate(range(int(x0 + 500), int(x1 - 300), 700)):
        g = lv.new_group()
        A.lobster(lv, lx, 120 + 40 * (i % 2), 0.95, flip=i % 2 == 1,
                  z_layer=K.B4, z=0, groups=[g],
                  palette=(FAR_LOBSTER, RED_DARK, RED))
        for j, b in enumerate(range(S_TRAP, S_CLAW, 2)):
            lv.move(bx(b) - 300, g, 0, 6 if j % 2 == 0 else -6, BEAT * 1.8,
                    K.EASE_SINE_IN_OUT)
    for o in [o for o in lv.objects if o.kind == "solid" and x0 < o.x < x1 + 30]:
        decorate_solid(lv, o, "wood")
    bubbles(lv, x0, x1, x0 - 200, seed=21, rise=300, dur=10)


def section_claw(lv, plan):
    x0, x1 = bx(S_CLAW), bx(S_KELP)
    lv.portal("ball", x0, 60)
    ceil = 150.0
    cx0, cx1 = x0 + 45, x1 - 70
    lv.block(cx0, ceil, cx1, 186, RED_DARK)
    flips = [65.5, 66.5, 67.5, 68.5, 70, 71, 72, 73, 74, 75.5, 76.5, 77.5,
             78.5, 79.5, 80.5, 81.5, 82.5, 84, 85, 86, 87, 88, 89, 90, 91,
             92, 93, 94]
    assert len(flips) % 2 == 0
    xs = [bx(b) for b in flips]
    for x in xs:
        plan.press(x, "ball flip")

    # simulate the ball along this schedule for the slowest and fastest
    # gravity we consider plausible, then only put spikes where the ball is
    # far from that surface in every case.
    tmp = K.Level("tmp")
    tmp.block(cx0, ceil, cx1, 186, RED_DARK)
    world = P.World(tmp)
    traces = []
    for gb in (0.45, 0.6, 0.85):
        st = P.State(x0 + 30, 60, "ball")
        st.vy = 0
        press_ticks = list(xs)

        def pol(s, pt=press_ticks):
            for px in pt:
                if px <= s.x < px + P.SPEED[1] * 2 * P.DT:
                    return True
            return False
        end, tr = P.run(world, pol, st, until_x=x1, params={"ball_g": gb},
                        record=True)
        assert not end.dead, end.why
        traces.append(tr)

    def clear_of(x, surface):
        lo, hi = x - 4.5 - 15 - 10, x + 4.5 + 15 + 10
        for tr in traces:
            for px, py, _, _ in tr:
                if lo <= px <= hi:
                    if surface == "floor" and py - 15 < 24 + 8:
                        return False
                    if surface == "ceil" and py + 15 > ceil - 24 - 8:
                        return False
        return True

    x = x0 + 200
    placed = {"floor": [], "ceil": []}
    while x < x1 - 120:
        for surf in ("floor", "ceil"):
            if clear_of(x, surf):
                if surf == "floor":
                    lv.spike(x, 15, HAZARD)
                else:
                    lv.spike(x, ceil - 15, HAZARD, flip=True)
                placed[surf].append(x)
        x += 30
    # thin the rows a little so they read as clusters, not walls
    plan.notes.append((x0, f"ball spikes floor={len(placed['floor'])} ceil={len(placed['ceil'])}"))

    # --- decoration: the tunnel roof is the underside of a giant lobster's
    # arm - jointed shell segments with spines, the spikes are its barbs
    seg_w = 120
    for i, sx in enumerate(range(int(cx0), int(cx1), seg_w)):
        a, b = sx, min(sx + seg_w, cx1)
        lv.poly([(a, 184), (b, 184), (b - 5, 212), (b - 16, 222),
                 (a + 16, 222), (a + 5, 212)], RED, z_layer=K.B2, z_order=-2)
        lv.poly([(a + 12, 207), (b - 12, 207), (b - 22, 217), (a + 22, 217)],
                RED_LIGHT, z_layer=K.B2, z_order=-1)
        lv.rect(a, 202, 5, 44, RED_DARK, z_layer=K.B2, z_order=0)
        for k in range(3):
            px = a + 26 + k * 34
            lv.poly([(px - 5, 220), (px + 5, 220), (px + 1, 233)], RED_LIGHT,
                    z_layer=K.B2, z_order=-3)
        for k in range(2):
            lv.ellipse(a + 40 + 40 * k, 196 + 4 * (k % 2), 3.5, 2.5, RED_DARK,
                       n=8, z_layer=K.B2, z_order=1)
        lv.rect((a + b) / 2, 151.5, b - a - 4, 3, ROCK_GLOW, z_layer=K.T1,
                z_order=4)
    # three giant snapping claws above the tunnel
    for i, cxx in enumerate((x0 + 700, x0 + 2000, x0 + 3300)):
        g, cg, pv = lv.new_group(), lv.new_group(), lv.new_group()
        A.lobster(lv, cxx - 150, 262, 2.0, z_layer=K.B3, z=0, groups=[g],
                  claw_group=cg, claw_pivot=pv)
        for j, b in enumerate(range(S_CLAW, S_KELP)):
            lv.rotate(bx(b) - 40, cg, pv, -16 if j % 2 == 0 else 16,
                      BEAT * 0.35, K.EASE_BACK_OUT)
    for i, lx in enumerate(range(int(x0 + 300), int(x1), 520)):
        A.rock(lv, lx, -2, 240, 100, FAR_ROCK, K.B5, -30, seed=100 + i)
    bubbles(lv, x0, x1, x0 - 300, seed=31, rise=180, dur=9, y0=0,
            z_layer=K.B2)


def section_kelp(lv, plan):
    x0, x1 = bx(S_KELP), bx(S_DROP)
    lv.portal("ufo", x0, 45)
    roof = 270.0
    lv.block(x0 + 120, roof, x1 + 40, 300, ROCK)
    gate_beats = [98, 100, 102, 104, 106, 107.5, 109, 110.5, 112, 113.25,
                  114.5, 115.75, 117]
    centers = [150, 95, 185, 110, 195, 120, 180, 100, 165, 195, 130, 178, 140]
    halves = [70, 68, 68, 66, 66, 64, 64, 64, 62, 62, 62, 62, 62]
    keys = [(x0, 20.0), (bx(97), 110.0)]
    for b, yc, hg in zip(gate_beats, centers, halves):
        gx = bx(b)
        keys.append((gx - 20, yc))
        keys.append((gx + 20, yc))
        w = 40
        plan.ufo_gates.append((gx, yc, hg))
        lv.block(gx - w / 2, 0, gx + w / 2, yc - hg, KELP_DARK)
        lv.block(gx - w / 2, yc + hg, gx + w / 2, roof, KELP_DARK)
    keys.append((x1 - 60, 150.0))
    keys.append((x1 + 80, 150.0))

    def target(x):
        for (xa, ya), (xb, yb) in zip(keys, keys[1:]):
            if xa <= x <= xb:
                t = (x - xa) / max(xb - xa, 1)
                t = (1 - math.cos(math.pi * t)) / 2
                return ya + (yb - ya) * t
        return keys[-1][1]
    plan.ufo.append((x0, x1, target))

    # coin 3 sits in the gap of the sixth kelp gate
    lv.add(K.USER_COIN, bx(107.5), centers[5], "coin", editor_layer=0)
    plan.ufo_coins.append((bx(107.5), centers[5]))

    # --- decoration ---------------------------------------------------------------
    for o in [o for o in lv.objects if o.kind == "solid" and x0 < o.x < x1 + 60]:
        w = K.BLOCK * (o["scale_x"] or 1)
        h = K.BLOCK * (o["scale_y"] or 1)
        if h > 250 or w > 60:
            continue
        # giant kelp stalks: a lighter rib, leaves and a float bulb at the
        # gap-facing end, all kept inside the hitbox so the gap reads true
        y0, y1 = o.y - h / 2, o.y + h / 2
        from_floor = y0 < 1
        lv.rect(o.x - w * 0.2, o.y, w * 0.16, h, KELP, z_layer=K.T1, z_order=5)
        for k in range(int(h // 26)):
            yy = y0 + 13 + 26 * k
            side = 1 if k % 2 else -1
            lv.ellipse(o.x + side * w * 0.12, yy, w * 0.34, 6.5, KELP,
                       rot=side * 28, n=10, z_layer=K.T1, z_order=6)
        tip = y1 - 9 if from_floor else y0 + 9
        lv.ellipse(o.x, tip, w * 0.42, 8, KELP, n=12, z_layer=K.T1, z_order=7)
        lv.ellipse(o.x - 4, tip + (2 if from_floor else -2), w * 0.16, 3,
                   STAR, n=8, z_layer=K.T1, z_order=8)
        lv.rect(o.x, y1 - 1.5 if from_floor else y0 + 1.5, w, 3, ROCK_GLOW,
                z_layer=K.T1, z_order=9)
    rnd = random.Random(41)
    for i, kx in enumerate(range(int(x0 - 100), int(x1 + 100), 75)):
        swaying_kelp(lv, kx + rnd.uniform(-20, 20), -2, rnd.uniform(150, 260),
                     seed=200 + i, beats=range(S_KELP - 4 + i % 2, S_DROP, 2),
                     amp=6, z_layer=K.B4, colors=(KELP_DARK, KELP_DARK),
                     thick=rnd.uniform(4, 7))
    for i in range(8):
        A.fish(lv, x0 + 300 + 380 * i, 60 + 25 * (i % 5), 0.8, flip=True,
               z_layer=K.B3)
    seafloor_deco(lv, x0, x1, seed=43, lobsters=False, density=0.7)
    bubbles(lv, x0, x1, x0 - 400, seed=45, rise=330, dur=9)
    for o in [o for o in lv.objects if o.kind == "solid" and x0 < o.x < x1 + 60
              and o.y > 280]:
        decorate_solid(lv, o, "rock")


def section_boil(lv, plan):
    x0, x1 = bx(S_DROP), bx(S_ESC)
    lv.speed(2, x0 - 6, 150)
    lv.portal("wave", x0 + 14, 150)
    half_beat = (x1 - x0) / 64
    rnd = random.Random(7)
    pts = [(x0 + 14, 150.0)]
    x, y, d = x0 + 14, 150.0, 1
    # the drop: zig-zags on half beats, bursts of quarter-beat "spam"
    while x < x1 - 260:
        beat_now = S_DROP + (x - x0) / (half_beat * 2)
        spam = 128 <= beat_now < 130 or 140 <= beat_now < 142 or 146 <= beat_now < 148
        seg = half_beat * (0.5 if spam else rnd.choice((1, 1, 2)))
        d = -d
        ny = y + d * seg
        if ny > 245 or ny < 55:
            d = -d
            ny = y + d * seg
        if ny > 245 or ny < 55:
            seg = half_beat * 0.5
            ny = y + d * seg
        x += seg
        y = ny
        pts.append((x, y))
    # land the path on y=60 exactly at the cube portal
    xa, ya = pts[-1]
    z = x1 - xa - 90 - abs(ya - 150)
    pts.append((xa + abs(ya - 150), 150.0))
    pts.append((pts[-1][0] + z / 2, 150.0 + z / 2))
    pts.append((pts[-1][0] + z / 2, 150.0))
    pts.append((x1, 60.0))
    pts.append((x1 + 200, 60.0 - 200))

    def path(xq):
        for (xa_, ya_), (xb_, yb_) in zip(pts, pts[1:]):
            if xa_ <= xq <= xb_:
                return ya_ + (yb_ - ya_) * (xq - xa_) / (xb_ - xa_)
        return pts[-1][1]

    def corridor_at_vertex(xa_):
        beat_now = S_DROP + (xa_ - x0) / (half_beat * 2)
        if xa_ < x0 + 100:
            return 70.0
        return 47.0 if beat_now < 136 else 41.0
    seg_corr = [corridor_at_vertex(xa_) for xa_, _ in pts]

    def corridor(xq):
        # constant along each straight piece of the path, so the drawn wall
        # and the collision staircase always agree
        for i, ((xa_, _), (xb_, _)) in enumerate(zip(pts, pts[1:])):
            if xa_ <= xq < xb_:
                return seg_corr[i]
        return seg_corr[-1]

    # staircase solids that never come closer than corridor(x) to the path
    step = 12.0
    xs = x0 + 40
    while xs < x1 - 20:
        xe = xs + step
        samples = [xs + (xe - xs) * k / 4 for k in range(5)]
        low = min(path(q) - corridor(q) for q in samples)
        high = max(path(q) + corridor(q) for q in samples)
        if low > 1:
            lv.block(xs, 0, xe, low, STEEL)
        if high < 299:
            lv.block(xs, high, xe, 300, STEEL)
        xs = xe
    plan.wave.append((x0, x1 + 40, path))

    # --- decoration: inside a boiling pot ------------------------------------------
    # smooth wall faces drawn over the staircase
    for i, ((xa_, ya_), (xb_, yb_)) in enumerate(zip(pts, pts[1:])):
        if xb_ > x1 or xa_ < x0:
            continue
        ca = cb = seg_corr[i]
        lv.poly([(xa_, ya_ - ca), (xb_, yb_ - cb), (xb_, 0), (xa_, 0)], STEEL,
                z_layer=K.T1, z_order=1)
        lv.poly([(xa_, ya_ + ca), (xb_, yb_ + cb), (xb_, 300), (xa_, 300)],
                STEEL, z_layer=K.T1, z_order=1)
        lv.segment(xa_, ya_ - ca + 1.5, xb_, yb_ - cb + 1.5, 3, ROCK_GLOW,
                   z_layer=K.T1, z_order=3)
        lv.segment(xa_, ya_ + ca - 1.5, xb_, yb_ + cb - 1.5, 3, ROCK_GLOW,
                   z_layer=K.T1, z_order=3)
        lv.segment(xa_, ya_ - ca - 9, xb_, yb_ - cb - 9, 14, HEAT_GLOW,
                   z_layer=K.T1, z_order=2)
        lv.segment(xa_, ya_ + ca + 9, xb_, yb_ + cb + 9, 14, HEAT_GLOW,
                   z_layer=K.T1, z_order=2)
    # rivets
    for rx in range(int(x0 + 80), int(x1), 90):
        for ry in (14, 286):
            lv.ellipse(rx, ry, 4, 4, STEEL_DARK, n=8, z_layer=K.T1, z_order=4)
    # flames under the pot, flickering on every beat
    fg = lv.new_group()
    for fx in range(int(x0 - 60), int(x1 + 60), 46):
        A.flame(lv, fx, -40, rnd.uniform(26, 44), rnd.uniform(20, 30), [fg],
                z_layer=K.T2)
    for i, b in enumerate(range(S_DROP, S_ESC)):
        lv.move(bx(b), fg, 0, 9 if i % 2 == 0 else -9, BEAT * 0.45,
                K.EASE_SINE_IN_OUT)
    # boiling bubbles rising through the corridor, and steam
    for k in range(6):
        g = lv.new_group()
        bx0 = x0 + k * (x1 - x0) / 6
        for j in range(26):
            A.bubble(lv, bx0 + rnd.uniform(0, (x1 - x0) / 6),
                     rnd.uniform(-160, 40), rnd.uniform(3, 9), groups=[g],
                     z_layer=K.B1)
        lv.move(bx0 - 500, g, 0, 460, 2.6, K.EASE_IN)
    sg = lv.new_group()
    for sx in range(int(x0), int(x1), 70):
        lv.ellipse(sx, 312 + rnd.uniform(-6, 6), rnd.uniform(30, 50),
                   rnd.uniform(14, 22), STEAM, n=12, z_layer=K.T2, groups=[sg])
    for i, b in enumerate(range(S_DROP, S_ESC, 2)):
        lv.move(bx(b), sg, 25 if i % 2 == 0 else -25, -8 if i % 2 == 0 else 8,
                BEAT * 1.9, K.EASE_SINE_IN_OUT)
    # lobsters bobbing in the pot, panicking
    for i, lx in enumerate(range(int(x0 + 400), int(x1 - 200), 900)):
        g = lv.new_group()
        A.lobster(lv, lx, 150 + 50 * math.sin(i), 1.1, flip=i % 2 == 1,
                  z_layer=K.B4, z=0, groups=[g])
        for j, b in enumerate(range(S_DROP, S_ESC)):
            lv.move(bx(b), g, 0, 10 if j % 2 == 0 else -10, BEAT * 0.9,
                    K.EASE_SINE_IN_OUT)
    lv.text(x0 + 160, 250, "BOIL!", scale=1.4, color=GOLD, z_layer=K.T2)

    # --- the drop: colours, pulses, camera ------------------------------------------
    palette_change(lv, x0 - 40, "boil", 0.0)
    lv.shake(x0, 0.6, 2.2, 0.03)
    lv.trigger(K.SHOCKWAVE_TRIGGER, x0 + 2, sw_speed=1.2, sw_strength=1.2,
               sw_thickness=2.0, sw_wave_w=1.0, sw_fade_out=0.6,
               sw_target=True, sw_p1=True)
    for i, b in enumerate(range(S_DROP, S_ESC)):
        strong = i % 4 == 0
        lv.pulse(bx(b), K.BG, (190, 46, 14) if strong else (130, 26, 10),
                 0.0, 0.05, 0.35 if strong else 0.25)
        if strong:
            lv.pulse(bx(b), HEAT_GLOW, (255, 220, 120), 0.0, 0.05, 0.4)
    lv.zoom(x0, 0.92, BEAT * 2)
    lv.zoom(bx(S_ESC - 2), 1.0, BEAT * 2)


def section_escape(lv, plan):
    x0, x1 = bx(S_ESC), bx(S_OUT)
    lv.speed(1, x0 - 4, 60)
    lv.portal("cube", x0 + 10, 60)
    c = Cube(lv, plan, x0 + 60)
    c.spikes(154, 2)
    c.spikes(155, 1)
    c.up(156, 1, 1.6 * 133.5)
    c.spikes(157, 1)
    c.up(158, 1, 0.75 * 133.5)
    c.down(159, 0.0, spikes=3)
    c.pad(160.5, spikes=3)
    c.orb(162.5, spikes=5)
    c.orb(165, spikes=4, kind=K.PINK_ORB)
    c.spikes(167, 2)
    c.pad(168, spikes=2, onto=4, length=3.0 * 133.5)
    c.spikes(169.5, 1)
    c.spikes(170.5, 2)
    c.down(171.5, 0.0, spikes=3)
    c.spikes(173, 1)
    c.spikes(174, 1)
    c.spikes(175, 2)
    c.up(176, 2, 1.6 * 133.5)
    c.spikes(177, 1)
    c.down(178, 0.0, spikes=3)
    c.spikes(179.5, 1)
    c.spikes(180.5, 2)
    c.spikes(181.5, 1)

    seafloor_deco(lv, x0, x1 + 200, seed=61, density=1.2)
    for o in [o for o in lv.objects if o.kind == "solid" and x0 < o.x < x1]:
        decorate_solid(lv, o, "rock")
    # a lobster swimming alongside the player at the same speed
    g = lv.new_group()
    A.lobster(lv, x0 + 40, 230, 0.75, z_layer=K.B1, z=0, groups=[g])
    lv.move(x0 + 20, g, int((x1 - x0) * 0.98), 0, (x1 - x0) / P.SPEED[1])
    for j, b in enumerate(range(S_ESC, S_OUT)):
        lv.move(bx(b), g, 0, 7 if j % 2 == 0 else -7, BEAT * 0.9,
                K.EASE_SINE_IN_OUT)
    # lobster parade at the end of the section
    for i in range(5):
        lx = bx(178) + 150 * i
        walking_lobster(lv, lx, 22, 0.7, 520, 7.0, lx - 700, z_layer=K.B3,
                        palette=(FAR_LOBSTER, RED_DARK, RED))
    for i, kx in enumerate(range(int(x0 + 200), int(x1), 600)):
        swaying_kelp(lv, kx, -2, 210, seed=300 + i,
                     beats=range(S_ESC + i % 2, S_OUT + 4, 2))
        A.coral(lv, kx + 260, -2, 90, seed=i, z_layer=K.B3)
    bubbles(lv, x0, x1, x0 - 100, seed=63)
    palette_change(lv, x0 - 30, "escape", 0.6)
    lv.zoom(x0 + 20, 1.0, 0.5)
    return c


def section_outro(lv, plan):
    x0, x1 = bx(S_OUT), bx(S_END)
    palette_change(lv, x0, "outro", 2.5)
    seafloor_deco(lv, x0, x1 + 500, seed=71, density=1.3)
    kx = x0 + 1050
    A.rock(lv, kx - 30, -2, 420, 110, ROCK, K.B3, -2, seed=72)
    A.lobster(lv, kx, 175, 2.4, z_layer=K.B3, z=0)
    A.crown(lv, kx + 8 * 2.4, 175 + 15 * 2.4, 46, z_layer=K.B3, z=60)
    for i, (ox, s, flip) in enumerate(((-330, 0.8, False), (330, 0.8, True),
                                       (-520, 0.6, False), (520, 0.6, True))):
        g = lv.new_group()
        A.lobster(lv, kx + ox, 40, s, flip=flip, z_layer=K.B3, z=0, groups=[g])
        for j, b in enumerate(range(S_OUT, S_END + 8)):
            lv.move(bx(b), g, 0, 6 if j % 2 == 0 else -6, BEAT * 0.9,
                    K.EASE_SINE_IN_OUT)
    lv.text(kx, 300, "THANKS FOR PLAYING", scale=0.9, color=WHITE,
            z_layer=K.T1)
    lv.text(kx, 270, "Lobster Lagoon - built with the GD Skills Pack",
            scale=0.45, color=GOLD, z_layer=K.T1)
    bubbles(lv, x0, x1 + 300, x0 - 200, seed=73, rise=360, dur=8)
    lv.zoom(x0 + 300, 0.78, BEAT * 6)
    lv.trigger(K.END_TRIGGER, bx(S_END - 2))


# ---------------------------------------------------------------- level

def build():
    lv = K.Level(NAME)
    plan = Plan()
    setup_channels(lv)
    reports = {}
    reports["seafloor"] = section_seafloor(lv, plan).report
    palette_change(lv, bx(S_TRAP) - 30, "trap", 0.8)
    section_trap(lv, plan)
    palette_change(lv, bx(S_CLAW) - 30, "claw", 0.8)
    section_claw(lv, plan)
    palette_change(lv, bx(S_KELP) - 30, "kelp", 0.8)
    section_kelp(lv, plan)
    section_boil(lv, plan)
    reports["escape"] = section_escape(lv, plan).report
    section_outro(lv, plan)
    # music guidelines: green on each bar, yellow on the other beats
    for b in range(0, S_END + 1):
        lv.guidelines.append((b * BEAT, 1.0 if b % 4 == 0 else 0.9))
    plan.presses.sort()
    lv.chunk_long_objects()
    return lv, plan, reports


DESCRIPTION = ("Escape the trap, dodge the claws and survive the boiling pot! "
               "A lobster adventure on The Seven Seas. 3 coins.")


def main():
    creator = ""
    if "--creator" in sys.argv:
        creator = sys.argv[sys.argv.index("--creator") + 1]
    lv, plan, reports = build()
    with open("level_string.txt", "w") as f:
        f.write(lv.level_string())
    with open("Lobster_Lagoon.gmd", "w") as f:
        f.write(lv.gmd(creator, DESCRIPTION, SONG_ID, 3))
    print(f"{len(lv.objects)} objects, {lv._next_group - 1} groups, "
          f"{len(plan.presses)} clicks planned")
    for name, rep in reports.items():
        tight = min(m for _, _, m in rep)
        print(f"  {name}: {len(rep)} cube moves, tightest layout margin {tight:.1f} units")


if __name__ == "__main__":
    main()
