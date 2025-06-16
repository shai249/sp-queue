QueueManager = {}

-- Initialize the queue system
function QueueManager.init()
    Logger.info("Initializing " .. Config.ServerName .. " Queue System...")

    -- Initialize models
    QueueManager.queue = Queue.new()

    -- Initialize controllers
    QueueController.init(QueueManager.queue)
    CommandController.init()

    -- Load card template
    CardView.loadTemplate()

    -- Disable hardcap if configured
    QueueManager.handleHardcap()

    -- Register event handlers
    QueueManager.registerEventHandlers()

    -- Start queue processing
    QueueManager.startProcessing()

    Logger.system("started", string.format(
                      "Max players: %d, Discord: %s, Anti-spam: %s, Reconnect priority: %s",
                      Config.MaxPlayers,
                      Config.Discord.enabled and "Enabled" or "Disabled",
                      Config.AntiSpam.enabled and "Enabled" or "Disabled",
                      Config.ReconnectPrio.enabled and "Enabled" or "Disabled"))

    if Config.Webhook.enabled then WebhookService.systemStarted() end
end

-- Handle hardcap resource
function QueueManager.handleHardcap()
    if Config.DisableHardCap then
        AddEventHandler("onResourceStarting", function(resource)
            if resource == "hardcap" then
                CancelEvent()
                Logger.info(
                    "Prevented hardcap resource from starting (DisableHardCap = true)")
                return
            end
        end)

        CreateThread(function()
            Wait(2000)
            StopResource("hardcap")
            Logger.info('Hardcap has been stopped')
        end)
    end
end

-- Register all event handlers
function QueueManager.registerEventHandlers()
    -- Player connecting event
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local source = source
        QueueController.handlePlayerConnecting(source, name, setKickReason,
                                               deferrals)
    end)

    -- Player joining event
    AddEventHandler('playerJoining', function(source)
        QueueController.handlePlayerJoining(source)
    end)

    -- Player dropped event
    AddEventHandler('playerDropped', function(reason)
        local source = source
        QueueController.handlePlayerDropped(source, reason)
    end)

    -- Resource stopping event
    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            Logger.system("stopping", nil)
            if Config.Webhook.enabled then
                WebhookService.systemStopped()
            end
        end
    end)
end

-- Start queue processing loop
function QueueManager.startProcessing()
    CreateThread(function()
        while true do
            QueueController.processQueue()
            Wait(Config.QueueUpdateRate)
        end
    end)

    Logger.info("Queue processing started")
end

-- Graceful shutdown
function QueueManager.shutdown()
    Logger.system("shutting down", nil)

    -- Notify all players in queue
    for _, player in ipairs(QueueManager.queue.players) do
        if player.deferrals then
            player.deferrals.done(
                "Queue system is shutting down. Please reconnect in a moment.")
        end
    end

    -- Clear queue
    QueueManager.queue.players = {}

    if Config.Webhook.enabled then WebhookService.systemStopped() end
end

-- Health check
function QueueManager.healthCheck()
    local stats = QueueController.getStatistics()
    local health = {
        status = "healthy",
        queueSize = stats.queueSize,
        connectingCount = stats.connectingCount,
        cardTemplateLoaded = CardView.hasTemplate(),
        discordEnabled = Config.Discord.enabled,
        webhookEnabled = Config.Webhook.enabled,
        uptime = os.time() - (QueueManager.startTime or os.time())
    }

    -- Check for potential issues
    if stats.queueSize > 100 then
        health.status = "warning"
        health.warning = "High queue size"
    end

    if not CardView.hasTemplate() then
        health.status = "error"
        health.error = "Card template not loaded"
    end

    return health
end

-- Set start time for uptime calculation
QueueManager.startTime = os.time()

-- Auto-initialize when the script loads
CreateThread(function()
    Wait(1000) -- Wait for all configs to load
    QueueManager.init()
end)
