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
.include "lib/ppu.s"
.include "lib/metasprites_types.s"
.include "lib/metasprites.s"
.include "lib/cursor.s"
.include "lib/background.s"

;
; iNES header
;

.segment "HEADER"

nes_header

;
; CHR ROM
;

.segment "TILES"
.incbin "background.chr"
.incbin "sprite.chr"

;
; vectors placed at top 6 bytes of memory area
;

.segment "VECTORS"
.word nmi
.word reset
.word irq

;
; reset routine
;

.segment "CODE"
reset:
  nes_reset
  jmp main

;
; nmi routine
;

.segment "ZEROPAGE"
nmi_lock:       .res 1 ; prevents NMI re-entry
nmi_count:      .res 1 ; is incremented every NMI
nmi_ready:      .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI
nmt_update_len: .res 1 ; number of bytes in nmt_update buffer
scroll_x:       .res 1 ; x scroll position
scroll_y:       .res 1 ; y scroll position
scroll_nmt:     .res 1 ; nametable select (0-3 = $2000,$2400,$2800,$2C00)

.segment "BSS"
nmt_update: .res 256 ; nametable update entry buffer for PPU update
palette:    .res 32  ; palette buffer for PPU update

.segment "CODE"
nmi:
  push_registers
  ; prevent NMI re-entry
  lda nmi_lock
  beq :+
    jmp @nmi_end
  :
  lda #1
  sta nmi_lock
  ; increment frame counter
  inc nmi_count
  ;
  lda nmi_ready
  bne :+ ; nmi_ready == 0 not ready to update PPU
    jmp @ppu_update_end
  :
  cmp #2 ; nmi_ready == 2 turns rendering off
  bne :+
    lda #%00000000
    sta PPUMASK
    ldx #0
    stx nmi_ready
    jmp @ppu_update_end
  :
  oam_dma
  ; palettes
  lda #%10101000
  sta PPUCTRL ; set horizontal nametable increment
  lda PPUSTATUS
  lda #$3F
  sta PPUADDR
  stx PPUADDR ; set PPU address to $3F00
  ldx #0
  :
    lda palette, X
    sta PPUDATA
    inx
    cpx #32
    bcc :-
  ; nametable update
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
@scroll:
  lda scroll_nmt
  and #%00000011 ; keep only lowest 2 bits to prevent error
  ora #%10101000
  sta PPUCTRL
  lda scroll_x
  sta PPUSCROLL
  lda scroll_y
  sta PPUSCROLL
  ; enable rendering
  lda #%00011110
  sta PPUMASK
  ; flag PPU update complete
  ldx #0
  stx nmi_ready
@ppu_update_end:
  ; if this engine had music/sound, this would be a good place to play it
  ; unlock re-entry flag
  lda #0
  sta nmi_lock
@nmi_end:
  pull_registers

;
; irq
;

.segment "CODE"
irq:
  rti

;
; main
;

.segment "RODATA"
example_palette:
.include "lib/palettes.s"

.segment "ZEROPAGE"
temp_x:   .res 1
temp_y:   .res 1

.segment "CODE"
main:
  ; setup
  for_x_asc_start
    lda example_palette, X
    sta palette, X
  for_x_asc_end #32
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
  joy1_down KEY_START, push_start
  joy1_release KEY_START, release_start ; releasing start restores scroll
  joy1_down KEY_UP, move_cursor_up
  joy1_down KEY_DOWN, move_cursor_down
  joy1_down KEY_LEFT, move_cursor_left
  joy1_down KEY_RIGHT, move_cursor_right
  joy1_down KEY_SELECT, push_select
  joy1_down KEY_B, push_b
  joy1_down KEY_A, push_a
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

push_start:
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

release_start:
  lda #0
  sta scroll_x
  sta scroll_y
  sta scroll_nmt
  rts

push_b:
  jsr snap_cursor
  lda cursor_x
  lsr
  lsr
  lsr
  tax ; X = cursor_x / 8
  lda cursor_y
  lsr
  lsr
  lsr
  tay ; Y = cursor_y / 8
  lda #4
  jmp ppu_update_tile ; puts tile 4 at X/Y

push_a:
  jsr snap_cursor
  lda cursor_x
  lsr
  lsr
  lsr
  sta temp_x ; cursor_x / 8
  lda cursor_y
  lsr
  lsr
  lsr
  sta temp_y ; cursor_y / 8
  ; draw a ring of 8 tiles around the cursor
  dec temp_x ; x-1
  dec temp_y ; y-1
  ldx temp_x
  ldy temp_y
  lda #5
  jsr ppu_update_tile
  inc temp_x ; x
  ldx temp_x
  ldy temp_y
  lda #6
  jsr ppu_update_tile
  inc temp_x ; x+1
  ldx temp_x
  ldy temp_y
  lda #5
  jsr ppu_update_tile
  dec temp_x
  dec temp_x ; x-1
  inc temp_y ; y
  ldx temp_x
  ldy temp_y
  lda #6
  jsr ppu_update_tile
  inc temp_x
  inc temp_x ; x+1
  ldx temp_x
  ldy temp_y
  lda #6
  jsr ppu_update_tile
  dec temp_x
  dec temp_x ; x-1
  inc temp_y ; y+1
  ldx temp_x
  ldy temp_y
  lda #5
  jsr ppu_update_tile
  inc temp_x ; x
  ldx temp_x
  ldy temp_y
  lda #6
  jsr ppu_update_tile
  inc temp_x ; x+1
  ldx temp_x
  ldy temp_y
  lda #5
  jmp ppu_update_tile
  rts

;
; end of file
;
