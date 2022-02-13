.define CURSOR_MSI #$00

.segment "ZEROPAGE"
cursor_x: .res 1
cursor_y: .res 1

.segment "CODE"

move_cursor_down:
  inc cursor_y
  ; Y wraps at 240
  lda cursor_y
  cmp #240
  bcc :+
    lda #0
    sta cursor_y
  :
  rts

move_cursor_left:
  dec cursor_x
  rts

move_cursor_up:
  dec cursor_y
  ; Y wraps at 240
  lda cursor_y
  cmp #240
  bcc :+
    lda #239
    sta cursor_y
  :
  rts

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

update_cursor:
  ldx CURSOR_MSI

@set_y:
  lda cursor_y
  sta ms_data_y, X

@set_x:
  lda cursor_x
  sta ms_data_x, X

@set_current:
  lda CURSOR_MSI
  sta ms_curr

@call_draw:
  jsr ms_draw

@return:
  rts
