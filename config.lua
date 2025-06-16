-- ===================================================================
-- BikeLife Queue System Configuration Example
-- Copy this file to config.lua and modify the values for your server
-- ===================================================================

Config = {}

-- Server Configuration
Config.ServerName = "Your Server Name" -- Change this to your server's name
Config.MaxPlayers = GetConvarInt("sv_maxclients", 32) -- Maximum players allowed on the server

-- Default Player Information
Config.DefaultInfo = {
    playerName = "Unknown", -- Default name when player name isn't available
    defaultRole = "⚙️ Member", -- Default role display for players with no Discord roles
    defaultPriority = 0 -- Default priority points for new players
}

-- Queue Settings
Config.JoinDelay = 1000 -- Delay in milliseconds before processing player connection
Config.QueueUpdateRate = 1000 -- How often to update queue in milliseconds (2 seconds recommended)
Config.TimeoutDuration = 300000 -- Time before timing out inactive players (5 minutes = 300000ms)
Config.DirectConnectionDisplayTime = 3000 -- Time to show info screen for direct connections (3 seconds)

-- Disable FiveM's built-in hardcap resource
Config.DisableHardCap = true -- Set to false if you want to use FiveM's hardcap instead

-- Queue Time Points System
Config.QueueTimePoints = {
    enabled = true, -- Give players priority points for waiting in queue
    pointsPerInterval = 1, -- Points to award per interval
    intervalSeconds = 2 -- Award points every 2 seconds of waiting
}

-- Reconnect Priority System
Config.ReconnectPrio = {
    enabled = true, -- Give priority to players who recently disconnected
    timeLimit = 300, -- Time limit in seconds (5 minutes) to get reconnect priority
    extraPoints = 50 -- Extra priority points for reconnecting players
}

-- Anti-Spam Protection
Config.AntiSpam = {
    enabled = true, -- Prevent rapid connection attempts
    joinDelay = 10000 -- Minimum time between connection attempts in milliseconds (10 seconds)
}

-- Discord Integration
Config.Discord = {
    enabled = true, -- Enable Discord integration features
    invite = "https://discord.gg/your-invite-code", -- Your Discord server invite link
    guildId = "YOUR_DISCORD_SERVER_ID", -- Replace with your Discord server ID (18 digit number)
    botToken = "YOUR_BOT_TOKEN", -- Replace with your Discord bot token
    requireServerMembership = true, -- Require players to be in your Discord server
    requireServerRole = false, -- Require players to have a specific role
    requiredRoles = { -- List of role IDs that allow access (leave empty to allow any role)
        -- "123456789012345678", -- Example role ID
        -- "987654321098765432", -- Another example role ID
    },
    roles = {
        -- Format: ["discord_role_id"] = { name = "Display Name", points = priority_points }
        -- You can find role IDs by enabling Developer Mode in Discord and right-clicking roles
        ["123456789012345678"] = { name = "👑 Owner", points = 1000 },
        ["234567890123456789"] = { name = "⚡ Admin", points = 500 },
        ["345678901234567890"] = { name = "🔧 Moderator", points = 100 },
        ["456789012345678901"] = { name = "⚙️ VIP", points = 50 },
        ["567890123456789012"] = { name = "🎗️ Supporter", points = 25 },
        ["678901234567890123"] = { name = "⚙️ Member", points = 10 }
    }
}

-- Required Player Identifiers
Config.RequiredIdentifiers = {
    "discord" -- Require Discord identifier (you can add "steam", "license", etc.)
}

-- Discord Webhook for Logging
Config.Webhook = {
    enabled = true, -- Enable webhook notifications
    url = "YOUR_DISCORD_WEBHOOK_URL", -- Replace with your Discord webhook URL
    botName = "Queue System", -- Name that appears in Discord
    color = 16753920 -- Embed color (orange = 16753920, blue = 3447003, green = 3066993)
}

-- Avatar Configuration
Config.Avatar = {
    enabled = true, -- Enable avatar display in queue cards
    useDiscordAvatar = true, -- Use Discord avatars when available
    fallbackAvatars = {
        -- Default Discord avatars used as fallbacks
        "https://cdn.discordapp.com/embed/avatars/0.png",
        "https://cdn.discordapp.com/embed/avatars/1.png",
        "https://cdn.discordapp.com/embed/avatars/2.png",
        "https://cdn.discordapp.com/embed/avatars/3.png",
        "https://cdn.discordapp.com/embed/avatars/4.png"
    }
}

-- Debug Mode
Config.Debug = false -- Set to true to enable debug logging (helpful for troubleshooting)

-- ===================================================================
-- SETUP INSTRUCTIONS:
-- 
-- 1. Discord Bot Setup:
--    - Go to https://discord.com/developers/applications
--    - Create a new application and bot
--    - Copy the bot token and paste it in botToken above
--    - Invite the bot to your server with appropriate permissions
--
-- 2. Discord Server ID:
--    - Enable Developer Mode in Discord (User Settings > Advanced)
--    - Right-click your server and "Copy ID"
--    - Paste the ID in guildId above
--
-- 3. Discord Role IDs:
--    - Right-click roles in your Discord server and "Copy ID"
--    - Add them to the roles table above with names and point values
--
-- 4. Webhook Setup:
--    - Create a webhook in your Discord server
--    - Copy the webhook URL and paste it in the webhook url above
--
-- 5. Testing:
--    - Set Debug = true to see detailed logs
--    - Use the testmvc console command to verify components load
--    - Use the queue console command to see current queue status
--
-- ===================================================================