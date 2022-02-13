.segment "ZEROPAGE"

temp:           .res 1 ; temporary variable

.segment "CODE"

; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
ppu_update:
  lda #1
  sta nmi_ready
  :
    lda nmi_ready
    bne :-
  rts

; ppu_skip: waits until next NMI, does not update PPU
ppu_skip:
  lda nmi_count
  :
    cmp nmi_count
    beq :-
  rts

; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via $2007)
ppu_off:
  lda #2
  sta nmi_ready
  :
    lda nmi_ready
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
  sta temp
  txa
  ora temp
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
  sta temp
  pla ; recover X value (but put in A)
  ora temp
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
