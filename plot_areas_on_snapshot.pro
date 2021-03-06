PRO PLOT_AREAS_ON_SNAPSHOT, SCALE=scale, COLOUR=col
    s = DLOAD()

    IF s EQ !NULL THEN RETURN

    img = s[3].DATA ; 193 is clearest
    sz = SIZE(img)

    IF NOT KEYWORD_SET(scale) THEN scale = 8.0
    IF NOT KEYWORD_SET(col)   THEN col   = 'FFF'x

    w = sz[1]*scale
    h = sz[2]*scale

    WINDOW, 1, XSIZE=w, YSIZE=h

    EXPAND_TV, img, w, h, 0, 0

    thickness = 1.0 + (scale / 6.0)

    ; Draw Arrows
    WHILE 1 DO BEGIN
        ; Ask if we want to go ahead
        cont = 'n'
        READ, cont, PROMPT='Do you want to draw a box? (y/n)'
        IF cont EQ 'n' THEN BREAK

        ; Ask for box area
        cutout = [0,0,0,0]
        READ, cutout, PROMPT='Please enter the cutout area [x0,x1,y0,y1]: '

        cutout = cutout * scale

        ; x0
        ARROW, cutout[0], cutout[2], cutout[0], cutout[3], COLOR=col, THICK=thickness, HSIZE=0
        ; x1
        ARROW, cutout[1], cutout[2], cutout[1], cutout[3], COLOR=col, THICK=thickness, HSIZE=0
        ; y0
        ARROW, cutout[0], cutout[2], cutout[1], cutout[2], COLOR=col, THICK=thickness, HSIZE=0
        ; y1
        ARROW, cutout[0], cutout[3], cutout[1], cutout[3], COLOR=col, THICK=thickness, HSIZE=0
    ENDWHILE
END