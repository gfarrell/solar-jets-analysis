; NAME:
;   STITCH_FRAMES
;
; PURPOSE:
;   Stitches the frames of several map sequences together
;   Designed to take filters and put them side-by-side for each time-slice
;   Writes an MPEG movie at 15 Mb/s and saves it in the event's movies dir
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   event   (string) the event we're dealing with
;
; OPTIONAL INPUTS:
;   Anything that PLOT_MAP takes, this will pass on
;
PRO STITCH_FRAMES, event, _extra=extra
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; where we store events
    CONFIGURATOR, DATA_DIR=rootDir

    ; our temp storage directory
    tmpDir = '~/tmp/stitch'

    ; our output directory
    outDir = 'movies'

    ; our output filename
    fileName = 'compositeMovie.mpeg'

    ; filters
    filters = [94, 131, 171, 193, 211, 335]

    ; imagemagick command
    magick = 'convert'

    ; framerate
    fps = 16

    ; ffmpeg command
    ffmpeg = 'ffmpeg'

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; setup directories
    eventDir = rootDir + '/' + event
    outDir = eventDir + '/' + outDir
    fileName = outDir + '/' + fileName

    ; clean up the temp dir
    IF FILE_TEST(tmpDir) THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Cleaning temp directory...'
        FILE_DELETE, tmpDir, /RECURSIVE
    ENDIF

    ; Set up directories
    FILE_MKDIR, tmpDir
    IF NOT FILE_TEST(outDir, /DIRECTORY, /WRITE) THEN FILE_MKDIR, outDir

    ; get the image magick command
    magick = SSW_BIN(magick, found=found)
    IF ~found THEN BEGIN
        MESSAGE, /ERROR, 'ImageMagick command not found'
    ENDIF

    ; get the ffmpeg command
    ffmpeg = SSW_BIN(ffmpeg, found=found)
    IF ~found THEN BEGIN
        MESSAGE, /ERROR, 'ffmpeg command not found'
    ENDIF

    ; number of filters
    fn = N_ELEMENTS(filters)

    ;;;;;;;;;;;;;;;;;;;;
    ;;; FRAME EXPORT ;;;
    ;;;;;;;;;;;;;;;;;;;;

    ; Basic idea is to export a png of each frame for each filter
    ; then we cycle over frames, stitching the filters together on a 3x2 basis
    ; later on we'll create a movie

    ; Set the plotting device to z
    SET_PLOT, 'z'

    ; Load the RED TEMPERATURE colour table
    LOADCT, 3

    MESSAGE, /INFORMATIONAL, 'Starting frame export process'

    ; cycle over filters
    FOR i=0, fn-1 DO BEGIN
        MESSAGE, /INFORMATIONAL, '- Exporting frames for ' + STRTRIM(filters[i], 2)
        ; load the map
        map = DLoad(EVENT=event, SEARCH='full_' + STRTRIM(filters[i], 2))

        ; how many frames do we have?
        fc = N_ELEMENTS(map)

        ; we need to find the min frame count so our sequences are all the same length
        IF i EQ 0 THEN BEGIN
            min_fc = fc
        ENDIF ELSE BEGIN
            IF fc LT min_fc THEN min_fc = fc
        ENDELSE

        ; cycle over the frames
        FOR j=0, fc-1 DO BEGIN
            ; the filename we're writing to
            frame = tmpDir + '/' + STRTRIM(filters[i], 2) + '_' + STRTRIM(j, 2) + '.png'

            ; plot the frame
            PLOT_MAP, map[j], _extra

            ; extract colour data
            TVLCT, r, g, b, /GET

            ; save the image
            img = TVRD()

            ; write a png file
            WRITE_PNG, frame, img, r, g, b
        ENDFOR
    ENDFOR

    ;;;;;;;;;;;;;;;;;;;;;;;
    ;;; FRAME STITCHING ;;;
    ;;;;;;;;;;;;;;;;;;;;;;;

    ; Set the plotting device back to x
    SET_PLOT, 'x'

    MESSAGE, /INFORMATIONAL, 'Starting stitching process'
    ; cycle over the frames
    FOR i = 0, min_fc-1 DO BEGIN
        MESSAGE, /INFORMATIONAL, '- Stitching #' + STRTRIM(i, 2)

        tR = tmpDir + '/' + STRTRIM(i, 2) + '_topRow.png'
        bR = tmpDir + '/' + STRTRIM(i, 2) + '_bottomRow.png'
        frame = tmpDir + '/comp_' + STRTRIM(i, 2) + '.png'
        
        ; process top row
        MESSAGE, /INFORMATIONAL, '--- Processing top row'
        names = tmpDir + '/' + STRTRIM(filters[0:2], 2) + '_' + STRTRIM(i, 2) + '.png'
        cmd = magick + ' ' + STRJOIN(names, ' ') + ' +append ' + tR
        SPAWN, cmd

        ; process bottom row
        MESSAGE, /INFORMATIONAL, '--- Processing bottom row'
        names = tmpDir + '/' + STRTRIM(filters[3:5], 2) + '_' + STRTRIM(i, 2) + '.png'
        cmd = magick + ' ' + STRJOIN(names, ' ') + ' +append ' + bR
        SPAWN, cmd

        ; Merge rows
        MESSAGE, /INFORMATIONAL, '--- Merging rows to ' + frame
        cmd = magick + ' ' + tR + ' ' + bR + ' -append ' + frame
        SPAWN, cmd

        ; Delete row files
        MESSAGE, /INFORMATIONAL, '--- Deleting temp files'
        FILE_DELETE, tR
        FILE_DELETE, bR
    ENDFOR

    ;;;;;;;;;;;;;;;;;;;
    ;;; MPEG EXPORT ;;;
    ;;;;;;;;;;;;;;;;;;;

    MESSAGE, /INFORMATIONAL, 'Exporting MPEG ' + fileName
    cmd = ffmpeg + ' -b 15M -i ' + tmpDir + '/comp_%d.png ' + fileName
    SPAWN, cmd

    ;;;;;;;;;;;;;;;
    ;;; CLEANUP ;;;
    ;;;;;;;;;;;;;;;

    MESSAGE, /INFORMATIONAL, 'Cleaning up'
    FILE_DELETE, tmpDir, /RECURSIVE 
END