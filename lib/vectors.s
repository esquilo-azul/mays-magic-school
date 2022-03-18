;
; vectors placed at top 6 bytes of memory area
;

.segment "VECTORS"
.word nmi
.word reset
.word irq

.include "vectors/reset.s"
.include "vectors/nmi.s"
.include "vectors/irq.s"
