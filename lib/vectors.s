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

.include "nmi.s"

;
; irq
;

.segment "CODE"
irq:
  rti
