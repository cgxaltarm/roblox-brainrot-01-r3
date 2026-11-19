# Brainrot Night Market — roblox-brainrot-01 (round 3 rebuild)

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/cgxaltarm/roblox-brainrot-01-r3/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/cgxaltarm/roblox-brainrot-01-r3/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

<sub>Entered on [make.fun](https://make.fun/?ref=witty-badger-10&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>

A 3D Roblox brainrot game set in a real night market plaza. Players buy
absurd Indonesian-food brainrots off a red-carpet conveyor, carry them to
their own kiosk base, and earn money every second — money that piles up
at the base until they walk to the green COLLECT pad to take it. Rarer
characters, mutations, a pity timer, a collection Index, named-character
rebirths and a gear shop give the hunt a long tail, while thieves (other
players, and a roaming thief NPC during Rush Hour) keep every trip home
tense.

Round 3 is a clean-room rebuild of the round-2 game (written from
scratch in a new recording session), with the full Steal a Brainrot
feature set made to actually work end to end: stealing is the heart of
the game, not a side button.

## How to play

1. Spawn at the south gate with $100. The tutorial shows the first three steps.
2. Walk to the conveyor on the north edge: 5 brainrots on show, a new one arrives every 6 seconds. Hold **E** on one to buy it, carry it to one of your base slots, click a pad to place it. It starts earning its $/s immediately — into a pile at your base.
3. Walk to the green COLLECT pad in front of your base to take the pile.
4. Buy rarer characters, fill your slots, then rebirth: each level needs cash plus two NAMED characters (shown with checkmarks in the Rebirth panel) for +50% income, +1 base slot and +10 s lock.
5. Spend cash at the Coins Shop: Slap ($500) knocks a thief down, Speed Coil ($750) makes you 50% faster for 30 s, Trap ($1,000) freezes a thief for 7 s.
6. **Steal:** hold **E** on a brainrot in another player's unlocked base to grab it. You carry it on your back at 80% speed. If anyone touches you — or slaps you with **Q** — you drop it on the ground, and anyone can pick it up. Get it to your own base to keep it. A $1,500 base lock seals your door with a solid laser for 20 seconds (+10 s per rebirth): nobody can walk in, nobody can steal.
7. **Fuse Machine:** feed it 3 brainrots of the same rarity, get 1 random brainrot one tier higher (Common → Rare → Epic → Legendary → Mythic → Brainrot God).
8. **Missions:** five goals in order — buy 1 brainrot ($250), collect $1,000 total ($500), steal 1 brainrot ($1,000), buy 1 gear ($750), rebirth 1× ($5,000). Claim each reward from the MISI panel.
9. Watch the pity board: an Epic is guaranteed every ~3 minutes, a Legendary every ~8 minutes. Every 4 minutes an event fires: Rush Hour (2x conveyor speed + a thief NPC raids a base), Festival (2x income for 45 seconds), or Golden Hour (every spawn is Golden for 60 seconds).
10. Check the Top-5 $/s leaderboard (in the world by the conveyor, and in the HUD) and complete the 30-character Index.

## The cast

30 original Indonesian-food characters across 7 rarities (Common, Rare,
Epic, Legendary, Mythic, Secret, Brainrot God), with Golden (×2 income,
4%), Rainbow (×5, 0.8%) and Diamond (×10, 0.15%) mutations. A mutation
changes the whole model — gold, ice-blue or rainbow-magenta glow — and
the label names it and shows the multiplied $/s.

## What round 3 fixed vs round 2

- **Steal actually works end to end.** In round 2 the attach step wiped
  the server's `Carrying` state, so a bought or stolen brainrot could
  never be placed; round 3 separates the visual weld from the state.
  Dropped brainrots now fall to the ground as loose items anyone can
  grab (they only return home after 60 s unclaimed, or if the carrier
  leaves/dies), instead of teleporting back to the owner.
- **Lock physically blocks entry:** the laser gate spans the whole
  28-stud door and is solid (`CanCollide`) while locked.
- **Mutations can actually roll:** the old roll compared the raw random
  number against each chance in turn, so Rainbow and Diamond were
  unreachable. Chances now accumulate properly.
- **12 physical pads:** rebirth grows slots to 12, and all 12 now exist
  as clickable pads (3 rows of 4), not just 8.
- **Slap only hits thieves:** carrying a fresh conveyor purchase home
  is safe; only stolen goods can be knocked loose.

## What the first play-test fixed (19 Nov 2026, Studio Play)

- **Buying has two paths now.** The hold-E prompt never fired for the
  tester, so clicking a conveyor model buys it too (same server
  check), the prompt bubble is lifted above the conveyor cards
  (`UIOffset`), its range is 14 studs, and the set only rolls every
  10 s (6 s in Rush Hour) so a hold is never cut short.
- **Buttons no longer hide under the cards.** The five small buttons
  (GEAR / INDEX / BUFF / MISI / FUSE) moved to one row above the big
  buttons, vertically clear of the conveyor cards at any screen
  width; the cards are explicitly non-interactive and only rebuild
  when their contents change (they used to flicker every second).
- **World labels de-cluttered.** Collect pads moved to the outer
  corners of each base (the old inner pads sat 8 studs apart, so
  both "COLLECT $0" labels printed as one "COLLICOLLECT $0"); owner
  boards show the name only; the neon sign, fuse sign, gear sign and
  leaderboard board all shrank, and the leaderboard board + Fuse
  Machine moved off the centre of the spawn view.
- **Wayfinding.** Neon chevrons on the ground point from spawn to the
  conveyor, and the lamp that blocked the middle of the walkway moved
  aside. COLLECT now toasts even when the pile is $0, so the click
  visibly does something.

## What the declutter pass changed (19 Nov 2026, Wira: "sangat padat dan berantakan")

- **Main screen keeps only the essentials:** money (cash / $/s / pile),
  one timer line (next event + Legendary + Epic in one row), one
  small mission line, a compact collapsible base panel (filled slots
  + one empty slot only), and three buttons bottom-right: MENU, LOCK
  BASE, COLLECT. The middle of the screen is empty - the game itself
  is visible.
- **One MENU panel, seven tabs:** GEAR, BUFF, INDEX, MISI, FUSE,
  REBIRTH, TOP 5. The Top-5 left the main screen entirely (it now
  lives in MENU > TOP 5) and the Top-5 world board is gone.
- **World labels removed:** the Top-5 board, the "FUSE MACHINE" sign
  label and the "COLLECT $0" pad labels are gone (they duplicated the
  HUD). What stays in the world: the neon market sign, the base owner
  boards (name only), the Coins Shop sign, the conveyor models' price
  labels, and the chevrons.
- **Smaller conveyor cards:** name + gold price, $/s in small print,
  rarity as the border colour only.

## What the second play-test fixed (19 Nov 2026)

- **Spawn is no longer blind.** The server faces every spawn at the
  conveyor (`PivotTo` on `CharacterAdded`) and the client snaps the
  camera behind the player looking north at the conveyor + chevrons
  for the first second. A new player sees the market, not the sky.
- **A new player can always buy something.** The conveyor now
  guarantees at least one slot at or under the $100 starting cash
  (`Conveyor.EnsureCheapSlot`, replacing the oldest slot so a pity
  Epic/Legendary is never eaten). Verified by running the real
  conveyor code under the Luau VM: 200 fills + 1.000 rolls all keep
  the guarantee, 100 pity-Legendary rolls all survive it.
- **Smaller world labels.** Gear sign now just "GEAR", owner boards
  show the direction only ("NW") until claimed. Neon sign kept.
- **Brighter night.** Lighting Brightness 1→2, ambient lifted, all
  lamp PointLights Range 22→30 / Brightness 2→3, plus four new path
  lamps flanking the spawn-to-conveyor walkway.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/shared/` holds the catalogue (`BrainrotData`, with each character's prop parts, missions and the fuse ladder), tuning (`Config`) and money formatting (`Format`).
- `src/server/` holds the server systems: economy (money, missions, fuse, collect pile), conveyor and pity timer, character models, the world builder (kiosks, Fuse Machine, leaderboard board), bases, stealing and the thief NPC, events, gear and saving. The server owns all state.
- `src/client/` holds the HUD (money, one timer line, one mission line, collapsible base panel, MENU/LOCK/COLLECT buttons), shop (small conveyor cards + the single MENU panel with its seven tabs) and effects (sounds). The client only renders.
- `screenshots/` holds 3–4 captures of the game running in Roblox Studio; the first by name is the game's thumbnail on Roblox.
- `PLAY.json` names the published public place on Roblox.

## Build it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Play it on Roblox: see `PLAY.json` for the public place link.
