; -----------------------------------------------------------------------------
; "Smart" integrated RCS+ZXX decoder by Einar Saukas (123 bytes)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_smartrcs:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxr_literals:
        call    dzxxr_elias             ; obtain length
dzxxr_literals_loop:
        call    dzxxr_copy_byte         ; copy literals
        jp      pe, dzxxr_literals_loop
        call    dzxxr_next_bit          ; copy from last offset or new offset?
        jr      c, dzxxr_new_offset
        call    dzxxr_elias             ; obtain length
dzxxr_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
dzxxr_copy_loop:
        push    hl                      ; copy from offset
        ex      de, hl
        call    dzxxr_convert
        ex      de, hl
        call    dzxxr_copy_byte
        pop     hl
        inc     hl
        jp      pe, dzxxr_copy_loop
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        call    dzxxr_next_bit          ; copy from literals or new offset?
        jr      nc, dzxxr_literals
dzxxr_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxr_elias_carry       ; obtain offset MSB
        ret     nz                      ; check end marker
        push    af                      ; adjust for negative offset
        xor     a
        sub     c
        ld      b, a
        pop     af
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        push    bc                      ; preserve new offset
        call    dzxxr_elias_carry       ; obtain length
        inc     bc
        jr      dzxxr_copy
dzxxr_elias:
        scf                             ; Elias gamma coding
dzxxr_elias_carry:
        ld      bc, 0
dzxxr_elias_size:
        rr      b
        rr      c
        call    dzxxr_next_bit
dzxxr_elias_backtrack:
        jr      nc, dzxxr_elias_size
dzxxr_elias_value:
        call    nc, dzxxr_next_bit
        rl      c
        rl      b
        jr      nc, dzxxr_elias_value
        ret
dzxxr_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
dzxxr_copy_byte:
        push    de                      ; preserve destination
        call    dzxxr_convert           ; convert destination
        ldi                             ; copy byte
        pop     de                      ; restore destination
        inc     de                      ; update destination
        ret

; Convert an RCS address 010RRccc ccrrrppp to screen address 010RRppp rrrccccc
; (note: replace both EX AF,AF' with PUSH AF/POP AF if you want to preserve AF')
dzxxr_convert:
        ex      af, af'
        ld      a, d                    ; A = 010RRccc
        cp      $58
        jr      nc, dzxxr_skip
        xor     e
        and     $f8
        xor     e                       ; A = 010RRppp
        push    af
        xor     d
        xor     e                       ; A = ccrrrccc
        rlca
        rlca                            ; A = rrrccccc
        pop     de                      ; D = 010RRppp
        ld      e, a                    ; E = rrrccccc
dzxxr_skip:
        ex      af, af'
        ret
; -----------------------------------------------------------------------------
