World.SpawnDefaultSun()

-- local maingameloop;
--Global Variables
local Gamemode = 1
local Gamemodes = {

}
local PlayersInMatch = {}
local PlayersSpectating = {}


--Global Functions

-- function SpectateNe

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
        print("Player " .. i)
        local PlayersLocation = character:GetLocation()

        --Were gonna send a raycast to see if the player is visible
        --Also Debugging
        -- Makes a trace with the 3D Location and it's direction multiplied by 5000
        -- Meaning it will trace 5000 units in that direction
        local trace_max_distance = 5000

        local start_location = GirlDollHeadPosition
        local end_location = PlayersLocation
        local trace_results = Client.Trace(start_location, end_location, CollisionChannel.WorldStatic | CollisionChannel.PhysicsBody, false, true, false, {}, true))

            -- If hit something draws a Debug Point at the location
        if (trace_results.Success) then

            -- Makes the point Red or Green if hit an Actor
            local color = Color(1, 0, 0) -- Red

            if (trace_results.Entity) then
                color = Color(0, 1, 0) -- Green

                -- Here you can check which actor you hit like
                -- if (trace_result.Entity:GetType() == "Character") then ...
            end

            -- Draws a Debug Point at the Hit location for 5 seconds with size 10
            Client.DrawDebugPoint(trace_results.Location, color, 5, 10)
        end
        -- print(i .. " " .. NanosUtils.Dump(PlayersLocation))

        local PlayersLastPosition = PlayersLastPos[character:GetPlayer():GetSteamID()]

        if PlayersLastPosition then
            if PlayersLastPosition ~= PlayersLocation then
                print("Player Has Moved!!")
                KillPlayer(i, character)
            end
        else 
            PlayersLastPos[character:GetPlayer():GetSteamID()] = PlayersLocation
        end

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
    GirlDollHead = Prop(GirlDollHeadPosition, Rotator(0, -90, 0), "Squid_Game::Head_Doll", CollisionType.StaticOnly, false, false)
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

--End of gamemode 1

--SetVars
Gamemodes[1] = Gamemode1Loop

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