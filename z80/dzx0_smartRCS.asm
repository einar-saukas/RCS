; -----------------------------------------------------------------------------
; "Smart" integrated RCS+ZX0 decoder by Einar Saukas (112 bytes)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_smartrcs:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, $80
dzx0r_literals:
        call    dzx0r_elias             ; obtain length
dzx0r_literals_loop:
        call    dzx0r_copy_byte         ; copy literals
        jp      pe, dzx0r_literals_loop
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0r_new_offset
        call    dzx0r_elias             ; obtain length
dzx0r_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
dzx0r_copy_loop:
        push    hl                      ; copy from offset
        ex      de, hl
        call    dzx0r_convert
        ex      de, hl
        call    dzx0r_copy_byte
        pop     hl
        inc     hl
        jp      pe, dzx0r_copy_loop
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0r_literals
dzx0r_new_offset:
        pop     bc                      ; discard last offset
        ld      c, $fe                  ; prepare negative offset
        call    dzx0r_elias_loop        ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0r_elias_backtrack
        inc     bc
        jr      dzx0r_copy
dzx0r_elias:
        inc     c                       ; interlaced Elias gamma coding
dzx0r_elias_loop:
        add     a, a
        jr      nz, dzx0r_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0r_elias_skip:
        ret     c
dzx0r_elias_backtrack:
        add     a, a
        rl      c
        rl      b
        jr      dzx0r_elias_loop
dzx0r_copy_byte:
        push    de                      ; preserve destination
        call    dzx0r_convert           ; convert destination
        ldi                             ; copy byte
        pop     de                      ; restore destination
        inc     de                      ; update destination
        ret
; Convert an RCS address 010RRccc ccrrrppp to screen address 010RRppp rrrccccc
dzx0r_convert:
        ex      af, af'
        ld      a, d                    ; A = 010RRccc
        cp      $58
        jr      nc, dzx0r_skip
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
dzx0r_skip:
        ex      af, af'
        ret
; -----------------------------------------------------------------------------
