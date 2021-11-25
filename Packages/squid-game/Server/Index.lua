-- local maingameloop;
--Global Variables
local Gamemode = 1
local Gamemodes = {

}
local PlayersInMatch = {}
local PlayersSpectating = {}
local PlayersWonRound = {}

--Global Functions

-- function SpectateNewPlayer

function SpawnPlayer(player) 
    -- Spawns a Character at position 0, 0, 0 with default's constructor parameters
    local new_character = Character(Vector(-800, 0, 0))

    -- Possess the new Character
    player:Possess(new_character)

    --insert into table
    table.insert(PlayersInMatch, new_character)
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
local RedLightKillDelay = 1300
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
    for i, character in ipairs(PlayersInMatch) do
        local PlayersLocation = character:GetLocation()
        local PlayersLastPosition = PlayersLastPos[character:GetPlayer():GetSteamID()]
        print(PlayersLastPosition)
        if PlayersLastPosition == nil then
            PlayersLastPosition = false
        end

        --Were gonna send a raycast to see if the player is visible
        Events.CallRemote("CheckIfPlayerHasMoved", character:GetPlayer(), 
        {startpos = GirlDollHeadPosition + Vector(-500, 0, 100), endpos = PlayersLocation + Vector(100, 0, 0), PlayersLoc = PlayersLocation, PlayersLastPos = PlayersLastPosition, character = character, index = i}, true)

    end
end

function KillPlayer(i, character)
    table.remove(PlayersInMatch, i)
    table.remove(PlayersLastPos, IndexOf(PlayersLastPos, character:GetPlayer():GetSteamID()))
    table.insert( PlayersSpectating, character:GetPlayer())

    Events.BroadcastRemote("KillPlayerBomb", character:GetLocation())

    character:ApplyDamage(1000, '', DamageType.Explosion, Vector(30, 30, 30))

    character:GetPlayer():UnPossess()
end

function ChangeLight()

    if Light then
        Light = false
        Events.BroadcastRemote("DisplayLight", Light)
        print(Light)
        Timer.SetTimeout(function() StartChecking = true end, RedLightKillDelay)

        --Rotate the dolls head 180 degrees smoothly
        GirlDollHead:RotateTo(Rotator(0, 90, 0), 5)
    else
        PlayersLastPos = {}
        StartChecking = false
        Light = true
        print(Light)
        Events.BroadcastRemote("DisplayLight", Light)

        --Rotate the dolls head back
        GirlDollHead:RotateTo(Rotator(0, -90, 0), 5)

        --TESTING BELOW
        for i, player in ipairs(PlayersSpectating) do
            SpawnPlayer(player)
        end
        
        PlayersSpectating = {}

    end

    local RandomTime = GetLightRandomTime()
    Timer.SetTimeout(ChangeLight, RandomTime)

    -- EndEpisode1()
end

function StartEpisode1()
    GirlDollHead = Prop(GirlDollHeadPosition, Rotator(0, -90, 0), "squid-game::Head_Doll", CollisionType.StaticOnly, false, false)
    GirlDollHead:SetScale(Vector(200,200,200))



    print("Starting Gamemode Redlight greenlight in 10 seconds")
    Events.BroadcastRemote("DisplayLight", "Starting In 10 Seconds")
    Timer.SetTimeout(function ()

        ChangeLight()
    end, 10000)
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
end

Server.Subscribe("PlayersLastLocation", function(character, PlayersLoc) 
    PlayersLastPos[character:GetPlayer():GetSteamID()] = PlayersLoc
    print("In Last Location")
end)

--End of gamemode 1

--SetVars
Gamemodes[1] = Gamemode1Loop

Server.Subscribe("KillPlayer", function(index, character)
    print("In kill moment")
    -- TODO: Check if has authority
    KillPlayer(index, character)
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
    local character = player:GetControlledCharacter()
    KillPlayer(IndexOf(PlayersInMatch, character), character)
end)

StartEpisode1()