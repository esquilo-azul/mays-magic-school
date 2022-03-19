; Reference: https://www.nesdev.org/wiki/INES#iNES_file_format

; Others: https://www.nesdev.org/wiki/Mapper#iNES_1.0_mapper_grid
INES_MAPPER_NROM = 0
INES_MAPPER_DEFAULT = INES_MAPPER_NROM

INES_MIRROR_HORIZONTAL = 0
INES_MIRROR_VERTICAL = 1
INES_MIRROR_DEFAULT = INES_MIRROR_HORIZONTAL

INES_SRAM_ABSENT = 0
INES_SRAM_PRESENT = 1 ; Battery backed SRAM at $6000-7FFF.
INES_SRAM_DEFAULT = INES_SRAM_ABSENT

INES_MAPPER = INES_MAPPER_DEFAULT
INES_MIRROR = INES_MIRROR_DEFAULT
INES_SRAM = INES_SRAM_DEFAULT