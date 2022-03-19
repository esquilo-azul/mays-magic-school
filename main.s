;
; example.s
; Brad Smith (rainwarrior), 4/06/2014
; http://rainwarrior.ca
;
; This is intended as an introductory example to NES programming with ca65.
; It covers the basic use of background, sprites, and the controller.
; This does not demonstrate how to use sound.
;
; This is not intended as a ready-made game. It is only a very minimal
; playground to assist getting started in NES programming. The idea here is
; to get you past the most difficult parts of a minimal NES program setup
; so that you can experiment from an almost blank slate.
;
; To use your own graphics, replace the two 4k tile banks provided.
; They are named "background.chr" and "sprite.chr".
;
; The reset and nmi routines are provided as a simple working example of
; these things. Writing these from scratch is a more advanced topic, so they
; will not be fully explained here.
;
; Under "drawing utilities" are some very primitive routines for working
; with the NES graphics. See the "main" section for examples of how to use them.
;
; Finally at the bottom you will find the "main" section that provides
; a small example program. A cursor is shown. Pressing the d-pad will move
;   - pressing the d-pad will move the cursor around the screen
;   - pressing B will draw a tile to the screen
;   - pressing A will draw several tiles to the screen
;   - pressing SELECT will reset the background
;   - holding START will demonstrate scrolling
;
; Please note that this example code is intended to be simple, not necessarily
; efficient. I have tried to avoid optimization in favour of easier to understand code.
;
; You may notice some odd behaviour when using the A button around the edges of the screen.
; I will leave it as an exercise for the curious to understand what is going on.
;

.include "eac-ca65-nes-lib/main.s"
.include "lib/memory_map.s"
.include "lib/palettes.s"
.include "lib/ppu.s"
.include "lib/nametables.s"
.include "lib/metasprites.s"
.include "lib/cursor.s"
.include "lib/background.s"
.include "lib/scroll.s"

;
; iNES header
;

nes_header INES_MAPPER_NROM, INES_MIRROR_VERTICAL, INES_SRAM_ABSENT

.include "lib/characters.s"
.include "lib/vectors.s"

;
; main
;

.segment "CODE"
main:
  ; setup
  jsr setup_background
  ; show the screen
  jsr ms_clear_all
  jsr init_cursor
  jsr ppu_update
  ; main loop
@loop:
  jsr metasprite_xy_to_cursor_xy
  jsr stop_cursor
  ; read joy1_current
  jsr joy1_poll
  ; respond to joy1_current state
  joy1_down KEY_START, scroll_bottom_right
  joy1_release KEY_START, reset_scroll ; releasing start restores scroll
  joy1_down KEY_UP, move_cursor_up
  joy1_down KEY_DOWN, move_cursor_down
  joy1_down KEY_LEFT, move_cursor_left
  joy1_down KEY_RIGHT, move_cursor_right
  joy1_down KEY_SELECT, push_select
  joy1_down KEY_B, draw_heart
  joy1_down KEY_A, draw_ring
@draw:
  ; draw everything and finish the frame
  jsr ms_process_all
  jsr ppu_update
  ; keep doing this forever!
  jmp @loop

push_select:
  ; turn off rendering so we can manually update entire nametable
  jsr ppu_off
  jsr setup_background
  ; wait for user to release select before continuing
  :
    jsr joy1_poll
    lda joy1_current
    and #KEY_SELECT
    bne :-
  rts

;
; end of file
;
