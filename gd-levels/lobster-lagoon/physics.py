"""A tick-based approximation of GD 2.2 player physics, used as a play-test bot.

Values come from gd-docs reference/player_physics (gamemodes, orbs_and_pads,
hitboxes). 1 Vel = 60 units/s; the game runs physics at 240 ticks/s.
Where the docs do not pin a value down (ship thrust, ball/UFO gravity) the
verifier sweeps a range, so a section only passes if it works across all of it.
"""

import math
from collections import defaultdict

import gdkit as K

TPS = 240
DT = 1.0 / TPS
VEL = 60.0
SPEED = {0.5: 251.16, 1: 311.58, 2: 387.42, 3: 468.0, 4: 576.0}
CUBE_JUMP = {0.5: 10.62 * VEL, 1: 11.18 * VEL, 2: 11.42 * VEL,
             3: 11.23 * VEL, 4: 11.23 * VEL}
BALL_JUMP = {0.5: 3.186 * VEL, 1: 3.354 * VEL, 2: 3.426 * VEL,
             3: 3.369 * VEL, 4: 3.369 * VEL}
WAVE_VY = {0.5: 4.186 * VEL, 1: 5.193 * VEL, 2: 6.457 * VEL,
           3: 7.8 * VEL, 4: 9.6 * VEL}
# 11.18 - 0.216 per tick at 240 tps (gamemodes.md) -> cube gravity
G_CUBE = 0.216 * VEL * TPS
MAX_FALL = 15 * VEL
UFO_CLICK = 7 * VEL
UFO_MAX_FALL = 6.4 * VEL
SHIP_MAX_UP, SHIP_MAX_DOWN = 8 * VEL, 6.4 * VEL
PAD_VY = {K.YELLOW_PAD: 16 * VEL, K.PINK_PAD: 10.4 * VEL}
ORB_MULT = {K.YELLOW_ORB: 1.0, K.PINK_ORB: 0.72}

DEFAULT_PARAMS = dict(ball_g=0.6, ufo_g=0.5, ship_up=2400.0, ship_down=2000.0)

HALF = {"cube": 15, "ship": 15, "ball": 15, "ufo": 15, "wave": 5}
PORTAL_MODE = {v: k for k, v in K.PORTAL.items()}
SPEED_OF = {v: k for k, v in K.SPEED_PORTAL.items()}


class Box:
    __slots__ = ("x0", "y0", "x1", "y1", "obj")

    def __init__(self, x0, y0, x1, y1, obj=None):
        self.x0, self.y0, self.x1, self.y1, self.obj = x0, y0, x1, y1, obj

    def hits(self, x0, y0, x1, y1):
        return x0 < self.x1 and x1 > self.x0 and y0 < self.y1 and y1 > self.y0


def spike_box(o):
    """Conservative spike hitbox: GD's is about 6x12, we use 9x21."""
    x, y = o.x, o.y
    rot = (o["rot"] or 0) % 360
    flip = bool(o["flipy"])
    if rot in (90, 270):
        # pointing sideways
        lo, hi = (-12, 9) if (rot == 90) != flip else (-9, 12)
        return Box(x + lo, y - 4.5, x + hi, y + 4.5, o)
    lo, hi = (-9, 12) if flip else (-12, 9)
    return Box(x - 4.5, y + lo, x + 4.5, y + hi, o)


def object_box(o):
    w = K.BLOCK * (o["scale_x"] or 1) * (o["scale"] or 1)
    h = K.BLOCK * (o["scale_y"] or 1) * (o["scale"] or 1)
    return Box(o.x - w / 2, o.y - h / 2, o.x + w / 2, o.y + h / 2, o)


class World:
    def __init__(self, level, ceiling=300.0):
        self.cell = 60
        self.solids = defaultdict(list)
        self.hazards = defaultdict(list)
        self.items = defaultdict(list)    # orbs, pads, portals, coins
        self.ceiling = ceiling
        for o in level.objects:
            if o.kind == "solid" and not o["no_touch"]:
                self._put(self.solids, object_box(o))
            elif o.kind == "hazard" and not o["no_touch"]:
                self._put(self.hazards, spike_box(o))
            elif o.oid in PAD_VY:
                b = Box(o.x - 12, o.y - 15, o.x + 12, o.y - 9, o)
                if o["flipy"]:
                    b = Box(o.x - 12, o.y + 9, o.x + 12, o.y + 15, o)
                self._put(self.items, b)
            elif o.oid in ORB_MULT:
                self._put(self.items, Box(o.x - 13, o.y - 13, o.x + 13,
                                          o.y + 13, o))
            elif o.oid in PORTAL_MODE or o.oid in SPEED_OF:
                self._put(self.items, Box(o.x - 12, o.y - 40, o.x + 12,
                                          o.y + 40, o))
            elif o.oid == K.USER_COIN:
                self._put(self.items, Box(o.x - 14, o.y - 14, o.x + 14,
                                          o.y + 14, o))

    def _put(self, grid, box):
        for c in range(int(box.x0 // self.cell), int(box.x1 // self.cell) + 1):
            grid[c].append(box)

    def near(self, grid, x0, x1):
        seen = set()
        for c in range(int(x0 // self.cell), int(x1 // self.cell) + 1):
            for b in grid.get(c, ()):
                if id(b) not in seen:
                    seen.add(id(b))
                    yield b


class State:
    __slots__ = ("x", "y", "vy", "mode", "speed", "grav", "ground", "tick",
                 "dead", "why", "used", "coins", "held", "last_press")

    def __init__(self, x=0.0, y=15.0, mode="cube", speed=1):
        self.x, self.y, self.vy = x, y, 0.0
        self.mode, self.speed, self.grav = mode, speed, 1
        self.ground = True
        self.tick = 0
        self.dead = False
        self.why = ""
        self.used = set()     # ids of orbs/pads/portals already triggered
        self.coins = set()
        self.held = False
        self.last_press = -999

    def copy(self):
        s = State.__new__(State)
        for k in State.__slots__:
            setattr(s, k, getattr(self, k))
        s.used = set(self.used)
        s.coins = set(self.coins)
        return s


def step(world, s, hold, p):
    """Advance one tick. `hold` is whether the button is down this tick."""
    pressed = hold and not s.held
    s.held = hold
    if pressed:
        s.last_press = s.tick
    half = HALF[s.mode]
    vx = SPEED[s.speed]
    g = s.grav

    # -- orbs (need a click while overlapping) and pads --------------------------
    for b in world.near(world.items, s.x - half, s.x + half):
        o = b.obj
        if id(o) in s.used or not b.hits(s.x - half, s.y - half, s.x + half,
                                         s.y + half):
            continue
        if o.oid in ORB_MULT and pressed and s.mode in ("cube", "ball", "ufo",
                                                        "ship"):
            s.used.add(id(o))
            s.vy = g * CUBE_JUMP[s.speed] * ORB_MULT[o.oid]
            s.ground = False
            pressed = False
        elif o.oid in PAD_VY and s.mode in ("cube", "ship", "ufo"):
            s.used.add(id(o))
            s.vy = g * PAD_VY[o.oid] * (0.5 if s.mode != "cube" else 1.0)
            s.ground = False
        elif o.oid in PORTAL_MODE:
            s.used.add(id(o))
            new = PORTAL_MODE[o.oid]
            if new != s.mode:
                s.mode = new
                if new == "wave":
                    s.vy = 0.0
                else:
                    s.vy *= 0.5
                half = HALF[s.mode]
        elif o.oid in SPEED_OF:
            s.used.add(id(o))
            s.speed = SPEED_OF[o.oid]
            vx = SPEED[s.speed]
        elif o.oid == K.USER_COIN:
            s.used.add(id(o))
            s.coins.add(round(o.x))

    # -- vertical motion -----------------------------------------------------------
    m = s.mode
    if m == "cube":
        if pressed or (hold and s.ground):
            if s.ground:
                s.vy = g * CUBE_JUMP[s.speed]
                s.ground = False
        s.vy -= g * G_CUBE * DT
        s.vy = max(s.vy, -MAX_FALL) if g > 0 else min(s.vy, MAX_FALL)
    elif m == "ball":
        if pressed and s.ground:
            s.vy = g * BALL_JUMP[s.speed]
            s.grav = g = -g
            s.ground = False
        s.vy -= g * G_CUBE * p["ball_g"] * DT
        s.vy = max(min(s.vy, MAX_FALL), -MAX_FALL)
    elif m == "ufo":
        if pressed:
            s.vy = g * UFO_CLICK
            s.ground = False
        s.vy -= g * G_CUBE * p["ufo_g"] * DT
        s.vy = max(s.vy, -UFO_MAX_FALL) if g > 0 else min(s.vy, UFO_MAX_FALL)
    elif m == "ship":
        s.vy += (p["ship_up"] if hold else -p["ship_down"]) * DT * g
        s.vy = max(min(s.vy, SHIP_MAX_UP), -SHIP_MAX_DOWN)
    elif m == "wave":
        s.vy = (1 if hold else -1) * g * WAVE_VY[s.speed]

    py_old = s.y
    s.y += s.vy * DT
    s.x += vx * DT
    s.tick += 1

    # -- world bounds --------------------------------------------------------------
    if s.y - half < 0:
        if m == "wave" and s.vy < 0 and py_old - half > 0.5:
            pass  # wave may slide on the ground in 2.2, but we treat a hit as unsafe
        s.y = half
        if m == "wave":
            s.dead, s.why = True, "wave hit the ground"
            return s
        if g > 0 or m in ("ship", "ufo"):
            s.vy = max(s.vy, 0.0) if g > 0 else s.vy
            s.ground = g > 0
    if m in ("ship", "ufo", "wave", "ball") and s.y + half > world.ceiling:
        s.y = world.ceiling - half
        if m == "wave":
            s.dead, s.why = True, "wave hit the ceiling"
            return s
        s.vy = min(s.vy, 0.0)
        s.ground = g < 0

    # -- solids ----------------------------------------------------------------------
    if m == "cube" or m == "ball":
        s.ground = False if s.y - half > 0.01 or g < 0 else s.ground
    on_surface = s.y - half <= 0.01 and g > 0
    for b in world.near(world.solids, s.x - half, s.x + half):
        if not b.hits(s.x - half, s.y - half, s.x + half, s.y + half):
            continue
        if m == "wave":
            s.dead, s.why = True, f"wave hit block at {b.x0:.0f},{b.y0:.0f}"
            return s
        was_above = py_old - half >= b.y1 - 0.5
        was_below = py_old + half <= b.y0 + 0.5
        if was_above and s.vy <= 0:
            s.y = b.y1 + half
            s.vy = 0.0
            if g > 0:
                on_surface = True
        elif was_below and s.vy >= 0 and (g < 0 or m in ("ship", "ufo")):
            s.y = b.y0 - half
            s.vy = 0.0
            if g < 0:
                on_surface = True
        else:
            s.dead, s.why = True, f"{m} crashed into block at x={b.x0:.0f} y={b.y0:.0f}-{b.y1:.0f}"
            return s
    if m in ("cube", "ball"):
        s.ground = on_surface or (g < 0 and s.y + half >= world.ceiling - 0.01
                                  and m == "ball")
    elif m in ("ship", "ufo"):
        s.ground = on_surface

    # -- hazards -----------------------------------------------------------------------
    for b in world.near(world.hazards, s.x - half, s.x + half):
        if b.hits(s.x - half, s.y - half, s.x + half, s.y + half):
            s.dead, s.why = True, f"{m} hit spike at x={b.obj.x:.0f} y={b.obj.y:.0f}"
            return s
    return s


def run(world, policy, start=None, until_x=1e9, params=None, record=False,
        max_ticks=200000):
    p = dict(DEFAULT_PARAMS)
    if params:
        p.update(params)
    s = start.copy() if start else State()
    trace = []
    while s.x < until_x and not s.dead and s.tick < max_ticks:
        hold = policy(s)
        step(world, s, hold, p)
        if record:
            trace.append((s.x, s.y, s.mode, hold))
    return s, trace
