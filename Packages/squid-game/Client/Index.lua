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