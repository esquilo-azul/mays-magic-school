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
