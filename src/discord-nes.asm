; Copyright (C) 2019, Vi Grey
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
;
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.

; Version 0.0.1

  .db "NES", $1A
  .db $02
  .db $01
  .db $01
  .db $00
  .db 0, 0, 0, 0, 0, 0, 0, 0

.include "ram.asm"
.include "defs.asm"

.base $8000

RESET:
  sei
  cld
  ldx #$40
  stx $4017
  ldx #$FF
  txs
  inx
  lda #%00000110
  sta PPU_MASK
  lda #$00
  sta PPU_CTRL
  stx $4010
  ldy #$00

InitialVWait:
  ldx #$02
InitialVWaitLoop:
  lda PPU_STATUS
  bpl InitialVWaitLoop
    dex
    bne InitialVWaitLoop

InitializeRAM:
  ldx #$00
InitializeRAMLoop:
  lda #$00
  sta Variables, x
  sta DrawBuffer, x
  lda #$FE
  sta $0200, x
  inx
  bne InitializeRAMLoop
    jsr ClearPPURAM
    jsr ClearScreen
    jsr SetPalette
    jsr DrawTitleScreen
    jsr ResetScroll

Forever:
  jmp Forever

NMI:
  lda #$00
  sta PPU_OAM_ADDR
  lda #$02
  sta OAM_DMA
  lda PPU_STATUS
  jsr DrawLastFrame
  jsr Draw
  jsr ResetScroll
  jsr Update
NMICheckSprite0:
  lda screen
  cmp #SCREEN_CHAT
  bne NMIDone
Sprite0ClearWait:
  bit $2002
  bvs Sprite0ClearWait
Sprite0HitWait:
  bit $2002
  bvc Sprite0HitWait:
    lda #%00000100
    sta PPU_ADDR
    lda #$06
    sta PPU_SCROLL
    ldx #$0A
  HBlankWait:
    dex
    bne HBlankWait
      lda #$00
      sta PPU_SCROLL
      lda #$00
      sta PPU_ADDR
NMIDone:
  ldy drawbufferoffset
  lda #$10
  sta (drawbuffer), y
  rti

DrawLastFrame:
  ldx #$00
  stx drawbufferoffset
  ldy #$02
  lda drawbuffer, x
  cmp #$10
  beq DrawLastFrameDone
  cmp #$00
  bne DrawLastFrameDone
  lda #$10
  sta drawbuffer, x
DrawLastFrameSetAddrLoop:
  inx
  lda drawbuffer, x
  sta PPU_ADDR
  dey
  bne DrawLastFrameSetAddrLoop
DrawLastFrameLoop:
  ldy #$02
  inx
  lda drawbuffer, x
  bne DrawLastFrameNotNewAddress
    lda #$10
    sta drawbuffer, x
    jmp DrawLastFrameSetAddrLoop
DrawLastFrameNotNewAddress:
  cmp #$10
  bne DrawLastFrameLoopContinue
    jsr ResetScroll
    jmp DrawLastFrameDone
DrawLastFrameLoopContinue:
  sta PPU_DATA
  jmp DrawLastFrameLoop
DrawLastFrameDone:
  rts

Update:
  lda screen
  cmp #SCREEN_TITLE
  bne UpdateNotTitleScreen
UpdateTitleScreenFrames:
  dec frames
  bne UpdateDone
    lda #FPS
    sta frames
    dec seconds
    bne UpdateDone
      jsr Blank
      jsr ClearScreen
      jsr SetPalette
      jsr DrawChatScreen
      jsr ResetScroll
      jmp UpdateDone
UpdateNotTitleScreen:
  jsr UpdateCursor
  lda frames
  and #$01
  asl
  asl
  asl
  asl
  tax
  lda #$10
  sta tmp
  cpx #$10
  bne Controller1PollLoop
    jsr LatchControllers
    jsr PollControllers
    inx
    dec tmp
Controller1PollLoop:
  jsr LatchControllers
  jsr PollController1
  inx
  dec tmp
  bne Controller1PollLoop
    inc frames 
    lda frames
    and #$01
    bne HandleController2Buttons
      jsr CharacterInputDraw
      lda newlines
      cmp #$02
      bne UpdateDone
        jsr OddFrameClearLine
        jmp UpdateDone
  HandleController2Buttons:
    ;jsr CheckA
    ;jsr CheckB
    ;jsr CheckStart
    ;jsr CheckUp
    ;jsr CheckDown
    jsr EvenFrameClearLine
UpdateDone:
  rts

EvenFrameClearLine:
  lda textaddr
  sta tmp
  lda (textaddr + 1)
  sta (tmp + 1)
  lda (textaddr + 1)
  and #%11100000
  clc
  adc #$A0
  sta (textaddr + 1)
  lda textaddr
  adc #$00
  sta textaddr
  jsr UpdateTextAddr
  ldy drawbufferoffset
  lda #$00
  sta (drawbuffer), y
  iny
  lda textaddr
  sta (drawbuffer), y
  iny
  lda (textaddr + 1)
  sta (drawbuffer), y
  iny
  lda #$20
  tax
EvenFrameClearLineLoop:
  sta (drawbuffer), y
  iny
  dex
  bne EvenFrameClearLineLoop
    sty drawbufferoffset
    lda tmp
    sta textaddr
    lda (tmp + 1)
    sta (textaddr + 1)
    rts

OddFrameClearLine:
  lda textaddr
  sta tmp
  lda (textaddr + 1)
  sta (tmp + 1)
  lda (textaddr + 1)
  and #%11100000
  clc
  adc #$80
  sta (textaddr + 1)
  lda textaddr
  adc #$00
  sta textaddr
  jsr UpdateTextAddr
  ldy drawbufferoffset
  lda #$00
  sta (drawbuffer), y
  iny
  lda textaddr
  sta (drawbuffer), y
  iny
  lda (textaddr + 1)
  sta (drawbuffer), y
  iny
  lda #$20
  tax
OddFrameClearLineLoop:
  sta (drawbuffer), y
  iny
  dex
  bne OddFrameClearLineLoop
    sty drawbufferoffset
    lda tmp
    sta textaddr
    lda (tmp + 1)
    sta (textaddr + 1)
    rts

UpdateTextAddr:
  lda textaddr
  cmp #$23
  bcc UpdateTextAddrDone
    bne UpdateTextAddrReset
      lda (textaddr + 1)
      cmp #$C0
      bcc UpdateTextAddrDone
UpdateTextAddrReset:
  lda (textaddr + 1)
  sec
  sbc #$C0
  sta (textaddr + 1)
  lda textaddr
  sbc #$03
  sta textaddr
UpdateTextAddrDone:
  rts

LatchControllers:
  ldy #$01
  sty CONTROLLER1
  dey
  sty CONTROLLER1
  rts

PollControllers:
  lda controller2
  sta controller2lastframe
  ldy #$08
PollControllersLoop:
  lda CONTROLLER1
  lsr A
  rol characters, x
  lda CONTROLLER2
  lsr A
  rol controller2
  dey
  bne PollControllersLoop
    rts

PollController1:
  ldy #$08
PollController1Loop:
  lda CONTROLLER1
  lsr A
  rol characters, x
  dey
  bne PollController1Loop
    rts

CheckUp:
  lda controller2
  cmp #BUTTON_UP
  bne CheckUpDone
    and controller2lastframe
    bne CheckUpDone
      ldx chatinputoffset
      inc chatinputbuffer, x
      lda chatinputbuffer, x
      cmp #189
      bne CheckUpDraw
        lda #$00
        sta chatinputbuffer, x
CheckUpDraw:
  jsr DrawChatInput
CheckUpDone:
  rts

CheckDown:
  lda controller2
  cmp #BUTTON_DOWN
  bne CheckDownDone
    and controller2lastframe
    bne CheckDownDone
      ldx chatinputoffset
      dec chatinputbuffer, x
      lda chatinputbuffer, x
      cmp #$FF
      bne CheckDownDraw
        lda #188
        sta chatinputbuffer, x
CheckDownDraw:
  jsr DrawChatInput
CheckDownDone:
  rts

CheckA:
  lda controller2
  cmp #BUTTON_A
  bne CheckADone
    and controller2lastframe
    bne CheckADone
      inc chatinputoffset
      lda chatinputoffset
      cmp #$80
      bne CheckADraw
        dec chatinputoffset
CheckADraw:
  jsr DrawChatInput
CheckADone:
  rts

CheckB:
  lda controller2
  cmp #BUTTON_B
  bne CheckBDone
    and controller2lastframe
    bne CheckBDone
      ldx chatinputoffset
      beq CheckBDone
        lda #$00
        sta chatinputbuffer, x
        dec chatinputoffset
CheckBDraw:
  jsr DrawChatInput
CheckBDone:
  rts

CheckStart:
  lda controller2
  cmp #BUTTON_START
  bne CheckStartDone
    and controller2lastframe
    bne CheckStartDone
      jsr ClearChatInput
CheckStartDone:
  rts

ClearChatInput:
  lda #$00
  ldx #$7F
ClearChatInputLoop:
  sta chatinputbuffer, x
  dex
  bpl ClearChatInputLoop
    sta chatinputoffset
    jsr DrawChatInput
    rts

DrawChatInput:
  ldy drawbufferoffset
  lda #$00
  sta (drawbuffer), y
  iny
  lda #$24
  sta (drawbuffer), y
  iny
  lda #$42
  sta (drawbuffer), y
  iny
  lda chatinputoffset
  sec
  sbc #27
  bpl DrawChatInputSbcChatInputOffsetContinue
    lda #$00
DrawChatInputSbcChatInputOffsetContinue:
  sta (tmp + 1)
  lda #28
  sta tmp
DrawChatInputLineLoop:
  ldx (tmp + 1)
  lda chatinputbuffer, x
  tax
  lda Controller1CharacterOrder, x
  sta (drawbuffer), y
  iny
  inc (tmp + 1)
  dec tmp
  bne DrawChatInputLineLoop
    sty drawbufferoffset
  lda chatinputoffset
  cmp #28
  bcc DrawChatInputCursor
    lda #27
DrawChatInputCursor:
  clc
  adc #$02
  asl
  asl
  asl
  sta $207
DrawChatInputDone:
  rts


ResetScroll:
  lda #$00
  sta PPU_SCROLL
  lda yscroll
  sta PPU_SCROLL
  jsr EnableNMI
  rts

Draw:
  lda #%11111110
  sta PPU_MASK
  rts

DisableNMI:
  lda #$00
  sta PPU_CTRL
  rts

EnableNMI:
  lda #%10000000
  clc
  adc nametable
  adc patterntable
  sta PPU_CTRL
  rts

Blank:
  lda #%11100110
  sta PPU_MASK
  jsr DisableNMI
  rts

ClearPPURAM:
  lda #$20
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldy #$10
  ldx #$00
  txa
ClearPPURAMLoop:
  sta PPU_DATA
  dex
  bne ClearPPURAMLoop
    ldx #$00
    dey
    bne ClearPPURAMLoop
      rts

ClearScreen:
  ldx #$00
  lda #$20
  sta addr
  jmp ClearScreenStartNametableLoop
ClearScreenLoop:
  lda addr
  clc
  adc #$04
  sta addr
ClearScreenStartNametableLoop:
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldx #$1E
  ldy #$20
  lda #$01
ClearScreenNametableLoop:
  sta PPU_DATA
  dex
  bne ClearScreenNametableLoop
    ldx #$1E
    dey
    bne ClearScreenNametableLoop
      lda addr
      cmp #$2C
      bne ClearScreenLoop
        rts

SetPalette:
  lda #$3F
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldx #$08
SetPaletteLoop:
  lda #$2D
  sta PPU_DATA
  sta PPU_DATA
  lda #$22
  sta PPU_DATA
  lda #$30
  sta PPU_DATA
  dex
  bne SetPaletteLoop
    rts

DrawTitleScreen:
DrawLogo:
  lda #$21
  sta PPU_ADDR
  lda #$2D
  sta PPU_ADDR
  ldx #$81
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  lda #$21
  sta PPU_ADDR
  lda #$4D
  sta PPU_ADDR
  ldx #$91
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  lda #$21
  sta PPU_ADDR
  lda #$6D
  sta PPU_ADDR
  ldx #$A1
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  lda #$21
  sta PPU_ADDR
  lda #$8D
  sta PPU_ADDR
  ldx #$B1
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  lda #$21
  sta PPU_ADDR
  lda #$AD
  sta PPU_ADDR
  ldx #$C1
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
DrawDiscordText:
  lda #$21
  sta PPU_ADDR
  lda #$EC
  sta PPU_ADDR
  ldx #$D0
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  lda #$22
  sta PPU_ADDR
  lda #$0C
  sta PPU_ADDR
  ldx #$E0
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
  inx
  stx PPU_DATA
DrawConnecting:
  lda #$22
  sta PPU_ADDR
  lda #$CD
  sta PPU_ADDR
  ldx #$EA
DrawConnectingLoop:
  stx PPU_DATA
  inx
  cpx #$F0
  bne DrawConnectingLoop
DrawCredits:
  lda #$23
  sta PPU_ADDR
  lda #$42
  sta PPU_ADDR
  ldx #$F0
DrawCreditsLoop:
  stx PPU_DATA
  inx
  bne DrawCreditsLoop
DrawLoadingText:
  lda #$22
  sta PPU_ADDR
  lda #$84
  sta PPU_ADDR
  lda #<(LoadingText)
  sta addr
  lda #>(LoadingText)
  sta (addr + 1)
  ldy #$00
DrawLoadingTextLoop:
  lda (addr), y
  sta PPU_DATA
  iny
  cpy #24
  bne DrawLoadingTextLoop
DrawVersion:
  lda #$20
  sta PPU_ADDR
  lda #$79
  sta PPU_ADDR
  ldx #$DB
DrawVersionLoop:
  stx PPU_DATA
  inx
  cpx #$E0
  bne DrawVersionLoop
SetTitleScreenTimer:
  lda #SECONDS
  sta seconds
  lda #FPS
  sta frames
SetTitleScreenScreenValue:
  lda #SCREEN_TITLE
  sta screen
SetTitleScreenNametable:
  lda #$00
  sta nametable
SetTitleScreenPatterntable:
  lda #%00000000
  sta patterntable
  rts

DrawChatScreen:
DrawChatBar:
  lda #$24
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  lda #$0F
  ldx #$20
DrawChatBarLoop:
  sta $
  sta PPU_DATA
  dex
  bne DrawChatBarLoop
SetChatScreenScreenVariable:
  lda #SCREEN_CHAT
  sta screen
SetChatScreenNametable:
  lda #$00
  sta nametable
SetChatScreenCursor:
  lda #225
  sta $204
  lda #$0E
  sta $205
  lda #$00
  sta $206
  lda #16
  sta $207
  lda #$00
  sta cursorframes
SetChatScreenPatterntable:
  lda #%00011000
  sta patterntable
DrawChatScreenSprite0:
  lda #198
  sta $200
  lda #$0D
  sta $201
  lda #$00
  sta $202
  lda #$40
  sta $203
ResetChatInputBuffer:
  ldx #$00
  stx chatinputoffset
  lda #$00
ResetChatInputBufferLoop:
  sta chatinputbuffer, x
  inx
  cpx #$80
  bne ResetChatInputBufferLoop
ResetChatTextAddr:
  lda #$20
  sta textaddr
  lda #$41
  sta (textaddr + 1)
  rts

UpdateCursor:
  inc cursorframes
  lda #FPS
  lsr
  cmp cursorframes
  bne UpdateCursorDone
    lda #$00
    sta cursorframes
    lda $205
    bne UpdateCursorNotBlank
      lda #$0E
      sta $205
      jmp UpdateCursorDone
  UpdateCursorNotBlank:
    lda #$00
    sta $205
UpdateCursorDone:
  rts

CharacterInputDraw:
  ldy drawbufferoffset
  lda #$00
  sta newlines
  sta (drawbuffer), y
  iny
  lda textaddr
  sta (drawbuffer), y
  iny
  lda (textaddr + 1)
  sta (drawbuffer), y
  iny
  ldx #$00
CharacterInputLoop:
  lda characters, x
  sta tmp
  jsr CheckAllowedCharacter
  sta tmp
  lda tmp
  bne CharacterInputLoopAllowedCharacter
    inx
    cpx #$20
    bne CharacterInputLoop
      jmp CharacterInputDrawDone
CharacterInputLoopAllowedCharacter:
  lda (textaddr + 1)
  and #%00011111
  cmp #$01
  bne CharacterInputLoopNotStartOfLine
    lda tmp 
    cmp #$81
    beq CharacterInputLoopNotStartOfLine
      lda #$20
      sta (drawbuffer), y
      iny
      inc (textaddr + 1)
CharacterInputLoopNotStartOfLine:
  lda tmp
  cmp #$0A
  bne CharacterInputNotNewLineCharacter
    inc $B0
    ldx #$20
    jmp CharacterInputNewLine
CharacterInputNotNewLineCharacter:
  sta (drawbuffer), y
  iny
  inx
  lda (textaddr + 1)
  clc
  adc #$01
  sta (textaddr + 1)
  lda textaddr
  adc #$00
  sta textaddr
  jsr UpdateTextAddr
  lda (textaddr + 1)
  and #%00011111
  cmp #$1E
  bne CharacterInputNotNewLine
CharacterInputNewLine:
    inc newlines
    lda (textaddr + 1)
    and #%11100000
    clc
    adc #$21
    sta (textaddr + 1)
    lda textaddr
    adc #$00
    sta textaddr
    jsr UpdateTextAddr
    lda #$00
    sta (drawbuffer), y
    iny
    lda textaddr
    sta (drawbuffer), y
    iny
    lda (textaddr + 1)
    sta (drawbuffer), y
    iny
    inc textrow
    lda textrow
    cmp #23
    bcc CharacterInputNotNewLine
      lda #22
      sta textrow
      lda yscroll
      clc
      adc #$08
      sta yscroll
      cmp #240
      bne CharacterInputNotNewLine
        lda #$00
        sta yscroll
CharacterInputNotNewLine:
  cpx #$20
  beq CharacterInputDrawDone
    jmp CharacterInputLoop
CharacterInputDrawDone:
  sty drawbufferoffset
  rts

CheckAllowedCharacter:
  lda tmp
  cmp #$0A
  beq CheckAllowedCharacterDone
    cmp #$20
    bcc CheckAllowedCharacterNotAllowed
      cmp #$AD
      beq CheckAllowedCharacterNotAllowed
        cmp #$7F
        bcc CheckAllowedCharacterDone
          cmp #$A1
          bcs CheckAllowedCharacterDone
            lda (textaddr + 1)
            and #%00011111
            cmp #$01
            bne CheckAllowedCharacterNotAllowed
              lda tmp
              cmp #$81
              beq CheckAllowedCharacterDone
CheckAllowedCharacterNotAllowed:
  lda #$00
CheckAllowedCharacterDone:
  rts

.include "tables.asm"

  .pad CALLBACK, #$FF

  .dw  NMI
  .dw  RESET
  .dw  0

.base $0000
  .incbin "graphics/tileset.chr"
