scroll_bottom_right:
  inc scroll_x
  inc scroll_y
  ; Y wraps at 240
  lda scroll_y
  cmp #240
  bcc :+
    lda #0
    sta scroll_y
  :
  ; when X rolls over, toggle the high bit of nametable select
  lda scroll_x
  bne :+
    lda scroll_nmt
    eor #$01
    sta scroll_nmt
  :
  rts

reset_scroll:
  lda #0
  sta scroll_x
  sta scroll_y
  sta scroll_nmt
  rts
