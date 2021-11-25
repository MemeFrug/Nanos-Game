// Register for "MyEvent" from Lua
Events.Subscribe("ChangeLight", function(param) {
    console.log(param);
    if (param) {
        document.getElementById("Light").style.color = "green"
        document.getElementById("Light").innerHTML = "GREEN LIGHT"
    }else {
        document.getElementById("Light").style.color = "red"
        document.getElementById("Light").innerHTML = "RED LIGHT"
    }
})