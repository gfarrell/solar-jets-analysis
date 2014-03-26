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
;   title  (string) plot title
;   cutout (array)  if specified, all DEMS will be averaged over this pixel area
;
PRO COMPARE_DEMS, TITLE=title, CUTOUT=cutout
    ; Set iteration counter so we know which plot routine to use
    i = 0

    ; Colours
    colours = ['red','blue','purple','green','orange','black']

    ; Line styles
    ; 0 Solid
    ; 1 Dotted
    ; 2 Dashed
    ; 3 Dash Dot
    ; 4 Dash Dot Dot
    ; 5 Long Dashes
    lines = [0,2,3,4,5,1] ; visibility order

    ; If no title is set, make it "DEM Comparison"
    IF NOT KEYWORD_SET(title) THEN title = 'DEM Comparison'

    ; Keep asking for DEMs
    ; Ask for the cutout area (leave blank to use previous) if not specified
    ; Ask for a title for the DEM
    ; Load DEM, plot it
    WHILE 1 DO BEGIN
        ; First load DEM
        dem = DEMLoad(EVENT=event, TEMPS=temps, H_ERR=herr, V_ERR=verr)

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
            PLOTERROR, xaxis, data, xerr, yerr, TITLE=title, LINESTYLE=line, xtitle='Log10 of temperature', ytitle='dn', /NOHAT, THICK=1.5, ERRCOL=colour, COLOR=colour
        ENDIF ELSE BEGIN
            OPLOTERROR, xaxis, data, xerr, yerr, /NOHAT, THICK=1.5, ERRCOL=colour, COLOR=colour, LINESTYLE=line
        ENDELSE

        ; Iterate
        i = i + 1
    ENDWHILE

    ; Draw legend
    AL_LEGEND, l_names, colors=l_colours, linestyle=l_lines, /top_legend, /right_legend, /clear
END