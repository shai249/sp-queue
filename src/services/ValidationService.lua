ValidationService = {}

-- Check if player has all required identifiers
function ValidationService.hasRequiredIdentifiers(source)
    local identifiers = GetPlayerIdentifiers(source)
    local foundIdentifiers = {}

    for _, identifier in ipairs(identifiers) do
        for _, required in ipairs(Config.RequiredIdentifiers) do
            if string.find(identifier, required .. ":") then
                foundIdentifiers[required] = true
            end
        end
    end

    for _, required in ipairs(Config.RequiredIdentifiers) do
        if not foundIdentifiers[required] then return false, required end
    end

    return true
end

-- Validate player connection
function ValidationService.validatePlayer(source)
    -- Check required identifiers
    local hasRequired, missing =
        ValidationService.hasRequiredIdentifiers(source)
    if not hasRequired then return false, "missing_identifier", missing end

    -- Check Discord server membership if required
    if Config.Discord.enabled and Config.Discord.requireServerMembership then
        if not DiscordService.isPlayerInServer(source) then
            return false, "not_in_discord", nil
        end
    end

    -- Check required Discord server roles
    if Config.Discord.enabled and Config.Discord.requireServerRole then
        if not DiscordService.hasRequiredRole(source) then
            return false, "missing_required_role", nil
        end
    end

    -- Check anti-spam
    local steamId = ValidationService.getSteamId(source)
    local canJoin, delay = ValidationService.checkAntiSpam(steamId)
    if not canJoin then return false, "anti_spam", delay end

    return true, "validated", nil
end

-- Get Steam ID from player
function ValidationService.getSteamId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, "steam:") then return id end
    end
    return nil
end

-- Check anti-spam protection
function ValidationService.checkAntiSpam(steamId)
    if not Config.AntiSpam.enabled then return true end

    -- Use a global anti-spam table since we don't have queue access here
    if not _G.AntiSpamData then _G.AntiSpamData = {} end

    if steamId and _G.AntiSpamData[steamId] then
        local timeSinceLastTry = (os.time() * 1000) - _G.AntiSpamData[steamId]
        if timeSinceLastTry < Config.AntiSpam.joinDelay then
            return false, Config.AntiSpam.joinDelay - timeSinceLastTry
        end
    end

    if steamId then _G.AntiSpamData[steamId] = os.time() * 1000 end

    return true
end

-- Calculate player priority
function ValidationService.calculatePriority(source)
    local points = 0

    -- Discord role points
    local discordPoints = DiscordService.calculatePriority(source)
    points = points + discordPoints -- Reconnect priority points
    local steamId = ValidationService.getSteamId(source)
    if steamId and QueueManager and QueueManager.queue then
        local reconnectPoints = QueueManager.queue:checkReconnectPriority(
                                    steamId)
        points = points + reconnectPoints

        if reconnectPoints > 0 then
            Logger.info(string.format(
                            "Player %s has reconnect priority (+%d points)",
                            GetPlayerName(source), reconnectPoints))
        end
    end

    return points
end

-- Get validation error message
function ValidationService.getErrorMessage(errorType, extra)
    if errorType == "missing_identifier" then
        if extra == "discord" then
            return Lang.get("discord_required") .. "\n" ..
                       Lang.get("discord_link")
        else
            return Lang.get(extra .. "_required")
        end
    elseif errorType == "not_in_discord" then
        return Lang.get("notInDiscord")
    elseif errorType == "missing_required_role" then
        return Lang.get("missingRequiredRole")
    elseif errorType == "anti_spam" then
        return string.format(
                   "⏱️ Please wait %d seconds before reconnecting.",
                   math.ceil(extra / 1000))
    end
    return Lang.get("connection_error")
end
