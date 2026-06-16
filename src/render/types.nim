import raylib

type
  RenderConfig* = object
    tileSize*: int
    windowWidth*: int
    windowHeight*: int
    title*: string
  
  Renderer* = object
    config*: RenderConfig
    camera*: Camera2D
