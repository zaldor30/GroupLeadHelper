local _, ns = ... -- Namespace (myaddon, namespace)

ns.ds = {}
local ds = ns.ds

function ds:Init()
    self.tblClassesByFile = {}
    self.tblClassesByName = self:GetClassData()

    ns.tblIconBuffs = self:GetBuffs()
    ns.tblIconMulti = self:GetMultiBuffs()

    ns.tblBuffsByID = self:SortBuffsByID(ns.tblIconBuffs)
    ns.tblMultiBuffsByID = self:SortBuffsByID(ns.tblIconMulti)
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
        [1] = { id = 6673, name = 'Battle Shout', icon = C_Spell.GetSpellTexture(6673), buffGiverFound = false, count = 0, iconFrame = nil, class = {['WARRIOR'] = true} },
        [2] = { id = 462854, name = 'Skyfury', icon = C_Spell.GetSpellTexture(462854), buffGiverFound = false, count = 0, iconFrame = nil, class = {['SHAMAN'] = true} },
        [3] = { id = 1459, name = 'Arcane Intellect', icon = C_Spell.GetSpellTexture(1459), buffGiverFound = false, iconFrame = nil, count = 0, class = {['MAGE'] = true} },
        [4] = { id = 21562, name = 'Power Word: Fortitude', icon = C_Spell.GetSpellTexture(21562), buffGiverFound = false, iconFrame = nil, count = 0, class = {['PRIEST'] = true} },
        [5] = { id = 1126, name = 'Mark of the Wild', icon = C_Spell.GetSpellTexture(1126), buffGiverFound = false, count = 0, iconFrame = nil, class = {['DRUID'] = true} },
        [6] = { id = 381748, name = 'Blessing of the Bronze', icon = C_Spell.GetSpellTexture(381748), buffGiverFound = false, count = 0, iconFrame = nil, class = {['EVOKER'] = true} },
    }
end
function ds:GetMultiBuffs()
    return {
        [1] = { id = 113746, name = 'Mystic Touch', icon = C_Spell.GetSpellTexture(113746), buffGiverFound = false, countOnly = true, count = 0, iconFrame = nil, class = {['MONK'] = true } },
        [2] = { id = 1490, name = 'Chaos Brand', icon = C_Spell.GetSpellTexture(1490), buffGiverFound = false, countOnly = true, count = 0, iconFrame = nil, class = {['DEMONHUNTER'] = true } },
        [3] = { id = 465, name = 'Devotion Aura', icon = C_Spell.GetSpellTexture(465), buffGiverFound = false, countOnly = false, count = 0, iconFrame = nil, class = {['PALADIN'] = true } },
        [4] = { id = 20707, name = 'Soulstone', icon = C_Spell.GetSpellTexture(20707), buffGiverFound = false, countOnly = true, count = 0, iconFrame = nil, class = {['WARLOCK'] = true } },
        [5] = { id = 20484, name = 'Rebirth', icon = C_Spell.GetSpellTexture(20484), buffGiverFound = false, countOnly = true, count = 0, iconFrame = nil, class = {
            ['DRUID'] = true,
            ['WARLOCK'] = true,
            ['DEATHKNIGHT'] = true,
            ['PALADIN'] = true, }
        },
        [6] = { id = 80353, name = 'Heroism/Bloodlust', icon = C_Spell.GetSpellTexture(80353), buffGiverFound = false, countOnly = true, count = 0, iconFrame = nil, class = {
            ['SHAMAN'] = true,
            ['HUNTER'] = true,
            ['MAGE'] = true,
            ['DRUID'] = true,
            ['EVOKER'] = true,
        }},
    }
end
function ds:SortBuffsByID(tbl)
    if not tbl then return end

    for k, v in pairs(tbl) do
        tbl[v.id] = v
        tbl[v.id].key = k
    end

    return tbl
end
ds:Init()