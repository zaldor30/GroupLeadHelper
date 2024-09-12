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

-- Function to create a fade-out animation group
local function CreateFadeOutAnimation(fontString, onComplete)
    -- Create the animation group for the fade-out
    local fadeOutGroup = fontString:CreateAnimationGroup()

    -- Define the fade-out alpha animation
    local fadeOut = fadeOutGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)  -- Start fully visible
    fadeOut:SetToAlpha(0)    -- End fully invisible
    fadeOut:SetDuration(1.5) -- Duration for fade-out
    fadeOut:SetSmoothing("IN_OUT") -- Smooth transition

    -- Callback when fade-out completes
    fadeOutGroup:SetScript("OnFinished", function()
        if onComplete then
            onComplete()  -- Trigger the onComplete function to switch the text
        end
    end)

    return fadeOutGroup
end

-- Create an AnimationGroup for fade-out
local function CreateFadeOutAnimation(fontString, onComplete)
    -- Create the animation group for the fade-out
    local fadeOutGroup = fontString:CreateAnimationGroup()

    -- Define the fade-out alpha animation
    local fadeOut = fadeOutGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)  -- Start fully visible
    fadeOut:SetToAlpha(0)    -- End fully invisible
    fadeOut:SetDuration(1.5) -- Time to fade out
    fadeOut:SetSmoothing("IN_OUT") -- Smooth transition

    -- When fade-out finishes, trigger the onComplete function
    fadeOutGroup:SetScript("OnFinished", function()
        if onComplete then
            onComplete()  -- Switch the text after fade-out
        end
    end)

    return fadeOutGroup
end

-- Create an AnimationGroup for fade-in
local function CreateFadeInAnimation(fontString)
    -- Create the animation group for the fade-in
    local fadeInGroup = fontString:CreateAnimationGroup()

    -- Define the fade-in alpha animation
    local fadeIn = fadeInGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)  -- Start fully invisible
    fadeIn:SetToAlpha(1)    -- Fade to fully visible
    fadeIn:SetDuration(1.5) -- Time to fade in
    fadeIn:SetSmoothing("IN_OUT") -- Smooth transition

    return fadeInGroup
end

-- Custom SetText with fade transition
function frames:FadeSetText(fontString, newText)
    -- Create fade-out group if it doesn't exist
    if not fontString.fadeOutGroup then
        fontString.fadeOutGroup = CreateFadeOutAnimation(fontString, function()
            -- After fade-out, change the text, but keep it invisible
            fontString:SetText(newText)
            fontString:SetAlpha(0)  -- Ensure the new text is invisible
            fontString.fadeInGroup:Play()  -- Start the fade-in animation
        end)
    end

    -- Create fade-in group if it doesn't exist
    if not fontString.fadeInGroup then
        fontString.fadeInGroup = CreateFadeInAnimation(fontString)
    end

    -- Stop any running animations
    fontString.fadeOutGroup:Stop()
    fontString.fadeInGroup:Stop()

    -- Play the fade-out animation first
    fontString.fadeOutGroup:Play()
end

-- Usage Example:
-- Assuming "MyFontString" is a valid FontString you want to fade in/out
--FadeSetText(MyFontString, "New Text Here")
