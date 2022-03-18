.segment "BSS"
palette:    .res 32  ; palette buffer for PPU update

.segment "RODATA"

example_palette:
.include "../palettes.s"
