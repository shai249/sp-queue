CommandController = {}

-- Initialize the controller
function CommandController.init()
    CommandController.registerCommands()
    CommandController.registerExports()
    Logger.info("Command Controller initialized")
end

-- Register admin commands
function CommandController.registerCommands()
    -- Queue status command (console only)
    RegisterCommand('queue', function(source, args)
        if source == 0 then -- Console only
            CommandController.showQueueStatus()
        end
    end, true)

    -- Clear queue command (console only)
    RegisterCommand('clearqueue', function(source, args)
        if source == 0 then -- Console only
            CommandController.clearQueue()
        end
    end, true)

    -- Queue statistics command (console only)
    RegisterCommand('queuestats', function(source, args)
        if source == 0 then -- Console only
            CommandController.showQueueStatistics()
        end
    end, true)

    -- Reload queue template command (console only)
    RegisterCommand('reloadtemplate', function(source, args)
        if source == 0 then -- Console only
            CommandController.reloadTemplate()
        end
    end, true)

    -- Set player priority command (console only)
    RegisterCommand('setpriority', function(source, args)
        if source == 0 then -- Console only
            if #args >= 2 then
                local playerId = tonumber(args[1])
                local priority = tonumber(args[2])
                CommandController.setPlayerPriority(playerId, priority)
            else
                print("^1Usage: setpriority <player_id> <priority>^0")
            end
        end
    end, true)

    -- Kick player from queue command (console only)
    RegisterCommand('kickqueue', function(source, args)
        if source == 0 then -- Console only
            if #args >= 1 then
                local playerId = tonumber(args[1])
                local reason = table.concat(args, " ", 2) or
                                   "Kicked by administrator"
                CommandController.kickFromQueue(playerId, reason)
            else
                print("^1Usage: kickqueue <player_id> [reason]^0")
            end
        end
    end, true)
end

-- Register exports
function CommandController.registerExports()
    -- Export queue count
    exports('getQueueCount',
            function() return QueueController.getQueueCount() end)

    -- Export queue check
    exports('isInQueue',
            function(source) return QueueController.isInQueue(source) end)

    -- Export priority data
    exports('getPrioData',
            function(source) return QueueController.getPrioData(source) end)

    -- Export queue list
    exports('getQueueList', function() return QueueController.getQueueList() end)

    -- Export queue statistics
    exports('getQueueStats',
            function() return QueueController.getStatistics() end)

    -- Export add priority points
    exports('addPriorityPoints', function(source, points)
        return CommandController.addPriorityPoints(source, points)
    end)

    -- Export remove from queue
    exports('removeFromQueue', function(source, reason)
        return QueueController.removeFromQueue(source, reason)
    end)
end

-- Show queue status
function CommandController.showQueueStatus()
    local stats = QueueController.getStatistics()
    print(string.format("^3Queue Status:^0 %d players in queue, %d connecting",
                        stats.queueSize, stats.connectingCount))

    local queueList = QueueController.getQueueList()
    for i, player in ipairs(queueList) do
        print(string.format("^2%d.^0 %s (Priority: %d)", i, player.name,
                            player.priority))
    end

    if #queueList == 0 then print("^3Queue is empty^0") end
end

-- Clear the queue
function CommandController.clearQueue()
    QueueController.clearQueue()
    print("^1Queue cleared!^0")
end

-- Show queue statistics
function CommandController.showQueueStatistics()
    local stats = QueueController.getStatistics()
    print("^3=== Queue Statistics ===^0")
    print(string.format("^2Players in Queue:^0 %d", stats.queueSize))
    print(string.format("^2Players Connecting:^0 %d", stats.connectingCount))
    print(string.format("^2Average Wait Time:^0 %d minutes",
                        math.floor(stats.averageWaitTime / 60)))
    print(string.format("^2Total Processed:^0 %d", stats.totalProcessed))

    -- Send webhook notification
    WebhookService.queueStatistics(stats)
end

-- Reload card template
function CommandController.reloadTemplate()
    if CardView.reloadTemplate() then
        print("^2Present card template reloaded successfully^0")
    else
        print("^1Failed to reload present card template^0")
    end
end

-- Set player priority
function CommandController.setPlayerPriority(playerId, priority)
    if not GetPlayerName(playerId) then
        print(string.format("^1Player with ID %d not found^0", playerId))
        return false
    end

    local player = QueueController.queue:getPlayer(playerId)
    if player then
        local oldPriority = player.priority
        player.priority = priority

        -- Re-sort queue based on new priority
        table.sort(QueueController.queue.players,
                   function(a, b) return a.priority > b.priority end)

        local newPosition = QueueController.queue:getPlayerPosition(playerId)
        print(string.format(
                  "^2Player %s priority changed from %d to %d (Position: %d)^0",
                  player.name, oldPriority, priority, newPosition))

        Logger.system("priority changed", string.format("%s: %d -> %d",
                                                        player.name,
                                                        oldPriority, priority))
        return true
    else
        print(string.format("^1Player with ID %d is not in queue^0", playerId))
        return false
    end
end

-- Kick player from queue
function CommandController.kickFromQueue(playerId, reason)
    if not GetPlayerName(playerId) then
        print(string.format("^1Player with ID %d not found^0", playerId))
        return false
    end

    local removed = QueueController.removeFromQueue(playerId, reason)
    if removed then
        local playerName = GetPlayerName(playerId)
        print(string.format("^2Player %s kicked from queue: %s^0", playerName,
                            reason))
        return true
    else
        print(string.format("^1Player with ID %d is not in queue^0", playerId))
        return false
    end
end

-- Add priority points to a player
function CommandController.addPriorityPoints(source, points)
    local player = QueueController.queue:getPlayer(source)
    if player then
        player.priority = player.priority + points

        -- Re-sort queue
        table.sort(QueueController.queue.players,
                   function(a, b) return a.priority > b.priority end)

        Logger.info(string.format(
                        "Added %d priority points to %s (New total: %d)",
                        points, player.name, player.priority))
        return true
    end
    return false
end

-- Get player by identifier
function CommandController.getPlayerByIdentifier(identifier)
    for _, player in ipairs(QueueController.queue.players) do
        local playerIdentifiers = player:getIdentifiers()
        for _, id in ipairs(playerIdentifiers) do
            if id == identifier then return player end
        end
    end
    return nil
end

-- Advanced queue management functions
function CommandController.movePlayerToPosition(source, position)
    local player = QueueController.queue:getPlayer(source)
    if not player then return false, "Player not in queue" end

    if position < 1 or position > QueueController.queue:getSize() then
        return false, "Invalid position"
    end

    -- Remove from current position
    QueueController.queue:removePlayer(source, "Position change")

    -- Insert at new position
    table.insert(QueueController.queue.players, position, player)
    Logger.system("player moved", string.format("%s moved to position %d",
                                                player.name, position))
    return true, "Player moved successfully"
end
