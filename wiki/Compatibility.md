# Action bar compatibility

AHOS discovers named buttons, reads their binding commands, draws child overlays
and suppresses the native hotkey label while those overlays are active. It does
not replace secure clicks, paging, override bindings or the provider's event code.
Bars that reuse Blizzard buttons keep their Blizzard identity in per-bar settings.

## Sources checked on 13 November 2026

| Provider | Owning source | Integration |
| --- | --- | --- |
| MelloUI | [OwnActionBars / OwnSpecialBars, revision 235d63e](https://github.com/MelloCro/MelloUI/tree/235d63e35b5c37120f2efe57104860e12a3a6a78/Modules) | Eight action bars; commandName before CLICK :Keybind; own pet and stance buttons. |
| EllesmereUI / standalone Action Bars | [Secure button creation and slot map](https://github.com/EllesmereGaming/EllesmereUI/blob/main/EllesmereUIActionBars/EUI_ActionBars_Secure.lua), [bar commands](https://github.com/EllesmereGaming/EllesmereUI/blob/main/EllesmereUIActionBars/EUI_ActionBars_Bars.lua) | EABButton action-slot indices; ten bars including custom pages 2 and 10; commandName. Pet/stance reuse Blizzard buttons. |
| SpartanUI | [9.0.4 native bars](https://github.com/spartanui-wow/SpartanUI/blob/9.0.4/Modules/ActionBars/ActionBar.lua) | SUI_ActionBar buttons, LibActionButton keyBoundTarget and CLICK :Keybind. Pet/stance reuse Blizzard buttons. Older Bartender mode uses the existing BT4 integration. |
| DaylightUI | [Buttons](https://github.com/dayightt/DaylightUI/blob/main/DaylightUI_ActionBars/Buttons.lua), [keys](https://github.com/dayightt/DaylightUI/blob/main/DaylightUI_ActionBars/Keys.lua), [small bars](https://github.com/dayightt/DaylightUI/blob/main/DaylightUI_ActionBars/Small.lua) | DaylightUIBar1-8 buttons and commandName; pet/stance reuse Blizzard buttons. |
| ForeverUI, Solindius | [Published 1.0.19](https://www.curseforge.com/wow/addons/foreverui/files/9584976), Modules/ActionBars/ActionBars.lua and PetBar.lua | ForeverUIbar1-8 buttons; CLICK :LeftButton before fuiGameCommand. Own pet buttons use BONUSACTIONBUTTON and a lower-case hotkey field. Pet action attributes are pet slots, never player action slots. |
| NDui | [Published Classic-0.0.10-forever](https://www.curseforge.com/wow/addons/ndui-classic/files/9509899), Modules/ActionBar/Bars/Bars.lua | Eight NDui_ActionBar bars using LibActionButton and keyBoundTarget. Also discovers older Classic NDui_ActionBarX buttons. Pet/stance reuse Blizzard buttons. The Forever package differs substantially from the repository's master branch. |
| GW2 UI | [Modern action bars](https://github.com/Mortalknight/GW2_UI/blob/master/Games/Modern/Actionbar/actionbars.lua) | Reused Blizzard buttons; provider detection and compatibility note. No invented GW2 button namespace. |
| ElvUI | [ActionBars](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Modules/ActionBars/ActionBars.lua), [PetBar](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Modules/ActionBars/PetBar.lua) | ElvUI_Bar buttons and LibActionButton keyBoundTarget. Pet/stance reuse Blizzard buttons. Enabled by default; an explicit saved forceOverlaysWithElvUI=false is respected. |

## Verification limits

Tools/TestCompatibility.lua runs source-shaped fixtures for every new provider
against each client TOC. It covers discovery after login, bindings while the main
bar shows another action page, rebinding, second bindings, per-bar identity, native
redraw suppression, inherited visibility and disable cleanup. It also exercises
EUI's extra/custom bars, NDui's eighth bar, ForeverUI's pet-slot distinction and
ElvUI's saved opt-out.

These are offline tests, not execution of the complete UI addons. Live validation
is still required for login and /reload (including in combat), form/stance and
vehicle paging, mouse and secure key clicks, fading, skin placement, Edit Mode and
BugSack/taint. ForeverUI's totem spell/utility buttons and cooldown-manager widgets
are outside this action/pet/stance integration.
