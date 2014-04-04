PRO ATTENUATE_DEM, dem, v_err
    m = MAX(dem)

    dem   = (dem   / m) * 100
    v_err = (v_err / m) * 100

    MESSAGE, /INFORMATIONAL, 'Max DEM now '+STRTRIM(MAX(dem),2)+'.'
    MESSAGE, /INFORMATIONAL, 'Max V_ERR now '+STRTRIM(MAX(v_err),2)+'.'
END