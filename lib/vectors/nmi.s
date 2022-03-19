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
  ;
  lda ppu_update_status
  bne :+ ; ppu_update_status == 0 not ready to update PPU
    jmp @ppu_update_end
  :
  cmp #2 ; ppu_update_status == 2 turns rendering off
  bne :+
    ppu_render_off
    ppu_update_done
    jmp @ppu_update_end
  :
  oam_dump
  palettes_dump
  nametable_dump
@scroll:
  scroll_dump
  ppu_render_on
  ppu_update_done
@ppu_update_end:
  ; if this engine had music/sound, this would be a good place to play it
  ; unlock re-entry flag
  lda #0
  sta nmi_lock
@nmi_end:
  pull_registers
