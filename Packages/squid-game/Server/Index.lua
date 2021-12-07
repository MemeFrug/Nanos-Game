-- local maingameloop;
--Global Variables
local Gamemode = 1
local Gamemodes = {

}
local PlayersInMatch = {}
local PlayersSpectating = {}
local PlayersWonRound = {}

--Global Functions

function Tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- function SpectateNewPlayer

function SpawnPlayer(player) 
    -- Spawns a Character at position 0, 0, 0 with default's constructor parameters
    local new_character = Character(Vector(-800, 0, 0))
    -- -800

    -- Possess the new Character
    player:Possess(new_character)

    --insert into table
    table.insert(PlayersInMatch, player)
end

function IndexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Gamemode 1
local MinRandomTimeBetweenLights = 1500 --Milliseconds
local MaxRandomTimeBetweenLights = 1500 -- Milliseconds
local RedLightKillDelay = 1500
local Light = false
local StartChecking = false

local GirlDollHead;

local GirlDollHeadPosition = Vector(7980, 90, 0)

local PlayersLastPos = {}

function GetLightRandomTime()
    math.randomseed(os.time())
    return math.floor(math.random() * (MaxRandomTimeBetweenLights - MinRandomTimeBetweenLights + 1) + MinRandomTimeBetweenLights)
end

function CheckIfPlayerHasMoved()
    for i, player in ipairs(PlayersInMatch) do
        local PlayersLocation = player:GetControlledCharacter():GetLocation()
        if (player:GetControlledCharacter()) then
        local PlayersLastPosition = PlayersLastPos[player:GetSteamID()]
        if PlayersLastPosition == nil then
            PlayersLastPosition = false
        end

        --Were gonna send a raycast to see if the player is visible
        Events.CallRemote("CheckIfPlayerHasMoved", player, 
        {startpos = GirlDollHeadPosition + Vector(-200, 0, 300), endpos = PlayersLocation + Vector(100, 0, 0), PlayersLoc = PlayersLocation, 
        PlayersLastPos = PlayersLastPosition, character = player:GetControlledCharacter()}, true)
        end
    end
end

function KillPlayer(player)
    
    print(player)

    Events.BroadcastRemote("KillPlayerBomb", player:GetControlledCharacter():GetLocation())

    player:GetControlledCharacter():ApplyDamage(1000, '', DamageType.Explosion, Vector(30, 30, 30))

    player:UnPossess()

    table.remove(PlayersInMatch, IndexOf(PlayersInMatch, player))
    table.remove(PlayersLastPos, IndexOf(PlayersLastPos, player:GetSteamID()))
end

function ChangeLight()

    if Light then
        Light = false
        Events.BroadcastRemote("DisplayLight", "red")
        Timer.SetTimeout(function() StartChecking = true end, RedLightKillDelay)

        -- Play RedLight Sound
        Events.BroadcastRemote("PlaySound", "assets///squid-game/Audio/stopSound.ogg", false)

        --Rotate the dolls head 180 degrees smoothly
        GirlDollHead:RotateTo(Rotator(0, 90, 0), 5)
    else
        PlayersLastPos = {}
        StartChecking = false
        Light = true
        Events.BroadcastRemote("DisplayLight", "green")

        -- Play GreenLight Sound
        Events.BroadcastRemote("PlaySound", "assets///squid-game/Audio/goSound.ogg", false)

        --Rotate the dolls head back
        GirlDollHead:RotateTo(Rotator(0, -90, 0), 5)

    end

    local RandomTime = GetLightRandomTime()
    Timer.SetTimeout(ChangeLight, RandomTime)

    -- EndEpisode1()
end

function StartEpisode1()
    GirlDollHead = Prop(GirlDollHeadPosition, Rotator(0, -90, 0), "squid-game::Head_Doll", CollisionType.StaticOnly, false, false)
    GirlDollHead:SetScale(Vector(200,200,200))
    --Place invisible wall
    InvisibleWallStart = Prop(Vector(-190, 0, 24), Rotator(), "squid-game::Invisible_Barrier", CollisionType.Normal, false, false)
    InvisibleWallStart:SetScale(Vector(3,64,30))
    
    --End Round Trigger
    local Trigger = Trigger(Vector(8400,0,1000), Rotator(), Vector(640, 3500, 1000), TriggerType.Box, true)

    Trigger:Subscribe("BeginOverlap", function(trigger, actor_triggering)
        print(actor_triggering)
        if (not actor_triggering) then return end
        if (actor_triggering:GetType() == "Character") then
            for i,player in ipairs( PlayersInMatch ) do
                if player:GetControlledCharacter() == actor_triggering then
                  table.remove( PlayersInMatch, i )
                  table.insert( PlayersWonRound, player )
                  table.remove(PlayersLastPos, IndexOf(PlayersLastPos, player:GetSteamID()))
                  break;
                end
              end
        end
    end)

    Trigger:Subscribe("EndOverlap", function(trigger, actor_triggering)
        Package.Log("Something exited my Box Trigger")
        print(actor_triggering)
        if (not actor_triggering) then return end
        print('actor exists')
        if (actor_triggering:GetType() == "Character") then
            print("Is an Character")
            for i,player in ipairs( PlayersWonRound ) do
                if player:GetControlledCharacter() == actor_triggering then
                    table.remove( PlayersWonRound, i )
                    table.insert( PlayersInMatch, player )
                    break;
                end
              end
        end
    end)

    Events.BroadcastRemote("DisplayLight", "Starting In 5 Seconds")

    Timer.SetTimeout(function ()
        Events.BroadcastRemote("PlaySound", "assets///squid-game/Audio/goSound.ogg", false)
        InvisibleWallStart:Destroy()
        ChangeLight()
    end, 5000)
end


function EndEpisode1()
    -- if maingameloop then
    --     Timer.ClearInterval(maingameloop)
    -- end
end

function Gamemode1Loop()
    if StartChecking == true then
        CheckIfPlayerHasMoved()
    end

    --CheckIfThereAreAnyPlayersLeft
    if (Tablelength(PlayersInMatch) <= 0 and Light) then
        EndEpisode1()
        --TESTING BELOW
        for i, player in ipairs(PlayersSpectating) do
            -- KillPlayer(player)
            
            SpawnPlayer(player)
        end 
    end
end

Events.Subscribe("PlayersLastLocation", function(player, PlayersLoc)
    PlayersLastPos[player:GetSteamID()] = PlayersLoc
end)

--End of gamemode 1

function PlayBackgroundMusic()
    
end

--SetVars
Gamemodes[1] = Gamemode1Loop

Events.Subscribe("KillPlayer", function(player)
    --Check if player is possessing anything

    NanosUtils.Dump(PlayersInMatch)
    NanosUtils.Dump(PlayersLastPos)
    NanosUtils.Dump(PlayersSpectating)
    NanosUtils.Dump(PlayersWonRound)

    if (player:GetControlledCharacter()) then
        KillPlayer(player)
        table.insert( PlayersSpectating, player)
    end
end)

-- Main Server Loop
Server.Subscribe("Tick", function(delta)
    -- Put stuff here
    Gamemodes[Gamemode]()
end)

-- Called when Players join the server (i.e. Spawn)
Player.Subscribe("Spawn", function(new_player)
    SpawnPlayer(new_player)
end)

--Check for people already in the server
for k, player in ipairs( Player.GetAll() ) do
    SpawnPlayer( player )
end

-- When Player leaves the server, destroy it's Character
Player.Subscribe("Destroy", function(player)
    KillPlayer(player)

    --Remove Its Place in the game
    table.remove( PlayersInMatch, IndexOf(PlayersInMatch, player) )
    table.remove( PlayersWonRound, IndexOf(PlayersWonRound, player) )
    table.remove( PlayersLastPos, IndexOf(PlayersLastPos, player:GetSteamID()))
    table.remove( PlayersSpectating, IndexOf(PlayersLastPos, player))
end)

StartEpisode1()

--Server Console Commands

Server.Subscribe("debug", function(my_input)
    Package.Log("Console command received: " .. my_input)
end)