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
; OPTIONAL INPUTS:
;   cutout   (array)  the pixel box to average over
;   relative (flag)   if set, normalises intensities to 100
;   search   (string) a glob filter to narrow down available maps
;   save     (string) if set, will save a postscript file to the specified filename
;   filters  (array)  array of filters in order that you would like plotted, non-interactive
; 
PRO Lightcurve, CUTOUT=cutout, title=title, SEARCH=search, SAVE=save, FILTERS=filters, RELATIVE=relative
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; events location
    CONFIGURATOR, DATA_DIR=eventsDir

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

    ; character sizing
    charsize = 2

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Ask for cutout area
    IF NOT KEYWORD_SET(cutout) THEN BEGIN
        c = [0,0,0,0]
        READ, c, PROMPT='Please specify a cutout area (x0,x1,y0,y1): '
    ENDIF ELSE c = cutout

    ; Create x/y variables
    x0 = c[0]
    x1 = c[1]
    y0 = c[2]
    y1 = c[3]


    ;;;;;;;;;;;;;;;;;;
    ;;; Processing ;;;
    ;;;;;;;;;;;;;;;;;;

    ; If save is specified, then open a PS file
    IF KEYWORD_SET(save) THEN BEGIN
        PS, save, /LAND, /COLOR
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

        ; Default title is event name
        IF NOT KEYWORD_SET(title) THEN title = event
        ; axes etc.
        xt = 'time (HH:MM)'
        IF KEYWORD_SET(relative) THEN yt = 'relative strength' ELSE yt = 'dn / s'

        ; Get legend data
        ; Get the date
        dates = STREGEX(arrMap.time, '([0-9A-Za-z\-]+)', /EXTRACT)
        date = dates[0]
        ; Get the filter number
        ids = STREGEX(arrMap.id, '([0-9]{2,4})', /EXTRACT)
        f_name = ids[0]

        ; Colour for the wavelength
        colour = colours[FIX(f_name)]

        ; average data
        data = AVERAGE(arrMap.data[x0:x1, y0:y1], [1, 2])

        ; if RELATIVE is set, normalise
        IF KEYWORD_SET(relative) THEN data = (data / MAX(data)) * 100

        ; If this is the first one, use UTPLOT, otherwise OUTPLOT
        IF i EQ 0 THEN BEGIN
            UTPLOT, arrMap.time, data, color=colour, title=title, xtitle=xt, ytitle=yt, CHARSIZE=charsize
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
    AL_LEGEND, legend_items[REORD], COLORS=legend_colours[REORD], LINESTYLE=0, /BOTTOM_LEGEND, /RIGHT_LEGEND, /CLEAR, CHARSIZE=charsize, LINSIZE=0.3

    ; Close the PS file if created
    IF KEYWORD_SET(save) THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Writing file...'
        PSCLOSE
    ENDIF
END