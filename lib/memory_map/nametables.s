.segment "ZEROPAGE"
nmt_update_len: .res 1 ; number of bytes in nmt_update buffer

.segment "BSS"
nmt_update: .res 256 ; nametable update entry buffer for PPU update
