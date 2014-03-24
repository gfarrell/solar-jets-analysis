; NAME:
;   SDO_PROCESS_FULL
;
; PURPOSE:
;   Process data downloaded from the SDO AIA Cutout Service (lockheed)
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   event (string) the name of the event to process
;
; OPTIONAL INPUTS:
;   filters    (array) an array of filters to process (will be separately processed)
;
PRO SDO_PROCESS_FULL, event, FILTERS=filters
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; where the event is
    CONFIGURATOR, DATA_DIR=eventsDir
    rootDir = eventsDir + '/' + event

    ; where the images are
    imgDir = rootDir + '/raw/full'

    ; where the maps are
    mapDir = rootDir + '/maps'

    ; the glob pattern for relevant FITS files (will have filter* appended)
    glob = '*AIA*'

    ; save file format (will have filter.save appended)
    save = 'full_'

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; default filters if not specified
    IF NOT KEYWORD_SET(filters) THEN filters = [94,131,171,193,211,304,335]

    ; if filters is just a single element, splat it
    IF NOT ISA(filters, /ARRAY) THEN filters = [filters]

    ; check the event exists and is read-writable
    IF NOT FILE_TEST(imgDir, /DIRECTORY, /READ, /WRITE) THEN BEGIN
        MESSAGE, 'Event directory does not exist or cannot RW'
        RETURN
    ENDIF

    ; make sure mapsDir exists
    IF NOT FILE_TEST(mapDir, /DIRECTORY, /WRITE) THEN FILE_MKDIR, mapDir

    ;;;;;;;;;;;;;;;;;;
    ;;; PROCESSING ;;;
    ;;;;;;;;;;;;;;;;;;

    MESSAGE, /INFORMATIONAL, 'Processing event "' + event + '"...'

    ; cycle through filters and process as we go
    fCount = N_ELEMENTS(filters)
    FOR i=0, fCount-1 DO BEGIN
        ; what filter are we?
        filter = STRTRIM(filters[i], 2) ; needs to be a string anyway
        
        ; find all our files that we need
        frames = FILE_SEARCH(imgDir + '/' + glob + filter + '*')
        frameCount = N_ELEMENTS(frames)

        ;
        MESSAGE, /INFORMATIONAL, '- filter ' + filter + ' (' + STRTRIM(frameCount, 2) + ' files).'

        ; convert each frame into a map and append to the array
        FOR j=0, frameCount-1 DO BEGIN
            READ_SDO, frames[j], index, data
            INDEX2MAP, index, FLOAT(data), map

            ; Concatenate maps
            IF j EQ 0 THEN arrMap = map ELSE arrMap = [arrMap, map]
        ENDFOR

        ; save data
        MESSAGE, /INFORMATIONAL, '--- saving data...'

        SAVE, arrMap, file=mapDir + '/' + save + filter + '.save', /COMPRESS
    ENDFOR
END