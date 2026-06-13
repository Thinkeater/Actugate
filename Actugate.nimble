version = "0.0.0"
author = "Thinkeater Studio"
description = ""

let buildFlags = @[
  "--out:build/Actugate",
  "--nimcache:build/nimcache",
  "--debugger:native",
  "--stacktrace:on"
]
let target = "src/Actugate.nim"

task build, "Build the project":
  exec "nim c " & buildFlags.join(" ") & " " & target