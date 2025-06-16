Lang = {}

Lang.messages = {
    -- Connection Messages
    ["connecting"] = "🏍️ Welcome to " .. Config.ServerName .. "! Checking your credentials...",
    ["steam_required"] = "❌ Steam account required to join " .. Config.ServerName .. "!",
    ["discord_required"] = "❌ Discord account required! Please join the " .. Config.ServerName .. " Discord server.",
    ["notInDiscord"] = "❌ You must be a member of the " .. Config.ServerName .. " Discord server to join!\n🔗 Join us at: " ..
    Config.Discord.invite,
    ["missingRequiredRole"] = "❌ You need a server role to join " .. Config.ServerName .. "! Please contact an admin or check your Discord roles.",
    ["discord_link"] = "📱 Discord: " .. Config.Discord.invite,

    -- Error Messages
    ["connection_error"] = "❌ Connection error. Please try again."
}

-- Utility function to get localized message
function Lang.get(key, ...)
    local message = Lang.messages[key] or key
    if ... then return string.format(message, ...) end
    return message
end
