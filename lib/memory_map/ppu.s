.segment "ZEROPAGE"

ppu_update_status: .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI
