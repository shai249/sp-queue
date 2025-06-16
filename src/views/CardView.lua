CardView = {}

-- Card template cache
local cardTemplate = nil

-- Load card template from file
function CardView.loadTemplate()
    local resourceName = GetCurrentResourceName()
    local templateData = LoadResourceFile(resourceName, 'presentCard.json')

    if templateData then
        local decoded = json.decode(templateData)
        -- Handle array format - take the first element
        if type(decoded) == "table" and #decoded > 0 then
            cardTemplate = decoded[1]
        else
            cardTemplate = decoded
        end
        Logger.info("Present card template loaded successfully")
        return true
    else
        Logger.error("Failed to load presentCard.json template")
        cardTemplate = nil
        return false
    end
end

-- Get role display text based on priority using Discord roles configuration
local function getRoleText(priority)
    local bestRole = nil
    local bestPoints = -1

    -- Find the highest priority role that matches or is below the player's priority
    for roleId, roleData in pairs(Config.Discord.roles) do
        if roleData.points <= priority and roleData.points > bestPoints then
            bestRole = roleData
            bestPoints = roleData.points
        end
    end    -- Return the role name if found, otherwise default
    if bestRole then
        return bestRole.name
    else
        return Config.DefaultInfo.defaultRole -- Default for players with no matching roles
    end
end

-- Calculate estimated wait time
local function calculateWaitTime(position)
    if position <= 1 then return "< 1 min" end

    local estimatedWait = position * 2 -- Rough estimate: 2 minutes per position
    if estimatedWait < 60 then
        return string.format("%d min", estimatedWait)
    else
        return string.format("%d:%02d", math.floor(estimatedWait / 60),
                             estimatedWait % 60)
    end
end

-- Update present card for a player
function CardView.updateCard(source, deferrals, position, queueSize, priority,
                             isDirect)
    if not cardTemplate then
        deferrals.update("🏍️ Loading " .. Config.ServerName .. " queue...")
        return false
    end    local playerName = GetPlayerName(source) or Config.DefaultInfo.playerName
    local playerAvatar = DiscordService.getPlayerAvatar(source) or
                             Config.Avatar.fallbackAvatars[1]
    local playersOnline = #GetPlayers()

    -- Calculate position and wait time display
    local queuePositionText = ""
    local waitText = ""

    if isDirect then
        queuePositionText = "🟢 Connecting..."
        waitText = "No wait time"
    else
        queuePositionText = string.format("%d / %d", position, queueSize)
        waitText = calculateWaitTime(position)
    end

    -- Get role info based on priority
    local roleInfo = getRoleText(priority)

    -- Clone the template and replace variables
    local card = json.encode(cardTemplate)
    card = string.gsub(card, "{{playerName}}", playerName)
    card = string.gsub(card, "{{playerAvatar}}", playerAvatar)
    card = string.gsub(card, "{{queuePosition}}", queuePositionText)
    card = string.gsub(card, "{{priorityPoints}}", tostring(priority))
    card = string.gsub(card, "{{roleInfo}}", roleInfo)
    card = string.gsub(card, "{{waitTime}}", waitText)
    card = string.gsub(card, "{{playersOnline}}", tostring(playersOnline))
    card = string.gsub(card, "{{maxPlayers}}", tostring(Config.MaxPlayers))

    -- Present the card
    deferrals.presentCard(card, function(data, rawData)
        -- Handle card interactions if needed
        Logger.debug(string.format("Card interaction from %s: %s", playerName,
                                   json.encode(data)))
    end)

    return true
end

-- Show simple loading message
function CardView.showLoading(deferrals, message)
    message = message or Lang.get("connecting")
    deferrals.update(message)
end

-- Show error message
function CardView.showError(deferrals, errorMessage) deferrals.done(errorMessage) end

-- Show queue information without card
function CardView.showQueueInfo(deferrals, position, queueSize, priority)
    local message = string.format("🚦 You're in the %s queue!\n" ..
                                      "Position: %d/%d\n" ..
                                      "Priority Points: %d\n" ..
                                      "Estimated wait: %s", Config.ServerName, position, queueSize,
                                  priority, calculateWaitTime(position))
    deferrals.update(message)
end

-- Get template status
function CardView.hasTemplate() return cardTemplate ~= nil end

-- Reload template
function CardView.reloadTemplate() return CardView.loadTemplate() end
