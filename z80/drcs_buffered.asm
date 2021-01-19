; -----------------------------------------------------------------------------
; RCS buffered decoder by Einar Saukas (38 bytes)
; RCS decoder from buffer to regular screen
; -----------------------------------------------------------------------------
; Parameters:
;   HL: buffer address (RCS data)
; -----------------------------------------------------------------------------

drcs_buffered:
        ld      de, $4800
drcs_next_row_or_col:
        ld      a, d
        sub     8
        ld      d, a
drcs_next_sector:
        ld      b, 8
drcs_next_line:
        ld      a, (hl)
        inc     hl
        ld      (de), a
        inc     d                       ; next pixel line
        djnz    drcs_next_line
        ld      a, e
        add     a, 32                   ; next row
        ld      e, a
        jr      nc, drcs_next_row_or_col
        inc     e                       ; next column
        bit     5, e
        jr      z, drcs_next_row_or_col
        ld      e, b
        ld      a, d
        cp      $58                     ; finished bitmap area?
        jr      nz, drcs_next_sector
        ld      bc, 768
        ldir                            ; copy attributes
        ret

; -----------------------------------------------------------------------------
