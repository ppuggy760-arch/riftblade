# Marrow Lodge

A Roblox place set in a big two-storey log cabin with a cellar, a backyard and the woods around it.
It's always golden hour. You hold the key, and everyone else is just visiting.

**Open it:** download `MarrowLodge.rbxl`, then in Roblox Studio go to **File → Open from File…** and press **Play**.
To put it online, use **File → Publish to Roblox**. Whoever publishes it gets the key.

> This page is for you, the owner. Nothing below appears inside the game. In the game, the story only comes
> through pages, letters and drawings left around the lodge.

---

## You (the key holder)

- The account that owns the place gets the **Old Key** every time they spawn. In a group game, that's
  the group's owner. They start upstairs in the loft, looking down the stairs. Everyone else arrives at
  the front gate.
- For a Studio test with no publish, the first player to join gets the key. In **Test → Clients and
  Servers**, Player1 is the key holder.
- To let another account hold the Old Key too, add its user id to `KeeperUserIds` in
  `ReplicatedStorage.LodgeConfig`.
- The Old Key can't be dropped or given away.

## Doors

- Every door swings on a **hinge on its left side**, as seen when you walk in. Walk into a door and it
  swings away from you. It closes again a few seconds after everyone has moved away.
- Hold a key, walk up to a door and press **E** to **Lock** or **Unlock** it. A door stays the way you
  left it. If you forget to lock it again, it stays unlocked.
- Pushing on a locked door makes it rattle.
- The **front door** and **back door** have heavy deadbolts and only a key opens them.

Lockable doors: front door, back door, bathroom, cellar stairs, study, all five upstairs rooms, and the
key room in the cellar.

## Giving someone a key

1. Go down the cellar stairs to the **key room**. It starts locked.
2. Unlock it with your key, walk in, and press **E** on the key board on the back wall (**Take Key**).
   You get a copy called **Key**.
3. Walk up to a player and press **G** (**Give Key**). You can also drop it with Backspace and let them
   pick it up.

Anyone standing in the key room can take a copy, not only you. If you leave the key room unlocked,
whoever finds it can take a key.

## How the others get out

When the doors are locked, there are three ways out. All of them are hinted at by the pages people find:

| Way out | What it takes |
| --- | --- |
| **Hairpins** | One is hidden in every room with a lock: bathroom sink, study desk, guest room dresser, sewing table, master bedroom vanity, June's dresser, a crate in the attic room, and the cellar workbench. While holding one, a locked *interior* door shows **Pick Lock (F)**. It opens the door and uses up the pin. Pins come back after a while. Front, back and key room doors can't be picked. |
| **The green book** | The study's middle bookcase swings into a hidden narrow passage when you pull the green book (several books can be pulled, only one does anything). The passage runs along the outside wall to a small door into the backyard. A ring on the back of the bookcase opens it from inside. |
| **The coal chute** | Behind the furnace in the cellar, the old coal chute is boarded shut. The **Pry Bar** is in an open trunk in the attic room upstairs. With it, **Pry** the boards off and climb the chute up into the coal shed in the yard. The boards go back up after about 2½ minutes. There's only one pry bar, and it comes back only once nobody has it. |

Every locked room has a hairpin inside it, and the whole house has two ways out besides the doors. So
someone locked in can always get out eventually, as long as they look around. You can make it harder by
picking up the pry bar or the hairpins first.

## The story (spoilers)

Ansel Marrow, a locksmith, built the lodge in 1931 for his wife Odette and their daughter June. He made
one key for every door. In October 1934, June went out to watch the sun set behind the pines at twenty to
seven and never came back in. Ansel stopped every clock in the house at 6:40 and swore the evening
wouldn't end until she came home. It never has.

Guests kept arriving for the next fifty years: the Hallorans in 1951, R. Pike in 1977, and Dana and Theo
Okafor in 1989. Their pages, their trunk, their old station wagon by the fence and a bedroll in the cellar
are still there. June's drawings show "the key man", and Ansel's last page is hidden in the passage
behind the bookcase.

Pages to find:
- The guest register by the front door
- Odette's letter on the kitchen table
- A recipe card on the kitchen counter
- Ansel's journal on the study desk
- His second page beside the reading chair
- Odette's unsent note on the master bedroom dresser
- June's page pinned in her room
- Theo's note on the guest room nightstand
- Dana's note on the cellar wall behind the furnace
- The copy ledger in the key room
- The luggage tag on the Okafors' trunk in the attic room
- Ansel's last page in the hidden passage
- A note pinned to the swing tree in the backyard

## Look and feel

- Lighting uses **Future** quality, with a low golden sun and warm haze from `Atmosphere`. Bloom, a slight
  `BlurEffect` (size 2.5), soft depth of field and a warm colour grade sit on top. Settings are in
  `Lighting`.
- About 85 warm lights: lamps, candles, chandeliers, the fireplace, the wood stove, the furnace, string
  lights over the yard, and lanterns along the paths. Candles and fires flicker, and now and then a bulb
  dips.
- When the server starts, the flat grass, paths and pond turn into real **Terrain**, with swaying grass
  and water. To keep the plain parts instead, set `TerrainGround = false` in `LodgeConfig`.

## Sounds and the Toolbox

Everything is built from parts and scripts, with no free models, so nothing hidden comes along with them.
Roblox only lets a place play sounds that are public or that you uploaded, so the sound slots in
`LodgeConfig.Sounds` start empty. The only exception is a built-in click used for locks.

To add sound, open the **Toolbox → Audio** tab and find one you like (creaky door, keys jingling, page
turn, crackling fire, night ambience). Right-click it, choose **Copy Asset ID**, and paste it as
`"rbxassetid://123456"` into the matching slot. Any Toolbox models you drop into the map work alongside
everything else.

## Settings (`ReplicatedStorage.LodgeConfig`)

| Setting | Default | Meaning |
| --- | --- | --- |
| `KeeperUserIds` | `{}` | Extra user ids that get the Old Key |
| `StudioFirstPlayerIsKeeper` | `true` | In Studio tests, the first player gets the key |
| `KeeperStartsInside` | `true` | The key holder spawns in the upstairs loft |
| `TerrainGround` | `true` | Turn the ground parts into terrain at start |
| `ChuteBoardsReset` | `150` | Seconds before the chute is boarded up again |
| `DoorCloseDelay` | `3` | Seconds a door stays open after people walk away |
| `Sounds` | mostly empty | Sound ids, see above |

## Rebuilding from source

The place file is generated by code, so the world can be changed and rebuilt:

```
cargo install lune          # once
cd marrow-lodge
lune run build/bake.luau    # writes MarrowLodge.rbxl
```

- `build/world/` holds the map: `Cabin` (walls, floors, roof, porch, doors, windows), `Rooms` (furniture
  and pages), `Basement` (cellar, key room, chute, coal shed), `Yard` (grounds, woods) and `Story` (all
  the page text).
- `src/` holds the game scripts that are copied into the place:
  - `server/`: doors, keys and items, the two secret ways out, and terrain.
  - `client/`: who sees which prompt, the page reader, and the flicker.
