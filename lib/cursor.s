.define CURSOR_MSI #$00

.segment "ZEROPAGE"
cursor_x: .res 1
cursor_y: .res 1

.segment "CODE"

; snap_cursor: snap cursor to nearest tile
snap_cursor:
  lda cursor_x
  clc
  adc #4
  and #$F8
  sta cursor_x
  lda cursor_y
  clc
  adc #4
  and #$F8
  sta cursor_y
  ; Y wraps at 240
  cmp #240
  bcc :+
    lda #0
    sta cursor_y
  :
  rts

draw_cursor:
  ; four sprites centred around the currently selected tile
  ; y position (note, needs to be one line higher than sprite's appearance)
  ldx CURSOR_MSI

  lda cursor_y
  sta ms_data_y, X

  lda cursor_x
  sta ms_data_x, X

  lda CURSOR_MSI
  sta ms_curr
  jsr ms_draw
  rts
