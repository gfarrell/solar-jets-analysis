PRO AIA_PLOT_RESP
    RESTORE, '~/idl/lib/iain/demmap/aia_resp_chi.dat'

    cc = [2,1,0,3,4,6]
    ll = ['94','131','171','193','211','304', '335']
    cols = [[33,137,190], [80,33,190], [204,35,97], [228,125,40], [228,200,40], [126, 204, 35]]

    max_y = MAX(eff.all)
    min_y = MIN(eff.all)

    plot_title = 'AIA Response Curves'
    x_title    = 'Log(T/K)'
    y_title    = eff.units

    x = eff.logte

    FOR i=0, N_ELEMENTS(cc)-1 DO BEGIN
        j = cc[i]
        col = cols[j]
        t = ll[j]

        y = alog10(eff.all[*,j])

        IF i EQ 0 THEN BEGIN
            g = PLOT(x, y, TITLE=plot_title, MAX_VALUE=max_y, MIN_VALUE=min_y, OVERPLOT=op, AXIS_STYLE=1, XTITLE=x_title, YTITLE=y_title)
            
            g.COLOR=col

            gg=[g]
        ENDIF ELSE BEGIN
            g = PLOT(x, y, /OVERPLOT)
            g.COLOR=col
            gg = [gg, [g]]
        ENDELSE
    ENDFOR

END