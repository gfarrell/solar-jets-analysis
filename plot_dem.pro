; NAME:
;   PLOT_DEM
;
; PURPOSE:
;   Plots a dem map for a snapshot of a particular event.
;   This can do a couple of interesting things:
;       - resamples original images PRE DEM creation
;       - averages over spatial area within DEM (otherwise choosing pixels can be a tad hit-and-miss)
;       - plots a graph of the temperature at a particular point/area
;       - saves composite images showing the area/point and the corresponding graph
;   For speed the procedure caches the last parameters (auto-detects change)
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; OPTIONAL INPUTS:
;   FORCE_GEN  flag     forces DEM map regeneration
;   TEMP_INT   number   the interval between temperatures (x1E6), 'igh' for original
;   BIN_SIZE   integer  size of the bins in pixels (x = x/bin_size, etc.)
;   BIN_RADIUS integer  the radius for DEM averaging (not raw binning)
;   X          integer  X pixel coordinate to examine
;   Y          integer  Y pixel coordinate to examine
;   SAVE       string   what to call the plot
;
PRO PLOT_DEM, FORCE_GEN=regenerate, TEMP_INT=ti, BIN_SIZE=bin_size, BIN_RADIUS=bin_radius, X=x, Y=y, SAVE=save, EVENT=event, _extra=_extra
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; Configure paths
    CONFIGURATOR, DATA_DIR=eventsDir, DEMMAP_DIR=lib

    ; DEM dir (where DEM MAPS are saved)
    demDir = 'dem'

    ; Plots dir (where any output images will be saved)
    imgDir = 'plots'

    ; Min/Max temp (x1E6)
    temp_min = 0.1
    temp_max = 20

    ; The minimum window size for image display
    minsize = 512

    ; The colour we should use for drawing our axis arrows
    aCol='FFF'x

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Set variable defaults
    IF NOT KEYWORD_SET(regenerate) then regenerate = !NULL
    IF NOT KEYWORD_SET(bin_size) then bin_size = 1
    IF NOT KEYWORD_SET(ti) THEN ti = !NULL

    ; Temperatures along the x-axis
    ; If no interval chosen, we'll use our default scale
    IF ti EQ !NULL THEN BEGIN
        ; default scale from logT=5.6 to logT=7.2
        ; 0.15 interval
        temps = 10^[5.6,5.75,5.9,6.05,6.20,6.35,6.5,6.65,6.8,6.95,7.1,7.25]
    ENDIF ELSE IF ti EQ 'igh' THEN BEGIN
        temps = [0.5,1,1.5,2,3,4,6,8,11,14,19,25,32]*10^6 ; original to igh
    ENDIF ELSE BEGIN
        ; Should be starting at around 0.5M K (0.5x10^6), ending at around 20M K (20x10^6)
        i = temp_min
        WHILE i LT temp_max DO BEGIN
            IF i EQ temp_min THEN temps = [i] ELSE temps = [temps, i]
            i = i + ti
        ENDWHILE
        temps = temps * 10^6
    ENDELSE
    
    ; Load snapshot data
    data = DLoad(SEARCH='_composite', EVENT=event, FILE=file)

    ; Plots dir setup
    imgDir = eventsDir + '/' + event + '/' + imgDir
    IF NOT FILE_TEST(imgDir) THEN FILE_MKDIR, imgDir

    ; Check to see if we've already generated DEM map
    demDir = eventsDir + '/' + event + '/' + demDir
    IF NOT FILE_TEST(demDir) THEN FILE_MKDIR, demDir
    demFile = demDir + '/' + FILE_BASENAME(file)

    ; Store original values (that the user has selected)
    ; We'll use this in comparing with the restored data to check if we should regen
    o_bin_size = bin_size
    o_ti       = ti
    o_temps    = temps
    o_data     = data  ; this is used for image display later

    ; If it exists, restore the saved data
    IF FILE_TEST(demFile) THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Restoring data from ' + demFile + '...'
        RESTORE, demFile
    ENDIF ELSE regenerate = 1

    ; If FORCE_GEN isn't set, then we have to do some comparisons
    ; this checks if our data matches our settings
    IF regenerate EQ !NULL THEN BEGIN
        IF o_bin_size NE bin_size THEN regenerate = 1 $
        ELSE IF NOT ARRAY_EQUAL(o_temps, temps) THEN regenerate = 1
    ENDIF

    ; Copy our settings back
    bin_size = o_bin_size
    ti       = o_ti
    temps    = o_temps

    ; Bin resampling
    IF bin_size NE !NULL AND bin_size GT 1 THEN BEGIN
        ; have to resample each map in the array
        ; should all have the same dims so only need to calc x,y once
        sz  = SIZE(data.data)
        rx  = sz[1]/bin_size
        ry  = sz[2]/bin_size

        MESSAGE, /INFORMATIONAL, 'Resampling ' + STRTRIM(sz[1],2) + 'x' + STRTRIM(sz[2],2) + ' by factor ' + STRTRIM(bin_size, 2) + '.'

        FOR i=0, N_ELEMENTS(data)-1 DO BEGIN
            MESSAGE, /INFORMATIONAL, '- Resampling '+data[i].ID
            new_data   = FREBIN(data[i].data, rx, ry)

            new_map    = rem_tag(data[i], 'DATA')
            new_map    = add_tag(new_map, new_data, 'DATA')

            new_map.dx = new_map.dx * bin_size
            new_map.dy = new_map.dy * bin_size

            IF i EQ 0 THEN maps = new_map ELSE maps = [maps, new_map]
        ENDFOR

        data = maps
    ENDIF

    IF regenerate NE !NULL THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Generating DEMMAP'
        
        ; generate DEM
        ; DEM stored in dem
        ; vertical error in v_err
        ; horizontal error in h_err
        cdd, lib, CURRENT=prev_wd
        dn2dem_map_pos, data, dem, edem=v_err, elogt=h_err, err_max=1, nbridges=4, temps=temps, /doallpix
        cdd, prev_wd

        ; save
        MESSAGE, /INFORMATIONAL, 'Saving dem file in ' + demFile + '.'
        SAVE, dem, temps, v_err, h_err, bin_size, FILENAME=demFile
    ENDIF

    ; log temperature x-axis
    logT0=get_edges(alog10(temps),/mean)

    ;;;;;;;;;;;;;;;;;;
    ;;; PROCESSING ;;;
    ;;;;;;;;;;;;;;;;;;

    IF x EQ !NULL OR y EQ !NULL THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Displaying 171Å'
        LOADCT, 3
        PLOT_IMAGE, data[2].DATA

        ; ask the user for X,Y coordinates to plot
        READ, x, PROMPT='Enter X coordinate (px): '
        READ, y, PROMPT='Enter Y coordinate (px): '
    ENDIF

    ; Now let's draw the image in its own window
    ; min window size should be 256
    ; NB using original data, not resampled, for display quality
    sz = SIZE(o_data[2].DATA)
    IF sz[1] LT sz[2] THEN win_scale = minsize/sz[1] ELSE win_scale = minsize/sz[2]
    
    win_x = win_scale * sz[1]
    win_y = win_scale * sz[2]

    IF bin_size NE !NULL THEN BEGIN
        pl_x = x * bin_size
        pl_y = y * bin_size
    ENDIF ELSE BEGIN
        pl_x = x
        pl_y = y
    ENDELSE
    pl_x = pl_x * win_scale
    pl_y = pl_y * win_scale

    ; Display the image
    WINDOW, 1, XSIZE=win_x, YSIZE=win_y
    EXPAND_TV, o_data[2].DATA, win_x, win_y, 0, 0
    
    ; Calculating DEM average binning in case it's desired
    IF bin_radius NE !NULL THEN BEGIN
        x0 = x - bin_radius
        x1 = x + bin_radius
        y0 = y - bin_radius
        y1 = y + bin_radius

        IF bin_size NE !NULL THEN BEGIN
            pl_x0 = x0 * bin_size
            pl_x1 = x1 * bin_size
            pl_y0 = y0 * bin_size
            pl_y1 = y1 * bin_size
        ENDIF

        pl_x0 = pl_x0 * win_scale
        pl_x1 = pl_x1 * win_scale
        pl_y0 = pl_y0 * win_scale
        pl_y1 = pl_y1 * win_scale

        ; point to our plotting location as a box
        ; x-axis
        ARROW, pl_x0, 0, pl_x0, win_y, hthick=0, hsize=0, thick=1, color=aCol
        ARROW, pl_x1, 0, pl_x1, win_y, hthick=0, hsize=0, thick=1, color=aCol
        ; y-axis
        ARROW, 0, pl_y0, win_x, pl_y0, hthick=0, hsize=0, thick=1, color=aCol
        ARROW, 0, pl_y1, win_x, pl_y1, hthick=0, hsize=0, thick=1, color=aCol
    ENDIF ELSE BEGIN
        ; point to our plotting location
        ; x-axis
        ARROW, pl_x, 0, pl_x, win_y, hthick=0, hsize=0, thick=1, color=aCol
        ; y-axis
        ARROW, 0, pl_y, win_x, pl_y, hthick=0, hsize=0, thick=1, color=aCol
    ENDELSE
    
    ; get the data
    TVLCT, R, G, B, /GET
    visual_location_image = TVRD()

    MESSAGE, /INFORMATIONAL, 'Plotting (finally...)'
    WINDOW, 0

    plot_title = data[2].TIME
    IF bin_size NE !NULL THEN plot_title = plot_title + ' BIN ' + STRTRIM(bin_size, 2)
    IF ti NE !NULL THEN plot_title = plot_title + ' TI ' + STRTRIM(ti, 2)

    IF bin_radius NE !NULL THEN BEGIN
        p_dem = AVERAGE(dem[x0:x1,y0:y1,*], [1,2])
        x_err = AVERAGE(h_err[x0:x1,y0:y1,*], [1,2])
        y_err = AVERAGE(v_err[x0:x1,y0:y1,*], [1,2])
    ENDIF ELSE BEGIN
        p_dem = dem[x,y,*]
        x_err = h_err[x,y,*]
        y_err = v_err[x,y,*]
    ENDELSE

    PLOTERR, logT0, p_dem, x_err, y_err, TITLE=plot_title, xtitle='Log10 of temperature', ytitle='counts', /NOHAT, THICK=2, ERRCOL='00FF00'x, _extra=_extra

    graph_image_data = TVRD()

    ; If requested, save
    IF save NE !NULL THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Saving images...'

        imgFile = imgDir + '/' + save + '_loc.png'
        pltFile = imgDir + '/' + save + '_graph.png'
        cmpFile = imgDir + '/' + save + '_composite.png'

        iSize = SIZE(visual_location_image)
        pSize = SIZE(graph_image_data)

        ; Now to write the composite image
        ; rescale loc to fit graph height
        lH = pSize[2]
        lW = iSize[1] * lH/iSize[2]
        WINDOW, 0, XSIZE=(lW+pSize[1]), YSIZE=lH
        EXPAND_TV, visual_location_image, lW, lH, 0, 0
        EXPAND_TV, graph_image_data, pSize[1], pSize[2], lW, 0

        WRITE_PNG, imgFile, visual_location_image, R, G, B
        WRITE_PNG, pltFile, graph_image_data
        WRITE_PNG, cmpFile, TVRD(), R, G, B
    ENDIF
END