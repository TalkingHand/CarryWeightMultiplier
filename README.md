# Carry Weight Multiplier

Project Zomboid Build 42 mod. Multiplies the weight items count for in carry and capacity checks, fluids and picked-up furniture included, so characters, bags, vehicles and the floor hold more. The sandbox option "Carried weight multiplier" sets it: 0.1 (default) counts a tenth, 0 counts nothing, 1 is vanilla.

Item weights themselves do not change. Stamina, action times, fuel, foraging and fish stay vanilla. The menus for taking down curtains and light bulbs use the counted weight too.

Side effects:

- Strength rises less often from walking loaded, because that needs a load over half the carry limit.
- Vehicles gain less mass from cargo.
- Weight numbers in the UI show the counted weight, except for animals.
- Other mods that read these weights see the counted weight too.

## Install

1. Subscribe to [ZombieBuddy](https://github.com/zed-0xff/ZombieBuddy) and [this mod](https://steamcommunity.com/sharedfiles/filedetails/?id=3832023168), and enable both in the mod list.
2. Steam → Project Zomboid → Properties → Launch options: `-agentlib:zbNative --` (ZombieBuddy's Java loader; without it the mod does not load).
3. On the first start ZombieBuddy asks once to approve `CarryWeightMultiplier.jar`.
4. Check `Zomboid/console.txt` for `[CarryWeightMultiplier] loaded`.

Manual install: copy `Contents/mods/CarryWeightMultiplier` into `%USERPROFILE%\Zomboid\mods\`.

## Compatibility

Single-player tested. Multiplayer is not tested: the server and every client would need ZombieBuddy and the mod. Works when added to an existing save, which then uses the default 0.1. The mod changes no item data, so weights count as vanilla again once it is removed.

## Test

```bash
bash ../PZTestHarness/pzt run
```

Not covered by the test: real mouse use, the sandbox settings screen, multi-tile furniture, saving and reloading, multiplayer. The curtain and light bulb options are called directly rather than from a real right-click menu.

## License

All rights reserved. No license is granted for redistribution or modified versions.

## Support

If this mod helps you, you can support it via [Ko-fi](https://ko-fi.com/talkinghands2285) or [PayPal](https://www.paypal.com/paypalme/TalkingHands619/3). It's optional; every feature stays free.
