WebhookService = {}

-- Send webhook notification
function WebhookService.send(message, title, color)
    if not Config.Webhook.enabled or not Config.Webhook.url then return end

    local payload = {
        username = Config.Webhook.botName,
        embeds = {
            {
                title = title or Config.ServerName .. " Queue System",
                description = message,
                color = color or Config.Webhook.color,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
                footer = {text = Config.ServerName .. " Queue System"}
            }
        }
    }
    PerformHttpRequest(Config.Webhook.url, function(statusCode, response)
        if statusCode ~= 204 then
            print(string.format(
                      "^1[%s Queue ERROR]^0 Webhook failed with status code: %d",
                      Config.ServerName, statusCode))
        end
    end, "POST", json.encode(payload), {["Content-Type"] = "application/json"})
end

-- Send player joined queue notification
function WebhookService.playerJoinedQueue(playerName, priority, position)
    local message = string.format(
                        "🚦 **%s** joined the queue\n**Priority:** %d\n**Position:** %d",
                        playerName, priority, position)
    WebhookService.send(message, "Player Joined Queue")
end

-- Send player left queue notification
function WebhookService.playerLeftQueue(playerName, reason)
    local message = string.format("❌ **%s** left the queue\n**Reason:** %s",
                                  playerName, reason or "Disconnected")
    WebhookService.send(message, "Player Left Queue")
end

-- Send player connecting notification
function WebhookService.playerConnecting(playerName, priority)
    local message = string.format(
                        "✅ **%s** is connecting to %s\n**Priority:** %d",
                        playerName, Config.ServerName, priority)
    WebhookService.send(message, "Player Connecting", 3066993) -- Green color
end

-- Send player connected notification
function WebhookService.playerConnected(playerName)
    local message = string.format(
                        "✅ **%s** successfully joined %s! ⚙️",
                        playerName, Config.ServerName)
    WebhookService.send(message, "Player Connected", 3066993) -- Green color
end

-- Send player disconnected notification
function WebhookService.playerDisconnected(playerName, reason)
    local message = string.format("🔴 **%s** disconnected\n**Reason:** %s",
                                  playerName, reason or "Unknown reason")
    WebhookService.send(message, "Player Disconnected", 15158332) -- Red color
end

-- Send player denied access notification
function WebhookService.playerDeniedAccess(playerName, reason)
    local message = string.format("❌ **%s** denied access\n**Reason:** %s",
                                  playerName, reason)
    WebhookService.send(message, "Access Denied", 15158332) -- Red color
end

-- Send queue cleared notification
function WebhookService.queueCleared()
    local message = "🧹 **Queue cleared** by administrator"
    WebhookService.send(message, "Queue Management", 16776960) -- Yellow color
end

-- Send system started notification
function WebhookService.systemStarted()
    local message = "🟢 **" .. Config.ServerName .. " Queue System** has started!"
    WebhookService.send(message, "System Status", 3066993) -- Green color
end

-- Send system stopped notification
function WebhookService.systemStopped()
    local message = "🔴 **" .. Config.ServerName .. " Queue System** has stopped!"
    WebhookService.send(message, "System Status", 15158332) -- Red color
end

-- Send queue statistics notification
function WebhookService.queueStatistics(stats)
    local message = string.format("📊 **Queue Statistics**\n" ..
                                      "**Players in Queue:** %d\n" ..
                                      "**Players Connecting:** %d\n" ..
                                      "**Average Wait Time:** %d minutes",
                                  stats.queueSize, stats.connectingCount,
                                  math.floor(stats.averageWaitTime / 60))
    WebhookService.send(message, "Queue Statistics", 16753920) -- Orange color
end
