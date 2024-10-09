ns.roster[name] = {
    name,
    rank,
    subParty,
    level,
    class,
    classFile,
    zone,
    isOnline,
    isDead,
}
ns.groupInfo = {
    leader,
    assistants,
    groupType,
    groupOut,
}

ns.tblIconBuffs = self:GetBuffs()
{
        [1] = { id = 6673, name = 'Battle Shout', icon = C_Spell.GetSpellTexture(6673), buffGiverFound = false, count = 0, iconFrame = nil, class = {['WARRIOR'] = true} },
        [2] = { id = 462854, name = 'Skyfury', icon = C_Spell.GetSpellTexture(462854), buffGiverFound = false, count = 0, iconFrame = nil, class = {['SHAMAN'] = true} },
        [3] = { id = 1459, name = 'Arcane Intellect', icon = C_Spell.GetSpellTexture(1459), buffGiverFound = false, iconFrame = nil, count = 0, class = {['MAGE'] = true} },
        [4] = { id = 21562, name = 'Power Word: Fortitude', icon = C_Spell.GetSpellTexture(21562), buffGiverFound = false, iconFrame = nil, count = 0, class = {['PRIEST'] = true} },
        [5] = { id = 1126, name = 'Mark of the Wild', icon = C_Spell.GetSpellTexture(1126), buffGiverFound = false, count = 0, iconFrame = nil, class = {['DRUID'] = true} },
        [6] = { id = 381748, name = 'Blessing of the Bronze', icon = C_Spell.GetSpellTexture(381748), buffGiverFound = false, count = 0, iconFrame = nil, class = {['EVOKER'] = true} },
    }
ns.tblIconMulti = self:GetMultiBuffs()
{
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
        ['EVOKER'] = true,
    }},
}

ns.tblBuffsByID = ns.code:sortTableByField(ns.tblIconBuffs, 'id')
ns.tblBuffsByName = ns.code:sortTableByField(ns.tblIconBuffs, 'name')
ns.tblMultiBuffsByID = ns.code:sortTableByField(ns.tblIconMulti, 'id')
ns.tblMultiBuffsByName = ns.code:sortTableByField(ns.tblIconMulti, 'name')