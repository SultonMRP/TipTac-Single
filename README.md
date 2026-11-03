# TipTac - Single

TipTac tooltip suite for **WotLK 3.3.5a**. Paragon on player tips is optional.

OptionalDeps: **AethroParagon** and **SingleWoWParagon**. If neither is loaded, TipTac does not add a paragon line.

On SingleWoW, SingleWoWParagon already writes **Paragon ##**, so TipTac does not add a second line.

## Install

Download **TipTac.Single.1.1.zip** from [Releases](https://github.com/SultonMRP/TipTac-Single/releases) and extract it into `Interface\AddOns` so you have:

`Interface\AddOns\TipTac\TipTac.toc`  
`Interface\AddOns\TipTacOptions\TipTacOptions.toc`  
`Interface\AddOns\TipTacTalents\TipTacTalents.toc`  
`Interface\AddOns\TipTacItemRef\TipTacItemRef.toc`

Then `/reload`.

## Use

Hover a player. With SingleWoWParagon you see its paragon line only. With AethroParagon, TipTac can show **Paragon: ##**.

`/tip` → **Special** → **Show Paragon Level** (only if one of those addons is loaded).

## Notes

- Based on TipTac `10.05.01` (`## Interface: 30300`)
- Original addon by Aezay (Earthen Ring EU).
