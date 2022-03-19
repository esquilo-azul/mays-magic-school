.macro palettes_dump
  lda #%10101000
  sta PPUCTRL ; set horizontal nametable increment
  lda PPUSTATUS
  lda #$3F
  sta PPUADDR
  stx PPUADDR ; set PPU address to $3F00
  ldx #0
  :
    lda example_palette, X
    sta PPUDATA
    inx
    cpx #32
    bcc :-
.endmacro
