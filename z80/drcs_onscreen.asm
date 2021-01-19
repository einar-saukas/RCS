; -----------------------------------------------------------------------------
; RCS on-screen decoder by Einar Saukas & Antonio Villena (58 bytes)
; -----------------------------------------------------------------------------
; No parameters needed.
; -----------------------------------------------------------------------------

; Decode starting at upper sector (0), middle sector (1), or lower sector (2)
FIRST_SECTOR    EQU   0

; Decode until upper sector (0), middle sector (1), or lower sector (2)
LAST_SECTOR     EQU   2

drcs_onscreen:
        ld      b, $02
drcs_next:
        ld      de, 256*(FIRST_SECTOR*8+64)+1
drcs_loop:
        ld      h, d
        ld      a, e
        djnz    drcs_conv2 ; in first pass, skip first conversion

; In second pass, convert from format DA = x0x1x0R1R2c1c2c5 r1c3c4p1p2r2r3p3
;                           to format HA = x0x1x0R1R2p1p2r2 r3p3r1c3c4c1c2c5
        rrca               ; A = p3r1c3c4p1p2r2r3
        rrca               ; A = r3p3r1c3c4p1p2r2
        ld      c, a       ; C = r3p3r1c3c4p1p2r2
        xor     d
        and     $07
        xor     d          ; A = x0x1x0R1R2p1p2r2
        ld      h, a       ; H = x0x1x0R1R2p1p2r2
        xor     d
        xor     c          ; A = r3p3r1c3c4c1c2c5

; In first pass, convert from RCS format HA = x0x1x0R1R2c1c2c3 c4c5r1r2r3p1p2p3
;                              to format HL = x0x1x0R1R2c1c2c5 r1c3c4p1p2r2r3p3
; In second pass, convert from format HA = x0x1x0R1R2p1p2r2 r3p3r1c3c4c1c2c5
;            to regular screen format HL = x0x1x0R1R2p1p2p3 r1r2r3c1c2c3c4c5
drcs_conv2:
        ld      l, a      ; L = r3p3r1c3c4c1c2c5
        rlca              ; A = p3r1c3c4c1c2c5r3
        rrc     h         ; H = r2x0x1x0R1R2p1p2 (r2 to carry)
        rla               ; A = r1c3c4c1c2c5r3r2 (p3 to carry)
        rl      h         ; H = x0x1x0R1R2p1p2p3
        ld      c, a      ; C = r1c3c4c1c2c5r3r2
        xor     l
        and     $05
        xor     l         ; A = r3p3r1c3c4c5c2r2
        rrca              ; A = r2r3p3r1c3c4c5c2
        rrca              ; A = c2r2r3p3r1c3c4c5
        xor     c
        and     $67
        xor     c         ; A = r1r2r3c1c2c3c4c5
        ld      l, a      ; L = r1r2r3c1c2c3c4c5

; In-place byte swap permutation
        sbc     hl, de    ; HL < DE ?
        jr      nc, drcs_skip ; skip otherwise
        add     hl, de
        ld      c, (hl)   ; swap contents (HL) and (DE)
        ld      a, (de)
        ld      (hl), a
        ld      a, c
        ld      (de), a
drcs_skip:
        inc     b         ; djnz adjust
        inc     de        ; next address
        ld      a, d
        cp      LAST_SECTOR*8+72
        jr      nz, drcs_loop ; process next address
        djnz    drcs_next ; process next pass
        ret

; -----------------------------------------------------------------------------
