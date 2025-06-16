DiscordService = {}

-- Get player Discord information
function DiscordService.getPlayerInfo(source)
    if not Config.Discord.enabled then
        return {inServer = false, roles = {}, avatar = nil}
    end

    local discordId = DiscordService.getDiscordId(source)
    if not discordId then return {inServer = false, roles = {}, avatar = nil} end

    -- Make HTTP requests for member and user info
    local memberInfo = DiscordService.getMemberInfo(discordId)
    local userInfo = DiscordService.getUserInfo(discordId)

    return {
        inServer = memberInfo.inServer,
        roles = memberInfo.roles,
        avatar = userInfo.avatar
    }
end

-- Get Discord ID from player identifiers
function DiscordService.getDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    return nil
end

-- Get Discord guild member information
function DiscordService.getMemberInfo(discordId)
    local memberEndpoint = string.format(
                               "https://discord.com/api/guilds/%s/members/%s",
                               Config.Discord.guildId, discordId)

    local headers = {
        ["Authorization"] = "Bot " .. Config.Discord.botToken,
        ["Content-Type"] = "application/json"
    }

    local result = {inServer = false, roles = {}}
    local success = false

    PerformHttpRequest(memberEndpoint, function(statusCode, response)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.roles then
                result.roles = data.roles
                result.inServer = true
            end
        elseif statusCode == 404 then
            result.inServer = false
        end
        success = true
    end, "GET", "", headers)

    -- Wait for response with timeout
    local timeout = 0
    while not success and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    return result
end

-- Get Discord user information
function DiscordService.getUserInfo(discordId)
    local userEndpoint = string.format("https://discord.com/api/users/%s",
                                       discordId)

    local headers = {
        ["Authorization"] = "Bot " .. Config.Discord.botToken,
        ["Content-Type"] = "application/json"
    }

    local result = {avatar = nil}
    local success = false

    PerformHttpRequest(userEndpoint, function(statusCode, response)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.avatar then
                local ext = string.find(data.avatar, "a_") == 1 and "gif" or
                                "png"
                result.avatar = string.format(
                                    "https://cdn.discordapp.com/avatars/%s/%s.%s",
                                    discordId, data.avatar, ext)
            end
        end
        success = true
    end, "GET", "", headers)

    -- Wait for response with timeout
    local timeout = 0
    while not success and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    return result
end

-- Calculate priority based on Discord roles
function DiscordService.calculatePriority(source)
    local points = 0
    local discordInfo = DiscordService.getPlayerInfo(source)

    for _, roleId in ipairs(discordInfo.roles) do
        local roleData = Config.Discord.roles[roleId]
        if roleData then points = points + roleData.points end
    end

    return points
end

-- Check if player has required server roles
function DiscordService.hasRequiredRole(source)
    if not Config.Discord.enabled or not Config.Discord.requireServerRole then
        return true
    end

    local discordInfo = DiscordService.getPlayerInfo(source)

    -- If player is not in server, they can't have roles
    if not discordInfo.inServer then return false end

    -- If no specific roles are required, just check if they have any role in the configured roles
    if #Config.Discord.requiredRoles == 0 then
        -- Check if player has any of the configured roles (any role gives access)
        for _, roleId in ipairs(discordInfo.roles) do
            if Config.Discord.roles[roleId] then return true end
        end
        return false
    else
        -- Check if player has any of the specifically required roles
        for _, requiredRoleId in ipairs(Config.Discord.requiredRoles) do
            for _, playerRoleId in ipairs(discordInfo.roles) do
                if playerRoleId == requiredRoleId then
                    return true
                end
            end
        end
        return false
    end
end

-- Check if player is in Discord server
function DiscordService.isPlayerInServer(source)
    if not Config.Discord.enabled or not Config.Discord.requireServerMembership then
        return true
    end

    local discordInfo = DiscordService.getPlayerInfo(source)
    return discordInfo.inServer
end

-- Get player avatar from Discord
function DiscordService.getPlayerAvatar(source)
    if not Config.Avatar.enabled then 
        return Config.Avatar.fallbackAvatars[1] 
    end

    if not Config.Avatar.useDiscordAvatar or not Config.Discord.enabled then
        return DiscordService.getFallbackAvatar(source)
    end

    local discordInfo = DiscordService.getPlayerInfo(source)
    if discordInfo.avatar then return discordInfo.avatar end

    return DiscordService.getFallbackAvatar(source)
end

-- Get fallback avatar
function DiscordService.getFallbackAvatar(source)
    local fallbacks = Config.Avatar.fallbackAvatars
    local discordId = DiscordService.getDiscordId(source)

    if discordId then
        -- Use consistent fallback based on Discord ID
        local hash = 0
        for i = 1, #discordId do hash = hash + string.byte(discordId, i) end
        return fallbacks[(hash % #fallbacks) + 1]
    end

    return fallbacks[1] -- Use first fallback avatar as default
end

-- Legacy function for backwards compatibility
function DiscordService.getPlayerRoles(source)
    local discordInfo = DiscordService.getPlayerInfo(source)
    return discordInfo.roles
end
