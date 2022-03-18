MS_MAX_COUNT = 16

MS_FACE_UP = 0
MS_FACE_RIGHT = 1
MS_FACE_DOWN = 2
MS_FACE_LEFT = 3

.segment "ZEROPAGE"

; Attibutes
ms_y: .res MS_MAX_COUNT
ms_x: .res MS_MAX_COUNT
ms_face: .res MS_MAX_COUNT
ms_metatile: .res MS_MAX_COUNT
ms_speed: .res MS_MAX_COUNT
ms_type: .res MS_MAX_COUNT
ms_curr: .res 1

; All metasprites have two sprites.
; The following labels marks the offset of each.
ms_curr_sprite_0: .res 1
ms_curr_sprite_1: .res 1
