; -----------------------------------------------------------------------------
; "Smart" integrated RCS+ZXX decoder by Einar Saukas (121 bytes) - BACKWARDS
; -----------------------------------------------------------------------------
; Parameters:
;   HL: last source address (compressed data)
;   DE: last destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_smartrcs_back:
        ld      bc, 1                   ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxrb_literals:
        call    dzxxrb_elias            ; obtain length
dzxxrb_literals_loop:
        call    dzxxrb_copy_byte        ; copy literals
        jp      pe, dzxxrb_literals_loop
        call    dzxxrb_next_bit         ; copy from last offset or new offset?
        jr      c, dzxxrb_new_offset
        call    dzxxrb_elias            ; obtain length
dzxxrb_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
dzxxrb_copy_loop:
        push    hl                      ; copy from offset
        ex      de, hl
        call    dzxxrb_convert
        ex      de, hl
        call    dzxxrb_copy_byte
        pop     hl
        dec     hl
        jp      pe, dzxxrb_copy_loop
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        call    dzxxrb_next_bit         ; copy from literals or new offset?
        jr      nc, dzxxrb_literals
dzxxrb_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxrb_elias_carry      ; obtain offset MSB
        ret     nz                      ; check end marker
        dec     c                       ; adjust for positive offset
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        dec     hl
        inc     bc
        push    bc                      ; preserve new offset
        call    dzxxrb_elias_carry      ; obtain length
        inc     bc
        jr      dzxxrb_copy
dzxxrb_elias:
        scf                             ; Elias gamma coding
dzxxrb_elias_carry:
        ld      bc, 0
dzxxrb_elias_size:
        rr      b
        rr      c
        call    dzxxrb_next_bit
dzxxrb_elias_backtrack:
        jr      nc, dzxxrb_elias_size
dzxxrb_elias_value:
        call    nc, dzxxrb_next_bit
        rl      c
        rl      b
        jr      nc, dzxxrb_elias_value
        ret
dzxxrb_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        dec     hl
        rla
        ret
dzxxrb_copy_byte:
        push    de                      ; preserve destination
        call    dzxxrb_convert          ; convert destination
        ldd                             ; copy byte
        pop     de                      ; restore destination
        dec     de                      ; update destination
        ret

; Convert an RCS address 010RRccc ccrrrppp to screen address 010RRppp rrrccccc
; (note: replace both EX AF,AF' with PUSH AF/POP AF if you want to preserve AF')
dzxxrb_convert:
        ex      af, af'
        ld      a, d                    ; A = 010RRccc
        cp      $58
        jr      nc, dzxxrb_skip
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
dzxxrb_skip:
        ex      af, af'
        ret
; -----------------------------------------------------------------------------
