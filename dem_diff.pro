PRO DEM_DIFF, CUTOUT=cutout, PLOT=plot, _EXTRA=_extra
    d1 = DEMLOAD(TEMPS=t1, H_ERR=h1, V_ERR=v1)
    d2 = DEMLOAD(TEMPS=t2, H_ERR=h2, V_ERR=v2)

    IF d1 EQ !NULL OR d2 EQ !NULL THEN RETURN

    dem = d1 - d2
    s_x = h1 + h2
    s_y = v1 + v2

    IF KEYWORD_SET(plot) THEN BEGIN
        IF NOT KEYWORD_SET(cutout) THEN BEGIN
            cutout = [0,0,0,0]
            READ, cutout, PROMPT='Please enter the cutout area [x0,x1,y0,y1]: '
        ENDIF

        data = AVERAGE(dem[cutout[0]:cutout[1], cutout[2]:cutout[3], *], [1,2])
        s_x  = AVERAGE(s_x[cutout[0]:cutout[1], cutout[2]:cutout[3], *], [1,2])
        s_y  = AVERAGE(s_y[cutout[0]:cutout[1], cutout[2]:cutout[3], *], [1,2])

        x = get_edges(alog10(t1), /mean)

        ; PLOT
        PLOTERR, x, dem, s_x, s_y, _EXTRA=_extra
    ENDIF
END