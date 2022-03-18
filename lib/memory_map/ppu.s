PPU_UPDATE_STATUS_DONE = 0
PPU_UPDATE_STATUS_ON = 1
PPU_UPDATE_STATUS_OFF = 2

.segment "ZEROPAGE"

ppu_update_status: .res 1 ; set to 1 to push a PPU frame update, 2 to turn rendering off next NMI
