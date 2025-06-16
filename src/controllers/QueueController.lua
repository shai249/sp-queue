QueueController = {}

-- Initialize the controller
function QueueController.init(queueModel)
    QueueController.queue = queueModel
    Logger.info("Queue Controller initialized")
end

-- Handle player connecting
function QueueController.handlePlayerConnecting(source, name, setKickReason,
                                                deferrals)
    deferrals.defer()

    -- Initial loading message
    CardView.showLoading(deferrals, Lang.get("connecting"))

    -- Wait for join delay
    Wait(Config.JoinDelay)

    -- Validate player
    local isValid, errorType, extra = ValidationService.validatePlayer(source)
    if not isValid then
        local errorMessage = ValidationService.getErrorMessage(errorType, extra)
        CardView.showError(deferrals, errorMessage)

        if errorType == "not_in_discord" then
            WebhookService.playerDeniedAccess(name, "Not in Discord server")
        end
        return
    end

    -- Check Discord server membership specifically
    if Config.Discord.enabled and Config.Discord.requireServerMembership then
        CardView.showLoading(deferrals,
                             "🔍 Checking Discord server membership...")

        if not DiscordService.isPlayerInServer(source) then
            CardView.showError(deferrals, Lang.get("notInDiscord"))
            WebhookService.playerDeniedAccess(name, "Not in Discord server")
            return
        end

        Logger.info(string.format("Player %s verified as Discord server member",
                                  name))
    end

    -- Check if server is full
    local playersOnline = #GetPlayers()
    local maxPlayers = Config.MaxPlayers

    if playersOnline >= maxPlayers then
        QueueController.addToQueue(source, name, deferrals)
    else
        QueueController.directConnect(source, name, deferrals)
    end
end

-- Add player to queue
function QueueController.addToQueue(source, name, deferrals)
    local priority = ValidationService.calculatePriority(source)
    local player = Player.new(source, name, priority)
    player:setDeferrals(deferrals)

    local success, message = QueueController.queue:addPlayer(player)
    if success then
        local position = QueueController.queue:getPlayerPosition(source)
        Logger.playerAction(source, "added to queue", string.format(
                                "Priority: %d, Position: %d", priority, position))
        WebhookService.playerJoinedQueue(name, priority, position)

        -- Update card immediately
        QueueController.updatePlayerCard(source)
    else
        Logger.warn(string.format("Failed to add player %s to queue: %s", name,
                                  message))
        -- Player already in queue, just update their card
        QueueController.updatePlayerCard(source)
    end
end

-- Handle direct connection
function QueueController.directConnect(source, name, deferrals)
    Logger.playerAction(source, "connecting directly", nil)

    -- Create temporary queue entry for display purposes
    local priority = ValidationService.calculatePriority(source)
    local player = Player.new(source, name, priority)
    player:setDeferrals(deferrals)
    player.isDirect = true

    -- Add to queue temporarily for display
    QueueController.queue:addPlayer(player)

    -- Show player info screen
    CardView.updateCard(source, deferrals, 1, 1, priority, true)

    -- Wait for display duration then allow connection
    SetTimeout(Config.DirectConnectionDisplayTime, function()
        -- Remove from temporary queue
        QueueController.queue:removePlayer(source, "Direct connection")

        -- Allow connection
        deferrals.done()

        WebhookService.playerConnected(name)
    end)
end

-- Remove player from queue
function QueueController.removeFromQueue(source, reason)
    local player, removeReason = QueueController.queue:removePlayer(source,
                                                                    reason)
    if player then
        Logger.playerAction(source, "removed from queue", removeReason)
        WebhookService.playerLeftQueue(player.name, removeReason)
        return true
    end
    return false
end

-- Process the queue
function QueueController.processQueue()
    local playersOnline = #GetPlayers()
    local maxPlayers = Config.MaxPlayers

    -- Clean up disconnected players
    local removedCount = QueueController.queue:cleanup()
    if removedCount > 0 then
        Logger.debug(string.format("Cleaned up %d disconnected players",
                                   removedCount))
    end

    -- Check if we can let someone in
    if playersOnline < maxPlayers then
        local nextPlayer = QueueController.queue:getNextPlayer()
        if nextPlayer then QueueController.connectNextPlayer(nextPlayer) end
    end

    -- Update queue time points
    QueueController.queue:updateQueueTimePoints()

    -- Update all players in queue
    QueueController.updateAllCards()

    -- Check for timeouts
    QueueController.handleTimeouts()
end

-- Connect the next player in queue
function QueueController.connectNextPlayer(player)
    -- Move to connecting state
    QueueController.queue:moveToConnecting(player.source)

    -- Allow player to connect
    if player.deferrals then player.deferrals.done() end

    Logger.playerAction(player.source, "connecting from queue",
                        string.format("Priority: %d", player.priority))
    WebhookService.playerConnecting(player.name, player.priority)

    -- Remove from connecting list after delay
    SetTimeout(30000, function()
        QueueController.queue:removeFromConnecting(player.source)
    end)
end

-- Update player card
function QueueController.updatePlayerCard(source)
    local player = QueueController.queue:getPlayer(source)
    if player and player.deferrals then
        local position = QueueController.queue:getPlayerPosition(source)
        local queueSize = QueueController.queue:getSize()

        -- Check for position inconsistencies (skip for direct connections)
        if not player.isDirect and (position == 0 or position > queueSize) then
            Logger.warn(string.format(
                            "Position inconsistency for player %s: pos=%d, size=%d",
                            player.name, position, queueSize))
            return
        end

        CardView.updateCard(source, player.deferrals, position, queueSize,
                            player.priority, player.isDirect)
        player:updateActivity()
    end
end

-- Update all player cards
function QueueController.updateAllCards()
    for _, player in ipairs(QueueController.queue.players) do
        if player.deferrals then
            QueueController.updatePlayerCard(player.source)
        end
    end
end

-- Handle player timeouts
function QueueController.handleTimeouts()
    local timedOutPlayers = QueueController.queue:checkTimeouts()

    for _, player in ipairs(timedOutPlayers) do
        if player.deferrals then
            player.deferrals.done(Lang.get("connection_error"))
        end
        Logger.playerAction(player.source, "timed out", nil)
        WebhookService.playerLeftQueue(player.name, "Timeout")
    end
end

-- Handle player joining
function QueueController.handlePlayerJoining(source)
    local playerName = GetPlayerName(source)

    -- Remove from connecting list
    QueueController.queue:removeFromConnecting(source)

    Logger.playerAction(source, "successfully joined", nil)
    WebhookService.playerConnected(playerName)
end

-- Handle player dropped
function QueueController.handlePlayerDropped(source, reason)
    local playerName = GetPlayerName(source)

    -- Remove from queue
    QueueController.removeFromQueue(source, reason)

    -- Remove from connecting list
    QueueController.queue:removeFromConnecting(source)

    -- Add to reconnect list if enabled
    if Config.ReconnectPrio.enabled then
        local steamId = ValidationService.getSteamId(source)
        if steamId then
            QueueController.queue:addReconnectData(steamId, playerName)
            Logger.info(string.format("Player %s added to reconnect list",
                                      playerName))
        end
    end

    Logger.playerAction(source, "disconnected", reason)
    WebhookService.playerDisconnected(playerName, reason)
end

-- Get queue statistics
function QueueController.getStatistics()
    return QueueController.queue:getStatistics()
end

-- Clear the queue
function QueueController.clearQueue()
    for _, player in ipairs(QueueController.queue.players) do
        if player.deferrals then
            player.deferrals.done("Queue cleared by administrator")
        end
    end

    QueueController.queue.players = {}
    Logger.system("queue cleared", "by administrator")
    WebhookService.queueCleared()
end

-- Export functions for backwards compatibility
function QueueController.getQueueCount() return QueueController.queue:getSize() end

function QueueController.isInQueue(source)
    return QueueController.queue:isPlayerInQueue(source)
end

function QueueController.getPrioData(source)
    local player = QueueController.queue:getPlayer(source)
    if player then
        return {
            position = QueueController.queue:getPlayerPosition(source),
            priority = player.priority,
            joinTime = player.joinTime
        }
    end
    return nil
end

function QueueController.getQueueList()
    return QueueController.queue:getAllPlayers()
end
