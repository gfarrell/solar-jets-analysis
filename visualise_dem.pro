; NAME:
;   VISUALISE_DEM
;
; PURPOSE:
;   Lets us visualise our DEM as images
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; OPTIONAL INPUTS:
;   EVENT
;   SCALE
;   ALL
;
PRO VISUALISE_DEM, EVENT=event, SCALE=scale, TEMPS=chosen_temps, COMBINE=combine, _EXTRA=_extra
    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Load the DEM
    dem = DEMLOAD(EVENT=event, TEMPS=temps)

    ; Default scale is 1
    IF NOT KEYWORD_SET(scale) THEN scale = 1

    IF KEYWORD_SET(COMBINE) THEN BEGIN
        data = AVERAGE(dem, 3)

        ; Create a window
        sz = SIZE(data)*scale
        WINDOW,0,XSIZE=sz[1],YSIZE=sz[2]

        ; Output
        EXPAND_TV, data, sz[1], sz[2], 0, 0
    ENDIF ELSE BEGIN
        ; If temperatures not chosen, interactivity allow user to add temps
        IF NOT KEYWORD_SET(chosen_temps) THEN BEGIN
            j = 0
            choice = 0
            WHILE choice NE !NULL DO BEGIN
                ; Ask for a temperature
                PRINT, 'Temperature bins available:'
                FOR i=0,N_ELEMENTS(temps)-1 DO PRINT, STRTRIM(i+1,2) + ') ' + STRTRIM(temps[i], 2)
                choice = PromptChoice(N_ELEMENTS(temps))

                IF choice NE !NULL THEN BEGIN
                    choice = choice -1
                    IF j EQ 0 THEN chosen_temps = [temps[choice]] ELSE chosen_temps = [chosen_temps, temps[choice]]

                    IF j EQ 0 THEN choices = [choice] ELSE choices = [choices, choice]
                ENDIF

                j = j + 1
            ENDWHILE
            
            IF N_ELEMENTS(choices) EQ 0 THEN RETURN
        ENDIF ELSE BEGIN
            ; Get our temperature choices as indices
            FOR i = 0, N_ELEMENTS(chosen_temps)-1 DO BEGIN
                j = WHERE(temps EQ chosen_temps[i], count)
                IF count NE 0 THEN BEGIN
                    IF i EQ 0 THEN choices = [j] ELSE choices = [choices, j]
                ENDIF ELSE BEGIN
                    MESSAGE, /ERROR, 'Invalid temperature choice '+STRTRIM(chosen_temps[i],2)+'!'
                ENDELSE
            ENDFOR
        ENDELSE

        ; Now we have a list of chosen temperatures and their relevant indices
        ; We can plot the images (titles are the temperatures + 'K')
        titles = STRTRIM(chosen_temps,2) + 'K'

        ; We need to extract the DEMs that we want first
        FOR i = 0, N_ELEMENTS(choices)-1 DO BEGIN
            d = dem[*,*,choices[i]]
            IF i EQ 0 THEN dems = [[d]] ELSE dems = [[[dems]], [[d]]]
            help, d
        ENDFOR
        help, dems

        ; Plot!
        IMAGES_LAYOUT, dems, SCALE=scale, TITLES=titles, _EXTRA=_extra
    ENDELSE
END