.segment "CODE"

setup_background:
  ; first nametable, start by clearing to empty
  lda PPUSTATUS ; reset latch
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ; empty nametable
  lda #0
  ldy #30 ; 30 rows
  :
    ldx #32 ; 32 columns
    :
      sta PPUDATA
      dex
      bne :-
    dey
    bne :--
  ; set all attributes to 0
  ldx #64 ; 64 bytes
  :
    sta PPUDATA
    dex
    bne :-
  ; fill in an area in the middle with 1/2 checkerboard
  lda #1
  ldy #8 ; start at row 8
  :
    pha ; temporarily store A, it will be clobbered by ppu_address_tile routine
    ldx #8 ; start at column 8
    jsr ppu_address_tile
    pla ; recover A
    ; write a line of checkerboard
    ldx #8
    :
      sta PPUDATA
      eor #$3
      inx
      cpx #(32-8)
      bcc :-
    eor #$3
    iny
    cpy #(30-8)
    bcc :--
  ; second nametable, fill with simple pattern
  lda #$24
  sta PPUADDR
  lda #$00
  sta PPUADDR
  lda #$00
  ldy #30
  :
    ldx #32
    :
      sta PPUDATA
      clc
      adc #1
      and #3
      dex
      bne :-
    clc
    adc #1
    and #3
    dey
    bne :--
  ; 4 stripes of attribute
  lda #0
  ldy #4
  :
    ldx #16
    :
      sta PPUDATA
      dex
      bne :-
    clc
    adc #%01010101
    dey
    bne :--
  rts