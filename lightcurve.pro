; NAME:
;   LIGHTCURVE
;
; PURPOSE:
;   Averages intensity over spatial coordinates and plots against time
;   Can combine multiple plots on one graph
;   Can save a PostScript file if desired
;   NB: plotting order should be most intense -> least intense otherwise former will be off-graph
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; CALLS:
;   ChooseFile, DLoad, UTPLOT, OUTPLOT, AL_LEGEND
;
; INPUTS:
;   event   (string) the specific event to look at
;   x_range (array)  pixel boundaries along the x-axis e.g. [1, 50]
;   y_range (array)  pixel boundaries along the y-axis e.g. [250, 450]
;
; OPTIONAL INPUTS:
;   search  (string) a glob filter to narrow down available maps
;   save    (string) if set, will save a postscript file to the specified filename
;   filters (array)  array of filters in order that you would like plotted, non-interactive
; 
PRO Lightcurve, event, x_range, y_range, title=title, SEARCH=search, SAVE=save, FILTERS=filters
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; events location
    CONFIGURATOR, DATA_DIR=eventsDir
    
    ; save file location
    saveDir = 'plots'

    ; Colours
    ; 0  black,
    ; 1  white,
    ; 2  yellow,
    ; 3  red,
    ; 4  green,
    ; 5  blue,
    ; 6  orange,
    ; 7  purple,
    ; 8  magenta,
    ; 9  brown, 
    ; 10 turquoise

    ; Dark colours
    ; colours = [0, 3, 4, 5, 6, 7, 8, 9, 10]
    ; Colours specific to wavelength
    colours = HASH(94, 10, 131, 3, 171, 4, 193, 5, 211, 6, 304, 7, 335, 8)

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Dirs
    rootDir = eventsDir + '/' + event
    saveDir = rootDir + '/' + saveDir

    ; Validate
    IF x_range[0] GT x_range[1] THEN $
        x_range = REVERSE(x_range)
    IF y_range[0] GT y_range[1] THEN $
        y_range = REVERSE(y_range)

    ; Create x/y variables
    x0 = x_range[0]
    x1 = x_range[1]
    y0 = y_range[0]
    y1 = y_range[1]

    ; Default title is event name
    IF NOT KEYWORD_SET(title) THEN title = event

    ;;;;;;;;;;;;;;;;;;
    ;;; Processing ;;;
    ;;;;;;;;;;;;;;;;;;

    ; If save is specified, then open a PS file
    IF KEYWORD_SET(save) THEN BEGIN
        IF NOT FILE_EXIST(saveDir) THEN FILE_MKDIR, saveDir
        PS, saveDir + '/' + save, /LAND, /COLOR
    ENDIF

    ; Keep offering to process until user requests exit
    ; Add subsequent plots instead of making new ones
    SET_LINE_COLOR
    SET_UTLABEL, 0
    i = 0

    ; if filters is set, we'll use that instead of interactivity
    ; to that end, we need to know how many there are
    ; this will also operate as a sort of flag
    IF KEYWORD_SET(filters) THEN fNum = N_ELEMENTS(filters) ELSE fNum = 0

    ; Start building up a legend
    IF NOT KEYWORD_SET(filters) THEN filters = []
    legend_items   = []
    legend_lines   = []
    legend_colours = []

    WHILE 1 DO BEGIN
        ; Check if there are filters left to go through
        IF i LT fNum THEN BEGIN
            arrMap = DLoad(EVENT=event, SEARCH='full_'+STRTRIM(filters[i], 2))
        ENDIF ELSE IF fNum EQ 0 THEN BEGIN
            arrMap = DLoad(EVENT=event, SEARCH=filter)
        ENDIF ELSE arrMap = !NULL

        ; Check that we were successful, otherwise exit the loop
        IF arrMap EQ !NULL THEN BREAK

        ; Get legend data
        ; Get the date
        dates = STREGEX(arrMap.time, '([0-9A-Za-z\-]+)', /EXTRACT)
        date = dates[0]
        ; Get the filter number
        ids = STREGEX(arrMap.id, '([0-9]{2,4})', /EXTRACT)
        f_name = ids[0]

        ; Colour for the wavelength
        colour = colours[FIX(f_name)]

        ; If this is the first one, use UTPLOT, otherwise OUTPLOT
        data = AVERAGE(arrMap.data[x0:x1, y0:y1], [1, 2])
        IF i EQ 0 THEN BEGIN
            UTPLOT, arrMap.time, data, color=colour, title=title, xtitle='time (HH:MM)', ytitle='dn / s'
        ENDIF ELSE BEGIN
            OUTPLOT, arrMap.time, data, COLOR=colour
        ENDELSE

        ; Add to the legend
        IF fNum EQ 0 THEN filters = [filters, FIX(f_name)]
        legend_items   = [legend_items, [f_name + 'A']]
        legend_colours = [legend_colours, [colour]]

        i = i + 1
    ENDWHILE

    ; Draw the legend
    ; We want to order the filters in numerical order, otherwise it's ugly
    REORD = SORT(filters)
    AL_LEGEND, legend_items[REORD], colors=legend_colours[REORD], linestyle=0, /top_legend, /right_legend, /clear

    ; Close the PS file if created
    IF KEYWORD_SET(save) THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Writing file...'
        PSCLOSE
    ENDIF
END