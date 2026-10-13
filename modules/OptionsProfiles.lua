---@diagnostic disable: undefined-global
-- modules/OptionsProfiles.lua - the Profiles page.
--
-- Ace3's profile controls, export and import, switching by itself, presets and
-- snapshots.
--
-- One part of the option table modules/Options.lua puts together; the helpers
-- every part shares are Options.Helpers.
local addonName, privateScope = ...
local addon = privateScope.addon --[[@as AHOS]]
---@class AHOSOptions
local Options = addon.Options
local L = addon.L or {}
local Groups = Options.Groups
local H = Options.Helpers

function Groups.profiles()
    return {
                type = "group",
        name = L.PROFILES or "Profiles Management",
                order = 3,
                args = {
                    aceProfiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db),
                    profileTools = {
                        type = "group",
            name = L.PROFILE_MANAGEMENT or "Profile Tools",
                        order = 2,
                        args = {
                            currentProfile = {
                                type = "description",
                                name = function()
                                    if addon.db and addon.db:GetCurrentProfile() then
                    return (L.CURRENT_PROFILE_LABEL or "|cff4A9EFFCurrent Profile:|r ") .. "|cffffd700" .. addon.db:GetCurrentProfile() .. "|r"
                                    else
                    return (L.CURRENT_PROFILE_LABEL or "|cff4A9EFFCurrent Profile:|r ") .. "|cffffd700" .. (L.UNKNOWN or "Unknown") .. "|r"
                                    end
                                end,
                                order = 0.5,
                                width = "full",
                            },
                            profileInfo = {
                                type = "description",
                                order = 1,
                                name = "Use the Ace3 profile controls above for switching, copying, and resetting profiles.",
                            },
                            exportProfile = {
                                type = "execute",
                name = L.EXPORT_PROFILE or "Export Current Profile",
                desc = L.EXPORT_PROFILE_DESC or "Export the current profile for support or backup.",
                                order = 2,
                                func = function()
                                    if addon.DebugExportTable and addon.db and addon.db.profile then
                                        addon:DebugExportTable(addon.db.profile)
                                    end
                                end,
                            },
                            importProfile = {
                                type = "input",
                name = L.IMPORT_PROFILE_DATA or "Import Profile Data",
                desc = L.IMPORT_PROFILE_DATA_DESC or "Paste a profile export string here to import settings.",
                                order = 3,
                                get = function() return "" end,
                                set = function(_, val) if addon.ImportProfileString then addon:ImportProfileString(val) else addon:Print(L.IMPORT_NOT_IMPLEMENTED or "Import feature not yet implemented.") end end,
                            },
                            autoSwitch = {
                                type = "select",
                                name = L.AUTO_SWITCH_PROFILE or "Switch Profile By Itself",
                                desc = L.AUTO_SWITCH_PROFILE_DESC or "This character switches to a profile of its own for each specialization, or for each talent loadout. A new one starts as a copy of the profile you are on.",
                                order = 4,
                                values = {
                                    off = L.AUTO_SWITCH_OFF or "Never",
                                    spec = L.AUTO_SWITCH_SPEC or "By Specialization",
                                    loadout = L.AUTO_SWITCH_LOADOUT or "By Talent Loadout",
                                },
                                sorting = { "off", "spec", "loadout" },
                                get = function() return addon.db and addon.db.char and addon.db.char.autoSwitch or "off" end,
                                set = function(_, val)
                                    if not (addon.db and addon.db.char) then return end
                                    addon.db.char.autoSwitch = val
                                    if val ~= "off" and addon.Profiles then addon.Profiles:AutoSwitch() end
                                end,
                            },
                            saveAs = {
                                type = "input",
                                name = L.SAVE_AS_PROFILE or "Save as New Profile",
                                desc = L.SAVE_AS_PROFILE_DESC or "Type a name: AHOS makes a profile of that name from this one and switches to it. Same as /ahos profile <name>.",
                                order = 5,
                                get = function() return "" end,
                                set = function(_, val) if addon.Profiles then addon.Profiles:SaveAs(val) end end,
                            },
                        },
                    },
                    presets = {
                        type = "group",
                        inline = true,
                        order = 3,
                        name = L.PRESETS or "Presets",
                        args = (function()
                            local args = {}
                            for index, preset in ipairs(addon.Profiles and addon.Profiles.Presets or {}) do
                                args[preset.key] = {
                                    type = "execute",
                                    name = preset.label,
                                    desc = preset.desc .. "\n\n" .. (L.PRESET_UNDO or "A snapshot is taken first: /ahos rollback undoes it."),
                                    order = index,
                                    func = function() addon.Profiles:ApplyPreset(preset.key) end,
                                }
                            end
                            return args
                        end)(),
                    },
                    snapshots = {
                        type = "group",
                        inline = true,
                        order = 4,
                        name = L.SNAPSHOTS or "Snapshots",
                        args = {
                            intro = {
                                type = "description",
                                order = 0,
                                name = L.SNAPSHOTS_DESC or "Copies of a profile to go back to, kept across characters. One is taken by itself before every preset, import, reset and restore.",
                            },
                            take = {
                                type = "execute",
                                name = L.SNAPSHOT_TAKE or "Take a Snapshot",
                                desc = L.SNAPSHOT_TAKE_DESC or "Keep a copy of this profile as it is now.",
                                order = 1,
                                func = function()
                                    addon.Profiles:TakeSnapshot()
                                    Options.selectedSnapshot = 1
                                end,
                            },
                            pick = {
                                type = "select",
                                name = L.SNAPSHOT or "Snapshot",
                                desc = L.SNAPSHOT_PICK_DESC or "The snapshot to restore or delete. The newest is first.",
                                order = 2,
                                width = "full",
                                values = function()
                                    local values = {}
                                    for index in ipairs(addon.Profiles and addon.Profiles:GetSnapshots() or {}) do
                                        values[index] = addon.Profiles:DescribeSnapshot(index)
                                    end
                                    return values
                                end,
                                disabled = function() return #(addon.Profiles and addon.Profiles:GetSnapshots() or {}) == 0 end,
                                get = function()
                                    local count = #(addon.Profiles and addon.Profiles:GetSnapshots() or {})
                                    if count == 0 then return nil end
                                    local selected = tonumber(Options.selectedSnapshot) or 1
                                    if selected > count then selected = 1 end
                                    return selected
                                end,
                                set = function(_, val) Options.selectedSnapshot = val end,
                            },
                            restore = {
                                type = "execute",
                                name = L.SNAPSHOT_RESTORE or "Restore",
                                desc = L.SNAPSHOT_RESTORE_DESC or "Put this snapshot into the profile you are on. What is there now is kept as a snapshot first.",
                                order = 3,
                                confirm = function() return L.SNAPSHOT_RESTORE_CONFIRM or "Replace this profile's settings with the snapshot?" end,
                                disabled = function() return #(addon.Profiles and addon.Profiles:GetSnapshots() or {}) == 0 end,
                                func = function()
                                    addon.Profiles:RestoreSnapshot(tonumber(Options.selectedSnapshot) or 1)
                                    Options.selectedSnapshot = 1
                                end,
                            },
                            delete = {
                                type = "execute",
                                name = L.SNAPSHOT_DELETE or "Delete",
                                desc = L.SNAPSHOT_DELETE_DESC or "Throw this snapshot away.",
                                order = 4,
                                disabled = function() return #(addon.Profiles and addon.Profiles:GetSnapshots() or {}) == 0 end,
                                func = function()
                                    addon.Profiles:DeleteSnapshot(tonumber(Options.selectedSnapshot) or 1)
                                    Options.selectedSnapshot = 1
                                end,
                            },
                        },
                    },
                },
    }
end
