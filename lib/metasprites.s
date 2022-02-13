MS_MAX_COUNT = 16

.segment "ZEROPAGE"

ms_data_y: .res MS_MAX_COUNT
ms_data_x: .res MS_MAX_COUNT
ms_curr: .res 1

; All metasprites have two sprites.
; The following labels marks the offset of each.
ms_curr_sprite_0: .res 1
ms_curr_sprite_1: .res 1

.segment "CODE"

ms_draw:
  ; two sprites centred around the currently selected tile
  ; y position (note, needs to be one line higher than sprite's appearance)
  jsr ms_sprites_set

@y_calculation:
  ldx ms_curr
  lda ms_data_y, X
  sec
  sbc #5 ; Y-5
  tay

@y_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_Y_OFFSET
  tya
  sta oam, X

@y_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_Y_OFFSET
  tya
  sta oam, X

@tile_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_T_OFFSET
  lda #1
  sta oam, X

@tile_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_T_OFFSET
  lda #1
  sta oam, X

@attributes_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_A_OFFSET
  lda #%00000000 ; no flip
  sta oam, X

@attributes_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_A_OFFSET
  lda #%01000000 ; horizontal flip
  sta oam, X

@x_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_X_OFFSET
  ldy ms_curr
  lda ms_data_x, Y
  sec
  sbc #4 ; X-4
  sta oam, X

@x_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_X_OFFSET
  ldy ms_curr
  lda ms_data_x, Y
  clc
  adc #4 ; X+4
  sta oam, X

@return:
  rts

ms_sprites_set:
  ; First sprite
  lda ms_curr
  asl
  asl
  sta ms_curr_sprite_0

  ; Second sprite
  lda ms_curr
  adc #1
  asl
  asl
  sta ms_curr_sprite_1

  rts
