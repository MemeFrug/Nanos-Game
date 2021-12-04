World.SpawnDefaultSun()

--spawns the ui in game
main_hud = WebUI("Main HUD", "file:///UI/index.html")

Events.Subscribe("DisplayLight", function(Light)

    main_hud:CallEvent("DisplayLight", Light)
end)

Events.Subscribe("KillPlayerBomb", function (Pos)
    local GrenadeEffect = "nanos-world::P_Explosion"
    local GrenadeSound = "nanos-world::A_Explosion_Large"

    Particle(Pos, Rotator(), GrenadeEffect, true, true)
    Sound(Pos, GrenadeSound, false, true, SoundType.SFX)
end)

Events.Subscribe("CheckIfPlayerHasMoved", function (params, debug)
    print(params.character:GetPlayer())


    local trace_results = Client.Trace(params.startpos, params.endpos, CollisionChannel.Pawn | CollisionChannel.WorldStatic | CollisionChannel.PhysicsBody, false, true, false, {}, true)

    -- If hit something draws a Debug Point at the location
    if (trace_results.Success) then
        print("In Success")
        
        -- if (debug == false) then return end
        -- Makes the point Red or Green if hit an Actor
        local color = Color(1, 0, 0) -- Red

        if (trace_results.Entity) then
            print("green")
            color = Color(0, 1, 0) -- Green

            -- Here you can check which actor you hit like
            -- if (trace_result.Entity:GetType() == "Character") then ...
        end

        -- Draws a Debug Point at the Hit location for 5 seconds with size 10
        Client.DrawDebugPoint(trace_results.Location, color, 5, 10)
    else 
        print(params.PlayersLastPos)
        if (params.PlayersLastPos) then
            if (params.PlayersLastPos ~= params.PlayersLoc) then
                Events.CallRemote("KillPlayer", params.index)
            end
        else 
            print("Calling PlayersLastLocation")
            Events.CallRemote("PlayersLastLocation", params.PlayersLoc)
        end 
    end
end)