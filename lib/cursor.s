CURSOR_MSI = $00
CURSOR_INITIAL_X = 128
CURSOR_INITIAL_Y = 120
CURSOR_SPEED = 1

.macro move_cursor face
  ldx #CURSOR_MSI
  lda #face
  sta ms_face, X
  lda #CURSOR_SPEED
  sta ms_speed
  rts
.endmacro

.segment "ZEROPAGE"
cursor_x: .res 1
cursor_y: .res 1

.segment "CODE"

init_cursor:
  lda #CURSOR_MSTI
  ldx #CURSOR_MSI
  sta ms_type, X
  jsr reset_cursor_xy
  jsr stop_cursor
  rts

reset_cursor_xy:
  lda #CURSOR_INITIAL_X
  sta cursor_x
  lda #CURSOR_INITIAL_Y
  sta cursor_y
  rts

stop_cursor:
  lda #0
  sta ms_speed, X
  rts

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

move_cursor_right:
  inc cursor_x
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

cursor_xy_to_metasprite_xy:
  ldx #CURSOR_MSI

@set_y:
  lda cursor_y
  sta ms_y, X

@set_x:
  lda cursor_x
  sta ms_x, X

@return:
  rts

metasprite_xy_to_cursor_xy:
  ldx #CURSOR_MSI

@set_y:
  lda ms_y, X
  sta cursor_y

@set_x:
  lda ms_x, X
  sta cursor_x

@return:
  rts
