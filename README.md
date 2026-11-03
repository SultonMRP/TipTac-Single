# TipTac - Single

TipTac tooltip suite for **WotLK 3.3.5a** with a **Paragon** line for **SingleWoW**.

Uses the server `SWParagonOf` stream (same as SingleWoWParagon and Shadow Unit Frames - Single). Your own tip shows `Paragon: 0` until the server sends a number.

## Install

Download **TipTac.Single.1.0.zip** from [Releases](https://github.com/SultonMRP/TipTac-Single/releases) and extract it into `Interface\AddOns` so you have:

`Interface\AddOns\TipTac\TipTac.toc`  
`Interface\AddOns\TipTacOptions\TipTacOptions.toc`  
`Interface\AddOns\TipTacTalents\TipTacTalents.toc`  
`Interface\AddOns\TipTacItemRef\TipTacItemRef.toc`

Then `/reload`.

## Use

Hover a player. The tip shows **Paragon: ##** when a number is known.

`/tip` → **Special** → **Show Paragon Level**.

## Notes

- Based on TipTac `10.05.01` (`## Interface: 30300`)
- Other players stay blank until the server has sent their name.
- Original addon by Aezay (Earthen Ring EU).
