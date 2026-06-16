@echo off
nim c --out:build/Actugate --nimcache:build/nimcache --debugger:native --stacktrace:on src/actugate.nim
.\build\Actugate.exe