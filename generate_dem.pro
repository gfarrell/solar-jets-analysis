; NAME:
;   GENERATE_DEM
;
; PURPOSE:
;   Generates DEM emissions.
;   Resamples using FREBIN before computation.
;   Uses IGH's DEMMAP library to generate DEM.
;
;   For speed the procedure caches the last parameters (auto-detects change)
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; OPTIONAL INPUTS:
;   FAINT      flag     relaxes SNR tolerance and forces /doallpix for faint phenomena.
;   FORCE_GEN  flag     forces DEM map regeneration
;   TEMP_INT   number   the interval between temperatures (in log10 space), 'igh' for original
;   TEMP_LOW   number   the lower bound for the temperature in log10 space
;   TEMP_HI    number   the upper bound for the temperature in log10 space
;   BIN_SIZE   integer  size of the bins in pixels (x = x/bin_size, etc.)
;   SAVE       string   save the DEM parameters and results in a non-standard file
;
PRO GENERATE_DEM, FAINT=faint, FORCE_GEN=regenerate, TEMP_INT=ti, TEMP_LOW=t_low, TEMP_HI=t_hi, BIN_SIZE=bin_size, BIN_RADIUS=bin_radius, X=x, Y=y, SAVE=save, EVENT=event, _extra=_extra
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; Configure paths
    CONFIGURATOR, DATA_DIR=eventsDir, DEMMAP_DIR=lib

    ; DEM dir (where DEM MAPS are saved)
    demDir = 'dem'

    ; Plots dir (where any output images will be saved)
    imgDir = 'plots'

    ; The minimum window size for image display
    minsize = 512

    ; The colour we should use for drawing our axis arrows
    aCol='FFF'x

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Set variable defaults
    IF NOT KEYWORD_SET(regenerate)  THEN regenerate = !NULL
    IF NOT KEYWORD_SET(bin_size)    THEN bin_size   = 1
    IF NOT KEYWORD_SET(ti)          THEN ti         = 0.15
    IF NOT KEYWORD_SET(t_low)       THEN t_low      = 5.6
    IF NOT KEYWORD_SET(t_hi)        THEN t_hi       = 7.55
    IF NOT KEYWORD_SET(faint)       THEN faint      = 0

    ; Temperatures along the x-axis
    IF STRTRIM(ti,2) EQ 'igh' THEN BEGIN
        temps = [0.5,1,1.5,2,3,4,6,8,11,14,19,25,32]*10^6 ; original to igh
    ENDIF ELSE BEGIN
        t = t_low
        temps = [t]
        WHILE t LE t_hi DO BEGIN
            t = t + ti
            temps = [temps, t]
        ENDWHILE
        temps = 10^temps
    ENDELSE
    
    ; Load snapshot data
    data = DLoad(SEARCH='_composite', EVENT=event, FILE=file)

    ; Plots dir setup
    imgDir = eventsDir + '/' + event + '/' + imgDir
    IF NOT FILE_TEST(imgDir) THEN FILE_MKDIR, imgDir

    ; Check to see if we've already generated DEM map
    demDir = eventsDir + '/' + event + '/' + demDir
    IF NOT FILE_TEST(demDir) THEN FILE_MKDIR, demDir
    IF NOT KEYWORD_SET(save) THEN save = FILE_BASENAME(file)
    demFile = demDir + '/' + save

    ; Store original values (that the user has selected)
    ; We'll use this in comparing with the restored data to check if we should regen
    o_faint     = faint
    o_bin_size  = bin_size
    o_ti        = ti
    o_t_low     = t_low
    o_t_hi      = t_hi
    o_temps     = temps
    o_data      = data  ; this is used for image display later

    ; If it exists, restore the saved data
    IF FILE_TEST(demFile) THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Restoring data from ' + demFile + '...'
        RESTORE, demFile
    ENDIF ELSE regenerate = 1

    ; If FORCE_GEN isn't set, then we have to do some comparisons
    ; this checks if our data matches our settings
    IF regenerate EQ !NULL THEN BEGIN
        IF o_bin_size NE bin_size THEN regenerate = 1 $
        ELSE IF NOT ARRAY_EQUAL(o_temps, temps) THEN regenerate = 1 $
        ELSE IF o_faint NE faint THEN regenerate = 1
    ENDIF

    ; Copy our settings back
    faint       = o_faint
    bin_size    = o_bin_size
    ti          = o_ti
    t_low       = o_t_low
    t_hi        = o_t_hi
    temps       = o_temps

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
            new_data   = FREBIN(data[i].data, rx, ry, /TOTAL)

            new_map    = rem_tag(data[i], 'DATA')
            new_map    = add_tag(new_map, new_data, 'DATA')

            new_map.dx = new_map.dx * bin_size
            new_map.dy = new_map.dy * bin_size

            IF i EQ 0 THEN maps = new_map ELSE maps = [maps, new_map]
        ENDFOR

        data = maps
    ENDIF

    IF regenerate NE !NULL THEN BEGIN        
        ; generate DEM
        ; DEM stored in dem
        ; vertical error in v_err
        ; horizontal error in h_err
        cd, lib, CURRENT=prev_wd
        IF faint THEN BEGIN
            MESSAGE, /INFORMATIONAL, 'Generating DEMMAP (faint)'
            dn2dem_map_pos, data, dem, edem=v_err, elogt=h_err, nbridges=4, temps=temps, err_max=1
            ; if this still doesn't work try /doallpix
        ENDIF ELSE BEGIN
            MESSAGE, /INFORMATIONAL, 'Generating DEMMAP'
            dn2dem_map_pos, data, dem, edem=v_err, elogt=h_err, nbridges=4, temps=temps
        ENDELSE

        cd, prev_wd

        ; save
        MESSAGE, /INFORMATIONAL, 'Saving dem file in ' + demFile + '.'
        SAVE, dem, faint, temps, ti, v_err, h_err, bin_size, FILENAME=demFile
    ENDIF
END