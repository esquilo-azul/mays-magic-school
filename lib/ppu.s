; Enable rendering.
.macro ppu_render_on
  lda #%00011110
  sta PPUMASK
.endmacro

; Disable rendering.
.macro ppu_render_off
  lda #%00000000
  sta PPUMASK
.endmacro

; Flag ppu_update_status as done.
.macro ppu_update_done
  ldx #PPU_UPDATE_STATUS_DONE
  stx ppu_update_status
.endmacro

.segment "CODE"

; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
ppu_update:
  lda #PPU_UPDATE_STATUS_ON
  sta ppu_update_status
  :
    lda ppu_update_status
    bne :-
  rts

; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via $2007)
ppu_off:
  lda #PPU_UPDATE_STATUS_OFF
  sta ppu_update_status
  :
    lda ppu_update_status
    bne :-
  rts

; ppu_address_tile: use with rendering off, sets memory address to tile at X/Y, ready for a $2007 write
;   Y =  0- 31 nametable $2000
;   Y = 32- 63 nametable $2400
;   Y = 64- 95 nametable $2800
;   Y = 96-127 nametable $2C00
ppu_address_tile:
  lda PPUSTATUS ; reset latch
  tya
  lsr
  lsr
  lsr
  ora #$20 ; high bits of Y + $20
  sta PPUADDR
  tya
  asl
  asl
  asl
  asl
  asl
  sta ppu_temp0
  txa
  ora ppu_temp0
  sta PPUADDR ; low bits of Y + X
  rts

; ppu_update_tile: can be used with rendering on, sets the tile at X/Y to tile A
; next time you call ppu_update
ppu_update_tile:
  pha ; temporarily store A on stack
  txa
  pha ; temporarily store X on stack
  ldx nmt_update_len
  tya
  lsr
  lsr
  lsr
  ora #$20 ; high bits of Y + $20
  sta nmt_update, X
  inx
  tya
  asl
  asl
  asl
  asl
  asl
  sta ppu_temp0
  pla ; recover X value (but put in A)
  ora ppu_temp0
  sta nmt_update, X
  inx
  pla ; recover A value (tile)
  sta nmt_update, X
  inx
  stx nmt_update_len
  rts

; ppu_update_byte: like ppu_update_tile, but X/Y makes the high/low bytes of the PPU address to write
;    this may be useful for updating attribute tiles
ppu_update_byte:
  pha ; temporarily store A on stack
  tya
  pha ; temporarily store Y on stack
  ldy nmt_update_len
  txa
  sta nmt_update, Y
  iny
  pla ; recover Y value (but put in Y)
  sta nmt_update, Y
  iny
  pla ; recover A value (byte)
  sta nmt_update, Y
  iny
  sty nmt_update_len
  rts
