; -----------------------------------------------------------------------------
; "Compact" RCS buffered decoder by Arkannoyed & Einar Saukas (27 bytes)
; RCS decoder from buffer to regular screen
; -----------------------------------------------------------------------------
; Parameters:
;   HL: buffer address (RCS data)
; -----------------------------------------------------------------------------

drcs_buffered_compact:
        ld      bc, $4000               ; BC = 010RRccc ccrrrppp
drcsc_loop:
        ld      a, b                    ; A = 010RRccc
        cp      $5b                     ; finished attributes?
        ret     z
        cp      $58                     ; finished bitmaps?
        jr      nc, drcsc_skip
        xor     c
        and     $f8
        xor     c                       ; A = 010RRppp
        ld      d, a                    ; D = 010RRppp
        xor     b
        xor     c                       ; A = ccrrrccc
        rlca
        rlca                            ; A = rrrccccc
        ld      e, a                    ; E = rrrccccc
drcsc_skip:
        ldi
        inc     bc
        inc     bc
        jr      drcsc_loop
; -----------------------------------------------------------------------------
