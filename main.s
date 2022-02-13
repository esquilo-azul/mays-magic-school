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
.include "lib/metasprites.s"
.include "lib/gamepad.s"
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
  sei       ; mask interrupts
  lda #0
  sta PPUCTRL ; disable NMI
  sta PPUMASK ; disable rendering
  sta $4015 ; disable APU sound
  sta $4010 ; disable DMC IRQ
  lda #$40
  sta $4017 ; disable APU IRQ
  cld       ; disable decimal mode
  ldx #$FF
  txs       ; initialize stack
  ; wait for first vblank
  bit PPUSTATUS
  vblank_wait
  ; clear all RAM to 0
  ram_clear
  ; place all sprites offscreen at Y=255
  lda #255
  ldx #0
  :
    sta oam, X
    inx
    inx
    inx
    inx
    bne :-
  ; wait for second vblank
  vblank_wait
  ; NES is initialized, ready to begin!
  ; enable the NMI for graphical updates, and jump to our main program
  lda #%10101000
  sta PPUCTRL
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
.byte $0F,$15,$26,$37 ; bg0 purple/pink
.byte $0F,$09,$19,$29 ; bg1 green
.byte $0F,$01,$11,$21 ; bg2 blue
.byte $0F,$00,$10,$30 ; bg3 greyscale
.byte $0F,$18,$28,$38 ; sp0 yellow
.byte $0F,$14,$24,$34 ; sp1 purple
.byte $0F,$1B,$2B,$3B ; sp2 teal
.byte $0F,$12,$22,$32 ; sp3 marine

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
  ; center the cursor
  lda #128
  sta cursor_x
  lda #120
  sta cursor_y
  ; show the screen
  jsr update_cursor
  jsr ppu_update
  ; main loop
@loop:
  ; read gamepad
  jsr gamepad_poll
  ; respond to gamepad state
  lda gamepad
  and #PAD_START
  beq :+
    jsr push_start
    jmp @draw ; start trumps everything, don't check other buttons
  :
  jsr release_start ; releasing start restores scroll
  lda gamepad
  and #PAD_U
  beq :+
    jsr move_cursor_up
  :
  lda gamepad
  and #PAD_D
  beq :+
    jsr move_cursor_down
  :
  lda gamepad
  and #PAD_L
  beq :+
    jsr push_l
  :
  lda gamepad
  and #PAD_R
  beq :+
    jsr push_r
  :
  lda gamepad
  and #PAD_SELECT
  beq :+
    jsr push_select
  :
  lda gamepad
  and #PAD_B
  beq :+
    jsr push_b
  :
  lda gamepad
  and #PAD_A
  beq :+
    jsr push_a
  :
@draw:
  ; draw everything and finish the frame
  jsr update_cursor
  jsr ppu_update
  ; keep doing this forever!
  jmp @loop

push_l:
  dec cursor_x
  rts

push_r:
  inc cursor_x
  rts

push_select:
  ; turn off rendering so we can manually update entire nametable
  jsr ppu_off
  jsr setup_background
  ; wait for user to release select before continuing
  :
    jsr gamepad_poll
    lda gamepad
    and #PAD_SELECT
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
  jsr ppu_update_tile ; puts tile 4 at X/Y
  rts

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
  jsr ppu_update_tile
  rts

;
; end of file
;
