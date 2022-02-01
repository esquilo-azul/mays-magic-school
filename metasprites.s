MS_MAX_COUNT = 16

.segment "ZEROPAGE"

ms_data_y: .res MS_MAX_COUNT
ms_data_x: .res MS_MAX_COUNT
ms_curr: .res 1

.segment "CODE"

ms_draw:
  ; four sprites centred around the currently selected tile
  ; y position (note, needs to be one line higher than sprite's appearance)
  ldx ms_curr
  lda ms_data_y, X
  sec
  sbc #5 ; Y-5
  sta sprite_y(0)
  sta sprite_y(1)
  ; tile
  lda #1
  sta sprite_t(0)
  sta sprite_t(1)
  ; attributes
  lda #%00000000 ; no flip
  sta sprite_a(0)
  lda #%01000000 ; horizontal flip
  sta sprite_a(1)
  ; x position
  ldx ms_curr
  lda ms_data_x, X
  sec
  sbc #4 ; X-4
  sta sprite_x(0)
  lda ms_data_x, X
  clc
  adc #4 ; X+4
  sta sprite_x(1)
  rts
