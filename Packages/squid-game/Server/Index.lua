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
    if (IndexOf(PlayersSpectating, player)) then
        table.remove(PlayersSpectating, IndexOf(PlayersSpectating, player))
    end
    if (Gamemode == 1) then
        table.insert(PlayersInMatch, player) 
    else 
        table.insert( PlayersSpectating, player)
    end
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
local MinRandomTimeBetweenLights = 2000 --Milliseconds
local MaxRandomTimeBetweenLights = 10000 -- Milliseconds
local RedLightKillDelay = 1500
local Light = false
local StartChecking = false

local ChangeLightTimeout;

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
    ChangeLightTimeout = Timer.SetTimeout(ChangeLight, RandomTime)

    -- EndEpisode1()
end

local TriggerEpisode1;

function StartEpisode1()
    Light = false

    GirlDollHead = Prop(GirlDollHeadPosition, Rotator(0, -90, 0), "squid-game::Head_Doll", CollisionType.StaticOnly, false, false)
    GirlDollHead:SetScale(Vector(200,200,200))
    --Place invisible wall
    InvisibleWallStart = Prop(Vector(-190, 0, 24), Rotator(), "squid-game::Invisible_Barrier", CollisionType.Normal, false, false)
    InvisibleWallStart:SetScale(Vector(3,64,30))
    
    --End Round Trigger
    TriggerEpisode1 = Trigger(Vector(8400,0,1000), Rotator(), Vector(640, 3500, 1000), TriggerType.Box, true)

    TriggerEpisode1:Subscribe("BeginOverlap", function(trigger, actor_triggering)
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

    TriggerEpisode1:Subscribe("EndOverlap", function(trigger, actor_triggering)
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

    ChangeLightTimeout = Timer.SetTimeout(function ()
        Events.BroadcastRemote("PlaySound", "assets///squid-game/Audio/goSound.ogg", false)
        InvisibleWallStart:Destroy()
        ChangeLight()
    end, 5000)
end


function EndEpisode1()
    TriggerEpisode1:Unsubscribe("BeginOverlap")
    TriggerEpisode1:Unsubscribe("EndOverlap")
    TriggerEpisode1:Destroy()

    Gamemode = 1

    Timer.ClearTimeout(ChangeLightTimeout)

    GirlDollHead:Destroy()

    PlayNextRound()
end

function Gamemode1Loop()
    if StartChecking == true then
        CheckIfPlayerHasMoved()
    end

    --CheckIfThereAreAnyPlayersLeft
    if (Tablelength(PlayersInMatch) <= 0 and Light) then
        EndEpisode1()
    end
end

Events.Subscribe("PlayersLastLocation", function(player, PlayersLoc)
    PlayersLastPos[player:GetSteamID()] = PlayersLoc
end)

--End of gamemode 1

function PlayBackgroundMusic()
    
end

function PlayNextRound()
    PlayersInMatch = PlayersWonRound
    PlayersWonRound = {}

    if (Tablelength(PlayersInMatch) <= 1) then
        PlayersInMatch = {}
        PlayersLastPos = {}
        FinishGame()
        return
    end

    --Pick A random number between available gamemodes
    Gamemode = math.random(2, Tablelength(Gamemodes))
    Package.Log(Gamemode)
end

function StartGame()
    for i, player in ipairs(PlayersSpectating) do
        SpawnPlayer(player)
        Gamemode = 2 -- Debug
        StartEpisode1() -- Debug
    end
end

function FinishGame()
    --Display Winner
    --Start Game again
    StartGame()
end

function PreRoundUpdate()
    if (GetAmountOfPeoplePlaying() >= 1) then
        Gamemode = 2 -- Debug
        StartEpisode1() -- Debug
    end
end

function GetAmountOfPeoplePlaying()
    local b = Tablelength(PlayersSpectating)
    local a = Tablelength(PlayersInMatch)
    return a+b
end

--SetVars
Gamemodes[1] = PreRoundUpdate
Gamemodes[2] = Gamemode1Loop

Events.Subscribe("KillPlayer", function(player)
    --Check if player is possessing anything

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

--Server Console Commands

local Commands = {
    {string = "Tables", command = function ()
        Package.Log("InMatch: " .. NanosUtils.Dump(PlayersInMatch))
        Package.Log("LastPos: " .. NanosUtils.Dump(PlayersLastPos))
        Package.Log("Spectating: " .. NanosUtils.Dump(PlayersSpectating))
        Package.Log("WonRound: " .. NanosUtils.Dump(PlayersWonRound))
    end},    
    {string = "kick", command = function ()
        Package.Log("Kicking/Banning Player")
    end},
}

Server.Subscribe("Console", function(my_input)
    local IsanCommand = false

    for i, command in ipairs(Commands) do
        if (my_input == command.string) then
            IsanCommand = true
            command.command()
        end
    end

    if (not IsanCommand) then
        Package.Error("Command Not Found")
    end
end)