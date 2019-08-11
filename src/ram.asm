.enum $0000
Variables:
  textaddr              dsb 2
  characters            dsb 32
  newlines              dsb 1
  yscroll               dsb 1
  textrow               dsb 1
  addr                  dsb 2
  cursorframes          dsb 1
  nametable             dsb 1
  patterntable          dsb 1
  nmi                   dsb 1
  mergedvalue           dsb 1
  addrtmp               dsb 2
  tmp                   dsb 2
  nametableaddrtmp      dsb 2
  controller2           dsb 1
  controller2lastframe  dsb 1
  screen                dsb 1
  seconds               dsb 1
  frames                dsb 1
.ende

.enum $300
DrawBuffer:
  drawbufferoffset      dsb 1
  drawbuffer            dsb 255
.ende

.enum $700
  chatinputoffset       dsb 1
  chatinputbuffer       dsb 128
.ende
