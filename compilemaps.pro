FUNCTION CompileMaps, event, FILTERS=filters
    ; Compiles a group of filters for a given event
    ; Produces an ordered array

    
    IF NOT KEYWORD_SET(filters) THEN filters = [94, 131, 171, 193, 211, 335]

    c = N_ELEMENTS(filters)

    FOR i = 0, c-1 DO BEGIN
        f_map = DLoad(EVENT=event, SEARCH='full_' + STRTRIM(filters[i], 2))
        
        ; sub map the non-0th maps
        IF i EQ 0 THEN BEGIN
            sub_map, f_map, s_map, REF_MAP=f_map, IRANGE=irange
            maps = [f_map]
        ENDIF ELSE BEGIN
            sub_map, f_map, s_map, xrange=irange[0:1], yrange=irange[2:3]
            maps = [maps, s_map]
        ENDELSE
    ENDFOR

    RETURN, maps
END