local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.frames = {}
local frames = ns.frames

frames.BUTTON_LOCKED = ns.ICON_PATH..'GLH_Locked'
frames.BUTTON_UNLOCKED = ns.ICON_PATH..'GLH_Unlocked'

-- Backdrop Templates
frames.DEFAULT_BORDER = 'Interface\\Tooltips\\UI-Tooltip-Border'
frames.BLANK_BACKGROUND = 'Interface\\Buttons\\WHITE8x8'
frames.DIALOGUE_BACKGROUND = 'Interface\\DialogFrame\\UI-DialogBox-Background'
function frames.BackdropTemplate(bgImage, edgeImage, tile, tileSize, edgeSize, insets)
	tile = tile == 'NO_TILE' and false or true

	return {
		bgFile = bgImage or frames.DIALOGUE_BACKGROUND,
		edgeFile = edgeImage or frames.DEFAULT_BORDER,
		tile = true,
		tileSize = tileSize or 16,
		edgeSize = edgeSize or 16,
		insets = insets or { left = 3, right = 3, top = 3, bottom = 3 }
	}
end

-- Frame Stratas
frames.BACKGROUND_STRATA = 'BACKGROUND'
frames.LOW_STRATA = 'LOW'
frames.MEDIUM_STRATA = 'MEDIUM'
frames.HIGH_STRATA = 'HIGH'
frames.DIALOG_STRATA = 'DIALOG'
frames.TOOLTIP_STRATA = 'TOOLTIP'
frames.DEFAULT_STRATA = frames.BACKGROUND_STRATA

--* Frame Pooling
local FramePool = {} -- Pool of frames to reuse
-- Function to reset a frame and all of its children
function frames:ResetFrame(frame)
    -- Clear all children
    local numChildren = select("#", frame:GetChildren())
    for i = 1, numChildren do
        local child = select(i, frame:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end

    -- Clear any scripts
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnEvent", nil)

    -- Reset position
    frame:ClearAllPoints()

    -- Hide the frame
    frame:Hide()
end
-- Function to get a frame from the pool or create a new one
function frames:CreateFrame(name, parent, useBackdrop, backdropTemplate, frameType)
    -- Check if a frame is available in the pool
    local frame = table.remove(FramePool)

    if not frame then
        -- No available frames, create a new one
        frame = CreateFrame(frameType or "Frame", name, parent, useBackdrop and "BackdropTemplate" or nil, frameType)

        -- If using the BackdropTemplate, set up the backdrop
        if useBackdrop then
            frame:SetBackdrop(backdropTemplate or frames.BackdropTemplate())
            frame:SetBackdropColor(0, 0, 0, 0.5)  -- Example: semi-transparent black background
        end
    else
        -- Reuse frame, reset its properties
        frame:SetParent(parent or UIParent)
        frame:SetName(name)
        self:ResetFrame(frame)

        -- Handle BackdropTemplate logic
        if useBackdrop then
            if not frame.SetBackdrop then
                Mixin(frame, BackdropTemplateMixin)  -- Ensure the backdrop is available
            end
            frame:SetBackdrop(backdropTemplate or frames.BACKDROP_TEMPLATE)
            frame:SetBackdropColor(0, 0, 0, 0.5)
        else
            -- Clear the backdrop if not required
            frame:SetBackdrop(nil)
        end
    end

    frame:Show()
    return frame
end
-- Function to return a frame to the pool
function frames:release(frame)
    self:ResetFrame(frame)
    table.insert(FramePool, frame)
end

local tblFade = {}
function frames:CreateAnimationAtlas(fontString, newData) frames:CreateAnimation(fontString, newData, 'ATLAS_IMAGE') end
function frames:CreateAnimationTexture(fontString, newData) frames:CreateAnimation(fontString, newData, 'IMAGE') end
function frames:CreateFadeAnimation(fontString, newText) frames:CreateAnimation(fontString, newText, 'TEXT') end
function frames:CreateAnimation(fontString, newData, type)
    -- Check if fadeOutGroup exists; if not, create it
    local fadeOutGroup = tblFade[fontString] and tblFade[fontString].fadeOutGroup
    if not fadeOutGroup then
        fadeOutGroup = fontString:CreateAnimationGroup()
        local fadeOut = fadeOutGroup:CreateAnimation('Alpha')
        fadeOut:SetFromAlpha(1)  -- Start fully visible
        fadeOut:SetToAlpha(0)    -- End fully invisible
        fadeOut:SetDuration(0.5)
        fadeOut:SetSmoothing("OUT")
        tblFade[fontString] = { fadeOutGroup = fadeOutGroup }
    end

    -- Check if fadeInGroup exists; if not, create it
    local fadeInGroup = tblFade[fontString] and tblFade[fontString].fadeInGroup
    if not fadeInGroup then
        fadeInGroup = fontString:CreateAnimationGroup()
        local fadeIn = fadeInGroup:CreateAnimation('Alpha')
        fadeIn:SetFromAlpha(0)  -- Start fully invisible
        fadeIn:SetToAlpha(1)    -- Fade to fully visible
        fadeIn:SetDuration(0.5)
        fadeIn:SetSmoothing("IN")
        tblFade[fontString] = { fadeInGroup = fadeInGroup }
    end

    -- When the fade-out finishes, change the text and start fade-in
    fadeOutGroup:SetScript('OnFinished', function()
        if type == 'TEXT' then fontString:SetText(newData)
        elseif type == 'IMAGE' then fontString:SetTexture(newData)
        elseif type == 'ATLAS_IMAGE' then fontString:SetAtlas(newData) end
        fadeOutGroup:Stop()
        fadeInGroup:Play()           -- Start the fade-in animation
    end)

    -- Immediately trigger fade-out and fade-in for the new text
    fadeOutGroup:Play()
end