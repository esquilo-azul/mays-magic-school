MS_MAX_COUNT = 16

.segment "ZEROPAGE"

ms_y: .res MS_MAX_COUNT
ms_x: .res MS_MAX_COUNT
ms_type: .res MS_MAX_COUNT
ms_curr: .res 1

; All metasprites have two sprites.
; The following labels marks the offset of each.
ms_curr_sprite_0: .res 1
ms_curr_sprite_1: .res 1

.macro ms_x_load attribute
  ldx ms_curr
  lda attribute, X
.endmacro

.macro ms_y_load attribute
  ldy ms_curr
  lda attribute, Y
.endmacro

.segment "CODE"

ms_clear:
  lda #DISABLED_MSTI
  sta ms_type, X
  rts

ms_clear_all:
  lda #0
  sta ms_curr
@loop:
  jsr ms_clear

  inc ms_curr
  cmp ms_curr
  bcc @loop

  rts

ms_process:
  ms_x_load ms_type
  cmp #DISABLED_MSTI
  beq @end_routine
  jsr ms_update_sprites
@end_routine:
  rts

ms_process_all:
  lda #0
  sta ms_curr
@loop:
  jsr ms_process

  inc ms_curr
  cmp ms_curr
  bcc @loop

  rts

.macro ms_update_sprites_tiles
@tile_calculation:
  ms_y_load ms_type
  ldy mst_tile, X

@tile_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_T_OFFSET
  tya
  sta oam, X

@tile_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_T_OFFSET
  tya
  sta oam, X

@attributes_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_A_OFFSET
  lda #%00000000 ; no flip
  sta oam, X

@attributes_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_A_OFFSET
  lda #%01000000 ; horizontal flip
  sta oam, X
.endmacro

.macro ms_update_sprites_xy
@x_0:
  sprite_byte_offset_to_x ms_curr_sprite_0, SPRITE_X_OFFSET
  ms_y_load ms_x
  sec
  sbc #4 ; X-4
  sta oam, X

@x_1:
  sprite_byte_offset_to_x ms_curr_sprite_1, SPRITE_X_OFFSET
  ms_y_load ms_x
  clc
  adc #4 ; X+4
  sta oam, X

@y_calculation:
  ms_x_load ms_y
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
.endmacro

ms_update_sprites:
  ; two sprites centred around the currently selected tile
  ; y position (note, needs to be one line higher than sprite's appearance)
  jsr ms_sprites_set
  ms_update_sprites_tiles
  ms_update_sprites_xy
@return:
  rts

ms_sprites_set:
@first_sprite:
  lda ms_curr
  asl
  asl
  sta ms_curr_sprite_0
@second_sprite:
  lda ms_curr
  adc #1
  asl
  asl
  sta ms_curr_sprite_1
@return:
  rts
