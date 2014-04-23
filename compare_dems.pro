; NAME:
;   COMPARE_DEMS
;
; PURPOSE:
;   Plots two or more DEM curves against each other
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; OPTIONAL INPUTS:
;   title    (string) plot title
;   cutout   (array)  if specified, all DEMS will be averaged over this pixel area
;   relative (flag)   make peak heights relative to max value
;   save     (string) postscript file to save result to
;
PRO COMPARE_DEMS, TITLE=title, CUTOUT=cutout, RELATIVE=relative, SAVE=save
    ; Set iteration counter so we know which plot routine to use
    i = 0

    ; Colours
    colours = ['red','blue','green','orange','purple','black']

    ; Line styles
    ; 0 Solid
    ; 1 Dotted
    ; 2 Dashed
    ; 3 Dash Dot
    ; 4 Dash Dot Dot
    ; 5 Long Dashes
    lines = [0,2,3,4,5,1] ; visibility order

    ; Charsize to use
    charsize = 2

    ; If no title is set, make it blank
    IF NOT KEYWORD_SET(title) THEN title = ''

    IF KEYWORD_SET(save) THEN PS, save

    ; Keep asking for DEMs
    ; Ask for the cutout area (leave blank to use previous) if not specified
    ; Ask for a title for the DEM
    ; Load DEM, plot it
    WHILE 1 DO BEGIN
        ; First load DEM
        dem = DEMLoad(TEMPS=temps, H_ERR=herr, V_ERR=verr)

        ; Break if user requests exit from loop
        IF dem EQ !NULL THEN BREAK

        ; If cutout not specified, ask for cutout area
        IF NOT KEYWORD_SET(cutout) THEN BEGIN
            c = [0,0,0,0]
            READ, c, PROMPT='Please specify a cutout area (x0,x1,y0,y1): '
        ENDIF ELSE c = cutout

        ; Ask for a name for this DEM
        name = ''
        READ, name, PROMPT='Please name this DEM curve: '

        ; Now perform data averaging
        data = AVERAGE(dem[c[0]:c[1], c[2]:c[3], *], [1,2])

        ; Average over errors
        xerr = AVERAGE(herr[c[0]:c[1], c[2]:c[3], *], [1,2])
        yerr = AVERAGE(verr[c[0]:c[1], c[2]:c[3], *], [1,2])

        ; If we're doing relative strength, attenuate
        ; ie make everything a %age of max DEM value.
        ; we do this for data because we want relatives w/i the average
        IF KEYWORD_SET(relative) THEN BEGIN
            d_max = MAX(data)
            data = data / d_max * 100
            yerr = yerr / d_max * 100

            MESSAGE, /INFORMATIONAL, 'DEM Maximum: '+STRTRIM(d_max,2)
            MESSAGE, /INFORMATIONAL, 'New data max: '+STRTRIM(MAX(data),2)
            MESSAGE, /INFORMATIONAL, 'New yerr max: '+STRTRIM(MAX(yerr),2)
        ENDIF

        ; Styling
        colour = colours[i MOD (N_ELEMENTS(colours) - 1)]
        line = lines[i MOD (N_ELEMENTS(lines) - 1)]

        ; Legend data
        IF i EQ 0 THEN l_colours = [colour] ELSE l_colours = [l_colours, colour]
        IF i EQ 0 THEN l_lines = [line] ELSE l_lines = [l_lines, line]
        IF i EQ 0 THEN l_names = [name] ELSE l_names = [l_names, name]

        ; X-Axis data
        xaxis = GET_EDGES(ALOG10(temps), /MEAN)

        ; Plot
        IF i EQ 0 THEN BEGIN
            IF KEYWORD_SET(relative) THEN yt = 'relative strength' ELSE yt = 'DEM [cm^-5 K^-1]'
            
            PLOTERROR, xaxis, data, xerr, yerr, TITLE=title, xtitle='Log10 of temperature [K]', ytitle=yt, /NOHAT, THICK=1.5, LINESTYLE=0,  ERRCOL=colour, COLOR=colour, CHARSIZE=charsize, YRANGE=[0, MAX(data)*1.05]
        ENDIF ELSE BEGIN
            OPLOTERROR, xaxis, data, xerr, yerr, /NOHAT, THICK=1.5, ERRCOL=colour, COLOR=colour, LINESTYLE=0
        ENDELSE

        ; Iterate
        i = i + 1
    ENDWHILE

    reord = SORT(l_names)

    ; Draw legend
    AL_LEGEND, l_names[reord], colors=l_colours[reord], LINESTYLE=0, /TOP_LEGEND, /RIGHT_LEGEND, /CLEAR, CHARSIZE=charsize, LINSIZE=0.3

    IF KEYWORD_SET(save) THEN PSCLOSE
END