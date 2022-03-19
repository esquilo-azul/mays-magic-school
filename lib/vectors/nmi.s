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
    lda #%00000000
    sta PPUMASK
    ldx #PPU_UPDATE_STATUS_DONE
    stx ppu_update_status
    jmp @ppu_update_end
  :
  oam_dump
  palettes_dump
  nametable_dump
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
  ldx #PPU_UPDATE_STATUS_DONE
  stx ppu_update_status
@ppu_update_end:
  ; if this engine had music/sound, this would be a good place to play it
  ; unlock re-entry flag
  lda #0
  sta nmi_lock
@nmi_end:
  pull_registers
