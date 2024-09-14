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
            local classColor = C_ClassColor.GetClassColor('MAGE'):GenerateHexColor()
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
ds:Init() -- Initialize the dataset