FUNCTION DEM_SUM, dem
    sz = SIZE(dem)
    w = sz[1] ; image width
    h = sz[2] ; image height
    c = sz[3] ; fourth property will be the number of images

    d = FLTARR(w,h)

    FOR i=0,c-1 DO BEGIN
        FOR x=0,w-1 DO BEGIN
            FOR y=0,h-1 DO BEGIN
                d[x,y] = d[x,y] + dem[x,y,i]
            ENDFOR
        ENDFOR
    ENDFOR

    RETURN, d
END