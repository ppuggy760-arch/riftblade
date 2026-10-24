-- Shared measurements for the lodge (studs). Front of the house faces -Z, backyard is +Z.

local L = {}

L.X0, L.X1 = -36, 36 -- exterior wall centre lines
L.Z0, L.Z1 = -28, 28
L.logD = 1.6
L.extT = 1.6 -- exterior wall thickness (log diameter)
L.intT = 0.8 -- interior partition thickness
L.stoneT = 2.4

L.yBasement = -12 -- basement floor top
L.yGround = 2 -- ground floor top
L.yUpper = 16 -- upper floor top
L.yCeilG = 15 -- ground floor ceiling (underside of upper floor)
L.yCeilU = 29 -- upper ceiling
L.yEave = 30
L.roofSlope = 0.65
L.yRidge = L.yEave + (L.Z1 - 0) * L.roofSlope

-- Interior faces of the exterior walls
L.inX0, L.inX1 = L.X0 + L.extT / 2, L.X1 - L.extT / 2
L.inZ0, L.inZ1 = L.Z0 + L.extT / 2, L.Z1 - L.extT / 2
-- Basement interior faces
L.bX0, L.bX1 = L.X0 + L.stoneT / 2, L.X1 - L.stoneT / 2
L.bZ0, L.bZ1 = L.Z0 + L.stoneT / 2, L.Z1 - L.stoneT / 2

-- Main stair (ground -> upper): x in [-12,-7], climbs toward +Z.
L.mainStair = { x0 = -12, x1 = -7, zStart = -21, tread = 1.5, steps = 13 }
L.mainStair.zTop = L.mainStair.zStart + L.mainStair.tread * L.mainStair.steps

-- Cellar stair (pantry -> basement): z in [-6,-1], descends toward +X.
L.cellarStair = { z0 = -6, z1 = -1, xStart = 15, tread = 1.35, steps = 13 }
L.cellarStair.xEnd = L.cellarStair.xStart + L.cellarStair.tread * L.cellarStair.steps

-- Coal chute: opening in the back basement wall, ramp up to the coal shed.
L.chute = { x0 = 21, x1 = 27, top = -5, rampStart = 30.5, rampEnd = 44.8 }
L.shed = { x0 = 18, x1 = 30, z0 = 34, z1 = 50 }

-- Hidden passage beside the study (lean-to on the east wall).
L.leanTo = { x0 = 36.8, x1 = 42.6, z0 = 10, z1 = 28 }

L.spawn = { x = 0, z = -96 }

return L
