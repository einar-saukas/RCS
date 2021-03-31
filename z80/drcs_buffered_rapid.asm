; -----------------------------------------------------------------------------
; "Rapid" RCS buffered decoder by Einar Saukas (38 bytes)
; RCS decoder from buffer to regular screen
; -----------------------------------------------------------------------------
; Parameters:
;   HL: buffer address (RCS data)
; -----------------------------------------------------------------------------

drcs_buffered_rapid:
        ld      de, $4800
        ld      c, 8
drcsr_next_row_or_col:
        ld      a, d
        sub     c
        ld      d, a
drcsr_next_sector:
        ld      b, c
drcsr_next_line:
        ld      a, (hl)
        inc     hl
        ld      (de), a
        inc     d                       ; next pixel line
        djnz    drcsr_next_line
        ld      a, e
        add     a, 32                   ; next row
        ld      e, a
        jr      nc, drcsr_next_row_or_col
        inc     e                       ; next column
        bit     5, e
        jr      z, drcsr_next_row_or_col
        ld      e, b
        ld      a, d
        cp      $58                     ; finished bitmap area?
        jr      nz, drcsr_next_sector
        ld      bc, 768
        ldir                            ; copy attributes
        ret
; -----------------------------------------------------------------------------
