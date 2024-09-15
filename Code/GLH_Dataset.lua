local _, ns = ... -- Namespace (myaddon, namespace)

ns.ds = {}
local ds = ns.ds

-- List of common PvP zones
local pvpMapIDs = {
    92,    -- Warsong Gulch
    93,    -- Arathi Basin
    1459,  -- Alterac Valley
    112,   -- Eye of the Storm
    169,   -- Strand of the Ancients
    169,   -- Isle of Conquest
    206,   -- Twin Peaks
    275,   -- Battle for Gilneas
    417,   -- Silvershard Mines
    423,   -- Temple of Kotmogu
    519,   -- Deepwind Gorge
    907,   -- Seething Shore
    123,   -- Wintergrasp
    244,   -- Tol Barad
    978,   -- Ashran
    559,   -- Nagrand Arena
    562,   -- Blade's Edge Arena
    617,   -- Dalaran Sewers
    572,   -- Ruins of Lordaeron
    1134,  -- The Tiger's Peak
    1504,  -- Mugambala
    1505,  -- Hook Point
}

function ds:Init()
    self.tblClassesByFile = {}
    self.tblClassesByName = self:GetClassData()

    self.zoneIDs = {}
    self.zoneNames = {}

    self.instanceList = {}
end
function ds:WhatsNew() -- What's new in the current version
    local height = 410 -- Adjust size of what's new window
    local title, msg = '', ''
    title = ns.code:cText('FFFFFF00', "What's new in v"..ns.versionOut.."?")
    msg = [[
            |CFF55D0FF** Please report any bugs or issues in Discord **
                    Discord: https://discord.gg/ZtS6Q2sKRH
                (or click on the icon in the top left corner)|r

    |CFFFFFF00v1.0.0 Notes|r
        - Initial Release
    ]]
end
function ds:GetClassData()
    self.tblClassesByName = {}
    for classID = 1, GetNumClasses() do
        local tblClass = C_CreatureInfo.GetClassInfo(classID)
        if tblClass then
            local classColor = C_ClassColor.GetClassColor(tblClass.classFile):GenerateHexColor()
            local iconPath = "Interface\\Icons\\ClassIcon_" .. tblClass.classFile
            self.tblClassesByName[tblClass.className] = {
                classID = classID,
                classFile = tblClass.classFile,
                className = tblClass.className,
                classColor = classColor,
                iconPath = iconPath
            }
            self.tblClassesByFile[tblClass.classFile] = self.tblClassesByName[tblClass.className]

            --print("|T" .. iconPath .. ":20|t " .. tblClass.className)
        end
    end
end
function ds:GetBuffs()
    return {
        [1] = { id = 6673, name = 'Battle Shout', icon = C_Spell.GetSpellTexture(6673), count = 0, iconFrame = nil, class = {['WARRIOR'] = true} },
        [2] = { id = 1459, name = 'Arcane Intellect', icon = C_Spell.GetSpellTexture(1459), iconFrame = nil, count = 0, class = {['MAGE'] = true} },
        [3] = { id = 21562, name = 'Power Word: Fortitude', icon = C_Spell.GetSpellTexture(21562), iconFrame = nil, count = 0, class = {['PRIEST'] = true} },
        [4] = { id = 1126, name = 'Mark of the Wild', icon = C_Spell.GetSpellTexture(1126), count = 0, iconFrame = nil, class = {['DRUID'] = true} },
        [5] = { id = 381748, name = 'Blessing of the Bronze', icon = C_Spell.GetSpellTexture(381748), count = 0, iconFrame = nil, class = {['EVOKER'] = true} },
        [6] = { id = 80353, name = 'Heroism/Bloodlust', icon = C_Spell.GetSpellTexture(80353), count = 0, iconFrame = nil, class = {
            ['SHAMAN'] = true,
            ['HUNTER'] = true,
            ['MAGE'] = true,
            ['DRUID'] = true,
            ['EVOKER'] = true,
        }}
    }
end
function ds:GetMutliBuffs()
    return {
        [1] = { id = 113746, name = 'Mystic Touch', icon = C_Spell.GetSpellTexture(113746), count = 0, iconFrame = nil, class = {['MONK'] = true } },
        [2] = { id = 1490, name = 'Chaos Brand', icon = C_Spell.GetSpellTexture(1490), count = 0, iconFrame = nil, class = {['DEMONHUNTER'] = true } },
        [3] = { id = 462854, name = 'Skyfury', icon = C_Spell.GetSpellTexture(462854), count = 0, iconFrame = nil, class = {['SHAMAN'] = true } },
        [4] = { id = 465, name = 'Devotion Aura', icon = C_Spell.GetSpellTexture(465), count = 0, iconFrame = nil, class = {['PALADIN'] = true } },
        [5] = { id = 20707, name = 'Soulstone', icon = C_Spell.GetSpellTexture(20707), count = 0, iconFrame = nil, class = {['WARLOCK'] = true } },
        [6] = { id = 20484, name = 'Rebirth', icon = C_Spell.GetSpellTexture(20484), count = 0, iconFrame = nil, class = {
            ['DRUID'] = true,
            ['WARLOCK'] = true,
            ['DEATHKNIGHT'] = true,
            ['PALADIN'] = true, }
        },
    }
end
ds:Init() -- Initialize the dataset