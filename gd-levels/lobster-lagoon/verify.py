"""Play-tests Lobster Lagoon with a bot and reports how forgiving each part is.

    python3 verify.py

1. Plays the whole level with the reference inputs (clicks on the beat for
   cube/ball, a tracking controller for ship/UFO/wave).
2. Repeats that with the physics values the docs leave open swept over a
   range (ball/UFO gravity, ship thrust) - every run must reach the end.
3. For each cube/ball click, finds how early/late it can be and still pass.
4. Reports the closest the player gets to a block or spike in ship/UFO/wave.
"""

import sys

import numpy as np

import build_level as B
import physics as P

HOLD_TICKS = 5
BOUNDS = (B.S_TRAP, B.S_CLAW, B.S_KELP, B.S_DROP, B.S_ESC, B.S_OUT, B.S_END,
          10 ** 5)


def segment_lookup(entries, x):
    for x0, x1, fn in entries:
        if x0 - 40 <= x <= x1 + 40:
            return fn
    return None


def make_policy(plan, presses=None, hold_ticks=HOLD_TICKS, skip_before=-1e9,
                params=None, ufo_clicks=None):
    prm = dict(P.DEFAULT_PARAMS)
    prm.update(params or {})
    # a skilled player knows how high one UFO click goes and clicks at the
    # bottom of the bob so it stays centred on the gap

    presses = sorted(plan.presses if presses is None else presses)
    first = sum(1 for p in presses if p < skip_before)
    st = {"i": first, "hold_until": -1, "last_click": -99, "clicking": False}

    def policy(s):
        while st["i"] < len(presses) and presses[st["i"]] <= s.x:
            st["hold_until"] = s.tick + hold_ticks
            st["i"] += 1
        if s.mode in ("cube", "ball"):
            return s.tick < st["hold_until"]
        if s.mode == "ship":
            fn = segment_lookup(plan.ship, s.x)
            tgt = fn(s.x + 25) if fn else 150
            return s.y + s.vy * 0.14 < tgt
        if s.mode == "ufo":
            if ufo_clicks is not None:
                st.setdefault("u", 0)
                fire = False
                while st["u"] < len(ufo_clicks) and ufo_clicks[st["u"]] <= s.tick:
                    st["u"] += 1
                    fire = True
                return fire
            if st["clicking"]:
                st["clicking"] = False
                return False
            if s.tick - st["last_click"] < 8 or s.tick % 2:
                return False
            if ufo_should_click(plan, s, prm):
                st["last_click"] = s.tick
                st["clicking"] = True
                return True
            return False
        if s.mode == "wave":
            fn = segment_lookup(plan.wave, s.x)
            return s.y < (fn(s.x + 1.6) if fn else 150)
        return False
    return policy


def ufo_should_click(plan, s, prm):
    """Model-predictive UFO play: try 'no click', 'click now' and 'click a
    bit later' against the openings of the gate we are in and the next one."""
    g = P.G_CUBE * prm["ufo_g"]
    v = P.SPEED[s.speed]
    gates = [gt for gt in plan.ufo_gates if gt[0] + 40 > s.x]
    if not gates:
        fn = segment_lookup(plan.ufo, s.x)
        tgt = fn(s.x + 60) if fn else 150
        return s.y < tgt - 25 and s.vy < 0
    window = gates[:1]
    x_end = window[-1][0] + 40

    def safe(click_ticks):
        y, vy, x, t = s.y, s.vy, s.x, 0
        clicks = set(click_ticks)
        while x < x_end:
            if t in clicks:
                vy = P.UFO_CLICK
            vy = max(vy - g * P.DT, -P.UFO_MAX_FALL)
            y += vy * P.DT
            x += v * P.DT
            t += 1
            if y < 20 or y > 250:
                return False
            for gx, yc, hg in window:
                if gx - 37 <= x <= gx + 37:
                    if y < yc - hg + 20 or y > yc + hg - 20:
                        return False
        return True

    if safe([]):
        return False
    if safe([0]):
        return True
    for k in range(4, 60, 4):
        if safe([k]):
            return False          # a later click works: wait for it
    for k in range(20, 80, 6):    # two clicks needed (climbing)
        if safe([0, k]):
            return True
    nxt = window[0]
    return s.y < nxt[1] and s.vy < 30


def plan_ufo(plan, start, prm, x_goal, every=4, margin=2.0):
    """Exhaustive search over click timings (one decision every `every`
    ticks) through the kelp gates. Keeps, for each (y, vy) cell, the path
    with the largest minimum clearance, and returns the click ticks of the
    best path that reaches the wave portal - or None if no path exists."""
    g = P.G_CUBE * prm["ufo_g"]
    v = P.SPEED[start.speed]
    gates = plan.ufo_gates
    Y = np.array([start.y])
    VY = np.array([start.vy])
    CLR = np.array([99.0])
    hist = []
    x = start.x
    tick = start.tick
    while x < x_goal:
        ny, nvy, nclr, par, act = [], [], [], [], []
        for a in (0, 1):
            y = Y.copy()
            vy = np.where(a == 1, P.UFO_CLICK, VY) if a else VY.copy()
            clr = CLR.copy()
            alive = np.ones(len(y), bool)
            xx = x
            for _ in range(every):
                vy = np.maximum(vy - g * P.DT, -P.UFO_MAX_FALL)
                y = y + vy * P.DT
                xx += v * P.DT
                low = y < 15
                y = np.where(low, 15.0, y)
                vy = np.where(low, np.maximum(vy, 0), vy)
                high = y > 255
                y = np.where(high, 255.0, y)
                vy = np.where(high, np.minimum(vy, 0), vy)
                lo, hi = 15.0, 255.0
                for gx, yc, hg in gates:
                    if abs(xx - gx) < 35:
                        lo, hi = max(lo, yc - hg + 15), min(hi, yc + hg - 15)
                if lo > 15 or hi < 255:
                    alive &= (y >= lo + margin) & (y <= hi - margin)
                    clr = np.minimum(clr, np.minimum(y - lo, hi - y))
                for cx, cy in plan.ufo_coins:      # route through the coin
                    if abs(xx - cx) < v * P.DT / 2 + 0.01:
                        alive &= np.abs(y - cy) < 18
            idx = np.nonzero(alive)[0]
            ny.append(y[idx]); nvy.append(vy[idx]); nclr.append(clr[idx])
            par.append(idx); act.append(np.full(len(idx), a))
        Y, VY, CLR = np.concatenate(ny), np.concatenate(nvy), np.concatenate(nclr)
        PAR, ACT = np.concatenate(par), np.concatenate(act)
        if len(Y) == 0:
            return None
        key = np.round(Y / 1.5).astype(np.int64) * 1000 + np.round(VY / 12).astype(np.int64)
        order = np.lexsort((-CLR, key))
        key_sorted = key[order]
        first = np.ones(len(order), bool)
        first[1:] = key_sorted[1:] != key_sorted[:-1]
        keep = order[first]
        Y, VY, CLR = Y[keep], VY[keep], CLR[keep]
        hist.append((PAR[keep], ACT[keep], tick))
        x += v * every * P.DT
        tick += every
    ok = np.nonzero((Y > 118) & (Y < 182))[0]
    if len(ok) == 0:
        return None
    i = ok[np.argmax(CLR[ok])]
    best_clr = float(CLR[i])
    clicks = []
    for par, act, t in reversed(hist):
        if act[i]:
            clicks.append(t)
        i = par[i]
    return sorted(clicks), best_clr


def clearance(world, s):
    """Gap in units between the player box and the closest block/spike."""
    half = P.HALF[s.mode]
    best = 1e9
    for grid in (world.solids, world.hazards):
        for b in world.near(grid, s.x - half - 60, s.x + half + 60):
            dx = max(b.x0 - (s.x + half), (s.x - half) - b.x1, 0)
            dy = max(b.y0 - (s.y + half), (s.y - half) - b.y1, 0)
            if dx < 60 and dy < 60:
                best = min(best, max(dx, dy) if (dx > 0 and dy > 0) else dx + dy)
    return best


UFO_CACHE = {}


def full_run(lv, plan, world, params=None, record=False):
    """Play the level. The UFO part uses the searched-for best path."""
    end_x = B.bx(B.S_END) + 10
    prm = dict(P.DEFAULT_PARAMS)
    prm.update(params or {})
    # play up to the UFO portal, then search the kelp forest from there
    pol = make_policy(plan, params=prm)
    s = P.State()
    trace = []
    while not s.dead and s.mode != "ufo" and s.x < end_x:
        h = pol(s)
        P.step(world, s, h, prm)
        if record:
            trace.append((s.x, s.y, s.mode, h))
    clicks = None
    if not s.dead and s.mode == "ufo":
        key = tuple(sorted(prm.items()))
        if key not in UFO_CACHE:
            UFO_CACHE[key] = plan_ufo(plan, s, prm, B.bx(B.S_DROP) - 30)
        res = UFO_CACHE[key]
        if res is None:
            s.dead, s.why = True, "no UFO path exists through the kelp gates"
            return s, trace
        clicks = res[0]
    pol2 = make_policy(plan, params=prm, ufo_clicks=clicks, skip_before=s.x)
    end, tr2 = P.run(world, pol2, s, until_x=end_x, params=prm, record=record)
    return end, trace + tr2


def section_of(x):
    names = [(B.S_TRAP, "seafloor (cube)"), (B.S_CLAW, "lobster trap (ship)"),
             (B.S_KELP, "claw tunnel (ball)"), (B.S_DROP, "kelp forest (UFO)"),
             (B.S_ESC, "the boil (wave 2x)"), (B.S_OUT, "escape (cube)"),
             (10 ** 6, "outro")]
    for b, n in names:
        if x < B.bx(b):
            return n
    return "end"


def timing_windows(lv, plan, world):
    presses = sorted(plan.presses)
    ref_states = {}
    # capture a state ~70 units before each click from the reference run
    pol = make_policy(plan)
    s = P.State()
    k = 0
    while k < len(presses) and not s.dead:
        if s.x >= presses[k] - 70:
            ref_states[k] = s.copy()
            k += 1
            continue
        P.step(world, s, pol(s), P.DEFAULT_PARAMS)
    out = []
    for k, px in enumerate(presses):
        if k not in ref_states:
            continue
        start = ref_states[k]
        stop = presses[k + 2] + 40 if k + 2 < len(presses) else px + 400
        stop = min(stop, next(B.bx(b) for b in BOUNDS if B.bx(b) > px))
        v = P.SPEED[start.speed]

        def ok(d):
            alt = list(presses)
            alt[k] = px + d * v / P.TPS
            pol = make_policy(plan, alt, skip_before=start.x)
            st = start.copy()
            end, _ = P.run(world, pol, st, until_x=stop)
            return not end.dead
        early = 0
        while early > -50 and ok(early - 1):
            early -= 1
        late = 0
        while late < 60 and ok(late + 1):
            late += 1
        out.append((px, early, late, ok(0)))
    return out


def main():
    lv, plan, _ = B.build()
    world = P.World(lv)
    ok_all = True
    print(f"Lobster Lagoon: {len(lv.objects)} objects, "
          f"length {B.S_END * B.BEAT:.1f}s at {B.BPM:.0f} BPM\n")

    end, trace = full_run(lv, plan, world, record=True)
    if end.dead:
        ok_all = False
        print(f"REFERENCE RUN FAILED at x={end.x:.0f} ({section_of(end.x)}): {end.why}")
    else:
        print(f"Reference run: completed, {len(end.coins)}/3 coins, "
              f"{len(plan.presses)} planned clicks")

    sweeps = ([{"ball_g": g} for g in (0.45, 0.55, 0.7, 0.85)] +
              [{"ufo_g": g} for g in (0.38, 0.45, 0.6, 0.7)] +
              [{"ship_up": u, "ship_down": d} for u, d in
               ((1500, 1300), (1800, 2400), (3200, 2000), (3600, 3400))])
    print("\nPhysics sweep (values the docs leave open):")
    for prm in sweeps:
        e, _ = full_run(lv, plan, world, params=prm)
        status = "pass" if not e.dead else f"FAIL x={e.x:.0f} {e.why}"
        ok_all &= not e.dead
        print(f"  {prm}: {status}")

    # clearance in the flying sections
    print("\nClosest approach to blocks/spikes (units, 30 = one block):")
    mins = {}
    _, ref_trace = full_run(lv, plan, world, record=True)
    s = P.State()
    for tx, ty, tm, _ in ref_trace[::3]:
        s.x, s.y, s.mode = tx, ty, tm
        if s.mode in ("ship", "ufo", "wave"):
            c = clearance(world, s)
            name = section_of(s.x)
            if c < mins.get(name, (1e9,))[0]:
                mins[name] = (c, s.x)
    for name, (c, x) in mins.items():
        print(f"  {name}: {c:.1f} units (at x={x:.0f})")
    best = {}
    for k, v in UFO_CACHE.items():
        if v:
            best[dict(k)["ufo_g"]] = v[1]
    print("  kelp forest (UFO), searched best path, min gap to kelp per gravity: "
          + ", ".join(f"{g}: {c:.0f}u" for g, c in sorted(best.items())))

    print("\nClick timing windows (ms early / late that still pass):")
    rows = timing_windows(lv, plan, world)
    tight = []
    for px, early, late, base_ok in rows:
        ms_e, ms_l = early / P.TPS * 1000, late / P.TPS * 1000
        tight.append((late - early, px, ms_e, ms_l, base_ok))
    by_sec = {}
    for w, px, e, l, okb in tight:
        by_sec.setdefault(section_of(px), []).append((w, px, e, l, okb))
    for name, items in by_sec.items():
        items.sort()
        w, px, e, l, okb = items[0]
        avg = sum(i[0] for i in items) / len(items) / P.TPS * 1000
        print(f"  {name}: {len(items)} clicks, average window {avg:.0f} ms, "
              f"tightest {(l - e):.0f} ms at x={px:.0f} ({e:+.0f}/{l:+.0f} ms)")
        if not okb:
            ok_all = False
    print("\nRESULT:", "ALL CHECKS PASSED" if ok_all else "PROBLEMS FOUND")
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
