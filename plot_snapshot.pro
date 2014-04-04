PRO PLOT_SNAPSHOT, REBIN=r
    LOADCT,3

    data = DLOAD()
    d = data[2]

    IF KEYWORD_SET(r) THEN BEGIN
        sz = SIZE(d.DATA)
        rx = sz[1]/r
        ry = sz[2]/r

        new_data   = FREBIN(d.data, rx, ry, /TOTAL)

        new_map    = rem_tag(d, 'DATA')
        new_map    = add_tag(new_map, new_data, 'DATA')

        new_map.dx = new_map.dx * r
        new_map.dy = new_map.dy * r

        d = new_map
    END

    MESSAGE, /INFORMATIONAL, 'Plotting 171Å...'
    PLOT_IMAGE, d.DATA
END