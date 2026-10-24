"""Small toolkit for building Geometry Dash 2.2 levels from Python.

Object IDs and property keys come from the gd-docs / gd-info-explorer data in
Mifu999/GD-Skills-Pack-for-Claude (gd-docs.skill). Positions are in GD units:
one grid block is 30 units, the first row of blocks sits at y = 15.
"""

import base64
import gzip
import math
from xml.sax.saxutils import escape

BLOCK = 30

# --- object IDs (looked up with gd.py obj <id>) --------------------------------
SQUARE = 211          # Colored Inner Square: plain 30x30 fill
DECO_SLOPE = 693      # Decorative Colored Slope: plain filled right triangle
CIRCLE = 3621
HOLLOW_CIRCLE = 3622
TEXT = 914
SPIKE = 8
YELLOW_PAD, PINK_PAD = 35, 140
YELLOW_ORB, PINK_ORB = 36, 141
USER_COIN = 1329
PORTAL = {"cube": 12, "ship": 13, "ball": 47, "ufo": 111, "wave": 660,
          "robot": 745, "spider": 1331, "swing": 1933}
SPEED_PORTAL = {0.5: 200, 1: 201, 2: 202, 3: 203, 4: 1334}
GRASS_PATCHES = (406, 407, 408, 414)
TALL_CHAIN, SMALL_CHAIN = 41, 110

COLOR_TRIGGER = 899
MOVE_TRIGGER = 901
PULSE_TRIGGER = 1006
ALPHA_TRIGGER = 1007
TOGGLE_TRIGGER = 1049
SPAWN_TRIGGER = 1268
ROTATE_TRIGGER = 1346
SHAKE_TRIGGER = 1520
ZOOM_TRIGGER = 1913
SHOCKWAVE_TRIGGER = 2905
END_TRIGGER = 3600

# --- channel IDs ---------------------------------------------------------------
BG, GROUND, LINE, OBJ, GROUND2 = 1000, 1001, 1002, 1004, 1009

# Z layers as stored in key 24
B5, B4, B3, B2, B1, T1, T2, T3 = -5, -3, -1, 1, 3, 5, 7, 9

# readable names for the property keys we use
KEY = {
    "id": 1, "x": 2, "y": 3, "flipx": 4, "flipy": 5, "rot": 6,
    "red": 7, "green": 8, "blue": 9, "duration": 10, "touch": 11,
    "checked": 13, "blending": 17, "editor_layer": 20,
    "color": 21, "color2": 22, "target_color": 23, "z_layer": 24,
    "z_order": 25, "move_x": 28, "move_y": 29, "easing": 30, "text": 31,
    "scale": 32, "opacity": 35, "fade_in": 45, "hold": 46, "fade_out": 47,
    "target": 51, "target_type": 52, "groups": 57, "spawn": 62, "delay": 63,
    "dont_fade": 64, "dont_enter": 67, "degrees": 68, "x360": 69,
    "center": 71, "strength": 75, "interval": 84, "easing_rate": 85,
    "multi": 87, "no_touch": 121, "scale_x": 128, "scale_y": 129,
    "zoom": 371, "sw_speed": 175, "sw_strength": 176, "sw_time_off": 177,
    "sw_wave_w": 179, "sw_thickness": 180, "sw_fade_in": 181,
    "sw_fade_out": 182, "sw_target": 188, "sw_p1": 138,
}

EASE_NONE, EASE_IN_OUT, EASE_IN, EASE_OUT = 0, 1, 2, 3
EASE_SINE_IN_OUT, EASE_SINE_OUT = 13, 15
EASE_BOUNCE_OUT, EASE_ELASTIC_OUT, EASE_BACK_OUT = 9, 6, 18
EASE_EXP_OUT = 12


def fmt(v):
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if abs(v - round(v)) < 1e-6:
            return str(int(round(v)))
        s = f"{v:.4f}".rstrip("0").rstrip(".")
        return "0" if s in ("-0", "") else s
    if isinstance(v, (list, tuple)):
        return ".".join(str(int(g)) for g in v)
    return str(v)


class Obj:
    """One level object. `kind` is only used by the verifier and preview."""

    __slots__ = ("props", "kind")

    def __init__(self, oid, x, y, kind="deco", **props):
        self.kind = kind
        self.props = {1: oid, 2: float(x), 3: float(y)}
        for name, value in props.items():
            if value is None:
                continue
            self.props[KEY[name] if name in KEY else int(name)] = value

    def __getitem__(self, name):
        return self.props.get(KEY.get(name, name))

    @property
    def oid(self):
        return self.props[1]

    @property
    def x(self):
        return self.props[2]

    @property
    def y(self):
        return self.props[3]

    def encode(self):
        out = []
        for k, v in self.props.items():
            if k in (4, 5, 13, 17, 62, 64, 67, 87, 121) and not v:
                continue
            if k == 57 and not v:
                continue
            out.append(f"{k},{fmt(v)}")
        return ",".join(out)


class Level:
    def __init__(self, name):
        self.name = name
        self.objects = []
        self.channels = {}          # channel -> dict(rgb, opacity, blending)
        self._trigger_rows = {}     # x bucket -> count, keeps triggers stacked
        self._next_group = 1
        self.guidelines = []        # (seconds, color value)
        self.header_extra = {}

    # -- groups -----------------------------------------------------------------
    def new_group(self):
        g = self._next_group
        self._next_group += 1
        return g

    # -- raw add ------------------------------------------------------------------
    def add(self, oid, x, y, kind="deco", **props):
        o = Obj(oid, x, y, kind, **props)
        self.objects.append(o)
        return o

    def channel(self, ch, rgb, opacity=1.0, blending=False):
        self.channels[ch] = dict(rgb=tuple(int(c) for c in rgb),
                                 opacity=opacity, blending=blending)

    # -- art primitives -----------------------------------------------------------
    def rect(self, cx, cy, w, h, color, rot=0.0, z_layer=B2, z_order=0,
             groups=None, solid=False, editor_layer=1):
        """Axis-aligned or rotated rectangle from one Colored Inner Square.

        `rot` is counter-clockwise degrees (GD's key 6 is clockwise)."""
        return self.add(
            SQUARE, cx, cy, "solid" if solid else "deco",
            scale_x=round(w / BLOCK, 4), scale_y=round(h / BLOCK, 4),
            rot=round(-rot, 3) if rot else None, color=color,
            z_layer=z_layer, z_order=z_order, groups=groups,
            no_touch=None if solid else True, editor_layer=editor_layer)

    def tri(self, x0, y0, x1, y1, corner, color, z_layer=B2, z_order=0,
            groups=None, editor_layer=1):
        """Right triangle filling the box [x0,x1]x[y0,y1].

        `corner` names the right-angle corner: 'BR' (the default GD slope),
        'BL', 'TR' or 'TL'."""
        w, h = x1 - x0, y1 - y0
        if w < 0.2 or h < 0.2:
            return None
        flipx = corner in ("BL", "TL")
        flipy = corner in ("TR", "TL")
        return self.add(
            DECO_SLOPE, (x0 + x1) / 2, (y0 + y1) / 2, "deco",
            scale_x=round(w / BLOCK, 4), scale_y=round(h / BLOCK, 4),
            flipx=flipx or None, flipy=flipy or None, color=color,
            z_layer=z_layer, z_order=z_order, groups=groups, no_touch=True,
            editor_layer=editor_layer)

    def poly(self, pts, color, z_layer=B2, z_order=0, groups=None,
             editor_layer=1):
        """Fill a convex polygon exactly with horizontal trapezoid strips
        (one square + up to two decorative slopes per strip)."""
        made = []
        merged = sorted({round(p[1], 2) for p in pts})
        if len(merged) < 2:
            return made
        n = len(pts)
        edges = [(pts[i], pts[(i + 1) % n]) for i in range(n)]
        c = self.channels.get(color)
        translucent = bool(c and (c["opacity"] < 1 or c["blending"]))
        # opaque fills overlap a hair to hide seams; translucent ones must
        # not overlap or the overlap shows up brighter/darker
        pad = 0.0 if translucent else 0.35
        tp = 0.0 if translucent else 0.2

        def x_on(edge, y):
            (ax, ay), (bx, by) = edge
            if abs(by - ay) < 1e-9:
                return ax
            x = ax + (bx - ax) * (y - ay) / (by - ay)
            return min(max(x, min(ax, bx)), max(ax, bx))

        for y0, y1 in zip(merged, merged[1:]):
            if y1 - y0 < 0.3:
                continue
            ym = (y0 + y1) / 2
            cross = [e for e in edges
                     if min(e[0][1], e[1][1]) <= ym <= max(e[0][1], e[1][1])
                     and abs(e[0][1] - e[1][1]) > 1e-9]
            if len(cross) < 2:
                continue
            cross.sort(key=lambda e: x_on(e, ym))
            le, re_ = cross[0], cross[-1]
            xl0, xl1 = x_on(le, y0), x_on(le, y1)
            xr0, xr1 = x_on(re_, y0), x_on(re_, y1)
            inner_l, inner_r = max(xl0, xl1), min(xr0, xr1)
            if inner_r - inner_l > 0.2:
                made.append(self.rect((inner_l + inner_r) / 2, ym,
                                      inner_r - inner_l + 2 * pad,
                                      y1 - y0 + 2 * pad, color,
                                      z_layer=z_layer, z_order=z_order,
                                      groups=groups,
                                      editor_layer=editor_layer))
            if abs(xl0 - xl1) > 0.3:
                corner = "BR" if xl1 > xl0 else "TR"
                made.append(self.tri(min(xl0, xl1), y0 - tp,
                                     max(xl0, xl1) + tp, y1 + tp, corner,
                                     color, z_layer, z_order, groups,
                                     editor_layer))
            if abs(xr0 - xr1) > 0.3:
                corner = "TL" if xr1 > xr0 else "BL"
                made.append(self.tri(min(xr0, xr1) - tp, y0 - tp,
                                     max(xr0, xr1), y1 + tp, corner,
                                     color, z_layer, z_order, groups,
                                     editor_layer))
        return [m for m in made if m is not None]

    def ellipse(self, cx, cy, rx, ry, color, rot=0.0, n=None, **kw):
        n = n or max(10, min(28, int((rx + ry) / 4)))
        c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        pts = []
        for i in range(n):
            a = 2 * math.pi * (i + 0.5) / n
            px, py = rx * math.cos(a), ry * math.sin(a)
            pts.append((cx + px * c - py * s, cy + px * s + py * c))
        return self.poly(pts, color, **kw)

    def segment(self, x0, y0, x1, y1, thick, color, **kw):
        """A straight bar between two points (one rotated square)."""
        length = math.hypot(x1 - x0, y1 - y0)
        ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
        return self.rect((x0 + x1) / 2, (y0 + y1) / 2, length, thick, color,
                         rot=ang, **kw)

    def text(self, x, y, s, scale=1.0, color=None, z_layer=T1, groups=None):
        enc = base64.urlsafe_b64encode(s.encode()).decode()
        return self.add(TEXT, x, y, "text", text=enc, scale=scale,
                        color=color, z_layer=z_layer, groups=groups,
                        editor_layer=1)

    # -- gameplay -----------------------------------------------------------------
    def block(self, x0, y0, x1, y1, color, z_order=0):
        """Solid rectangle (gameplay collision) from x0..x1, y0..y1."""
        return self.add(SQUARE, (x0 + x1) / 2, (y0 + y1) / 2, "solid",
                        scale_x=round((x1 - x0) / BLOCK, 4),
                        scale_y=round((y1 - y0) / BLOCK, 4), color=color,
                        z_order=z_order, editor_layer=0)

    def spike(self, x, y, color, flip=False, rot=0):
        return self.add(SPIKE, x, y, "hazard", flipy=flip or None,
                        rot=rot or None, color=color, editor_layer=0)

    def portal(self, mode, x, y):
        return self.add(PORTAL[mode], x, y, "portal", checked=True,
                        editor_layer=0)

    def speed(self, mult, x, y):
        return self.add(SPEED_PORTAL[mult], x, y, "speed", checked=True,
                        editor_layer=0)

    # -- triggers -----------------------------------------------------------------
    def _trig_y(self, x):
        b = int(x // 15)
        k = self._trigger_rows.get(b, 0)
        self._trigger_rows[b] = k + 1
        return 465 + 30 * k

    def trigger(self, oid, x, **props):
        return self.add(oid, x, self._trig_y(x), "trigger", editor_layer=2,
                        **props)

    def color_trigger(self, x, ch, rgb, dur=0.0, opacity=1.0, blending=False):
        r, g, b = rgb
        return self.trigger(COLOR_TRIGGER, x, target_color=ch, red=int(r),
                            green=int(g), blue=int(b), duration=float(dur),
                            opacity=float(opacity),
                            blending=blending or None)

    def move(self, x, group, dx, dy, dur, easing=0, rate=None):
        return self.trigger(MOVE_TRIGGER, x, target=group, move_x=int(dx),
                            move_y=int(dy), duration=float(dur),
                            easing=easing or None, easing_rate=rate)

    def rotate(self, x, group, center, deg, dur, easing=0):
        # GD rotates clockwise for positive degrees; callers pass CCW degrees
        return self.trigger(ROTATE_TRIGGER, x, target=group, center=center,
                            degrees=float(-deg), duration=float(dur),
                            easing=easing or None)

    def alpha(self, x, group, opacity, dur):
        return self.trigger(ALPHA_TRIGGER, x, target=group,
                            opacity=float(opacity), duration=float(dur))

    def pulse(self, x, target, rgb, fade_in, hold, fade_out, group=False):
        r, g, b = rgb
        return self.trigger(PULSE_TRIGGER, x, target=target,
                            target_type=bool(group) or None, red=int(r),
                            green=int(g), blue=int(b),
                            fade_in=float(fade_in), hold=float(hold),
                            fade_out=float(fade_out))

    def shake(self, x, dur, strength, interval=0.0):
        return self.trigger(SHAKE_TRIGGER, x, duration=float(dur),
                            strength=float(strength),
                            interval=float(interval))

    def zoom(self, x, zoom, dur, easing=EASE_IN_OUT):
        return self.trigger(ZOOM_TRIGGER, x, zoom=float(zoom),
                            duration=float(dur), easing=easing)

    def chunk_long_objects(self, max_solid=120.0, max_deco=240.0):
        """GD culls objects by their position, so a very wide scaled block
        can pop out while it is still on screen. Split wide unrotated squares
        into pieces (solid ones into pieces of at most four blocks)."""
        out = []
        for o in self.objects:
            if o.oid != SQUARE or o["rot"]:
                out.append(o)
                continue
            w = BLOCK * (o["scale_x"] or 1)
            limit = max_solid if o.kind == "solid" else max_deco
            if w <= limit:
                out.append(o)
                continue
            n = int(math.ceil(w / limit))
            pw = w / n
            left = o.x - w / 2
            for i in range(n):
                p = Obj.__new__(Obj)
                p.kind = o.kind
                p.props = dict(o.props)
                p.props[2] = left + pw * (i + 0.5)
                ch = self.channels.get(o["color"])
                clear = ch and (ch["opacity"] < 1 or ch["blending"])
                extra = 0 if (o.kind == "solid" or clear) else 0.3
                p.props[128] = round((pw + extra) / BLOCK, 4)
                out.append(p)
        self.objects = out

    # -- encoding -----------------------------------------------------------------
    def color_string(self):
        parts = []
        for ch in sorted(self.channels):
            c = self.channels[ch]
            r, g, b = c["rgb"]
            s = (f"1_{r}_2_{g}_3_{b}_11_255_12_255_13_255_4_-1_"
                 f"{'5_1_' if c['blending'] else ''}6_{ch}_7_{fmt(float(c['opacity']))}"
                 f"_15_1_18_0_8_1")
            parts.append(s)
        return "|".join(parts) + "|"

    def header(self):
        guide = "~".join(f"{fmt(round(t, 4))}~{fmt(c)}"
                         for t, c in self.guidelines)
        if guide:
            guide += "~"
        h = {
            "kS38": self.color_string(), "kA13": 0, "kA15": 0, "kA16": 0,
            "kA14": guide, "kA6": 0, "kA7": 0, "kA25": 0, "kA17": 0,
            "kA18": 0, "kS39": 0, "kA2": 0, "kA3": 0, "kA8": 0, "kA4": 0,
            "kA9": 0, "kA10": 0, "kA22": 0, "kA23": 0, "kA24": 0, "kA27": 1,
            "kA40": 1, "kA41": 1, "kA42": 1, "kA28": 0, "kA29": 0,
            "kA31": 1, "kA32": 1, "kA36": 0, "kA43": 0, "kA44": 0,
            "kA45": 1, "kA33": 1, "kA34": 1, "kA35": 0, "kA37": 1,
            "kA38": 1, "kA39": 1, "kA19": 0, "kA26": 0, "kA20": 0,
            "kA21": 0, "kA11": 0,
        }
        h.update(self.header_extra)
        return ",".join(f"{k},{v}" for k, v in h.items())

    def level_string(self):
        objs = sorted(self.objects, key=lambda o: (o.x, o.y))
        return self.header() + ";" + ";".join(o.encode() for o in objs) + ";"

    def encoded(self):
        raw = self.level_string().encode()
        return base64.urlsafe_b64encode(gzip.compress(raw, 9)).decode()

    def gmd(self, creator, description, song_id, length_enum,
            seconds_editing=0):
        """GDShare-style .gmd (the level's plist dict on its own)."""
        desc = base64.urlsafe_b64encode(description.encode()).decode()
        ls = self.encoded()
        fields = [
            ("kCEK", "i", 4), ("k2", "s", self.name), ("k3", "s", desc),
            ("k4", "s", ls), ("k5", "s", creator), ("k8", "i", song_id),
            ("k13", "t", True), ("k16", "i", 1), ("k21", "i", 2),
            ("k23", "i", length_enum), ("k47", "t", True),
            ("k48", "i", len(self.objects)), ("k50", "i", 45),
            ("k80", "i", seconds_editing), ("kI1", "r", 0),
            ("kI2", "r", 150), ("kI3", "r", 1),
        ]
        body = []
        for k, t, v in fields:
            body.append(f"<k>{k}</k>")
            if t == "t":
                body.append("<t />")
            else:
                body.append(f"<{t}>{escape(str(v))}</{t}>")
        return ('<?xml version="1.0"?><plist version="1.0" gjver="2.0">'
                "<dict>" + "".join(body) + "</dict></plist>")
