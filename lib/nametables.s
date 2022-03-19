.macro nametable_dump
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
.endmacro
