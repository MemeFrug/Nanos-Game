// Register for "MyEvent" from Lua
Events.Subscribe("DisplayLight", function(param) {

    if (param != "green" || param != "red") {
        document.getElementById("Light").innerHTML = param
        return
    }
    document.getElementById("Light").style.color = param
    document.getElementById("Light").innerHTML = `${param.toUpperCase()} LIGHT`
})