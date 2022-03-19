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

.macro nmi_jump_ppu_update_if_off jump_to
  lda ppu_update_status
  beq jump_to
  cmp #PPU_UPDATE_STATUS_OFF ; ppu_update_status == 2 turns rendering off
  bne :+
    ppu_render_off
    ppu_update_done
    jmp jump_to
  :
.endmacro

.segment "CODE"

nmi:
  nmi_lockable_start
  nmi_jump_ppu_update_if_off @ppu_update_end
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
