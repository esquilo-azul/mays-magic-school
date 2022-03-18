.segment "CODE"

nmi:
  push_registers
  ; prevent NMI re-entry
  lda nmi_lock
  beq :+
    jmp @nmi_end
  :
  lda #1
  sta nmi_lock
  ;
  lda ppu_update_status
  bne :+ ; ppu_update_status == 0 not ready to update PPU
    jmp @ppu_update_end
  :
  cmp #2 ; ppu_update_status == 2 turns rendering off
  bne :+
    lda #%00000000
    sta PPUMASK
    ldx #0
    stx ppu_update_status
    jmp @ppu_update_end
  :
  oam_dma
  ; palettes
  lda #%10101000
  sta PPUCTRL ; set horizontal nametable increment
  lda PPUSTATUS
  lda #$3F
  sta PPUADDR
  stx PPUADDR ; set PPU address to $3F00
  ldx #0
  :
    lda palette, X
    sta PPUDATA
    inx
    cpx #32
    bcc :-
  ; nametable update
  ldx #0
  cpx nmt_update_len
  bcs @scroll
  @nmt_update_loop:
    lda nmt_update, X
    sta PPUADDR
    inx
    lda nmt_update, X
    sta PPUADDR
    inx
    lda nmt_update, X
    sta PPUDATA
    inx
    cpx nmt_update_len
    bcc @nmt_update_loop
  lda #0
  sta nmt_update_len
@scroll:
  lda scroll_nmt
  and #%00000011 ; keep only lowest 2 bits to prevent error
  ora #%10101000
  sta PPUCTRL
  lda scroll_x
  sta PPUSCROLL
  lda scroll_y
  sta PPUSCROLL
  ; enable rendering
  lda #%00011110
  sta PPUMASK
  ; flag PPU update complete
  ldx #0
  stx ppu_update_status
@ppu_update_end:
  ; if this engine had music/sound, this would be a good place to play it
  ; unlock re-entry flag
  lda #0
  sta nmi_lock
@nmi_end:
  pull_registers
