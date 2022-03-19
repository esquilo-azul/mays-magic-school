.macro nmi_lock_write lock_value
  lda #lock_value
  sta nmi_lock
.endmacro

.macro nmi_lockable_start
  push_registers
  lda nmi_lock
  beq :+
    jmp @nmi_end
  :
  nmi_lock_write 1
.endmacro

.macro nmi_lockable_end
  ; unlock re-entry flag
  nmi_lock_write 0
@nmi_end:
  pull_registers
.endmacro

.segment "CODE"

nmi:
  nmi_lockable_start
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
  nmi_lockable_end
