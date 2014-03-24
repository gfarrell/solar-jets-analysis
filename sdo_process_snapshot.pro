; NAME:
;   SDO_PROCESS_SNAPSHOT
;
; PURPOSE:
;   Create a composite map from an SDO snapshot across a filter range.
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   NONE
;
; OPTIONAL INPUTS:
;   event   (string) the name of the event
;   name    (string) the snapshot to be processed
;   filters (array)  an array of filters to be processed, default: all
;   cutout  (array)  a bounding box (x0, x1, y0, y1) in arcsecs to be cropped to
;   
PRO SDO_PROCESS_SNAPSHOT, EVENT=event, NAME=name, FILTERS=filters, CUTOUT=cutout
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; The root directory in which we will store our data
    CONFIGURATOR, DATA_DIR=dataDir

    ; Directory to look for images in
    imgDir = 'raw/snapshots'

    ; Directory to save maps in
    mapDir = 'maps'
    
    ; Save file name (this is going to be modified in due course)
    saveFile = 'map'

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; default filters
    IF NOT KEYWORD_SET(filters) THEN filters = [94, 131, 171, 193, 211, 335]

    ; First choose the event, if name is specified, use it as a search string
    IF NOT KEYWORD_SET(event) THEN event = FILE_BASENAME(ChooseFile(dataDir, /DIR))

    ; Set up directories
    dataDir = dataDir + '/' + event
    mapDir  = dataDir + '/' + mapDir
    imgDir  = dataDir + '/' + imgDir

    ; Now choose the snapshot
    IF NOT KEYWORD_SET(name) THEN name = FILE_BASENAME(ChooseFile(imgDir, /DIR))

    ; Set imgDir again
    imgDir = imgDir + '/' + name

    ; If filter is just a single value, make it into a array
    IF NOT ISA(filters, /ARRAY) THEN filters = [filters]

    ; Set up the save file name
    saveFile = name
    saveFile = mapDir + '/' + name + '_composite.save'

    ; Create mapDir if it doesn't exist
    IF NOT FILE_TEST(mapDir) THEN FILE_MKDIR, mapDir


    ;;;;;;;;;;;;;;;;;;
    ;;; PROCESSING ;;;
    ;;;;;;;;;;;;;;;;;;

    MESSAGE, /INFORMATIONAL, 'Generating map from FITS files.'

    ; Collect all the files
    ; cycle over filters and collect relevant files
    ; we only want one snapshot per filter
    fCount = N_ELEMENTS(filters)
    FOR i=0, fCount-1 DO BEGIN
        raw_tmp = FILE_SEARCH(imgDir + '/*' + STRTRIM(filters[i], 2) + 'A*.fits')
        ; add only the first file into the array
        IF i EQ 0 THEN $
            raw_files = [raw_tmp[0]] $
        ELSE $
            raw_files = [raw_files, raw_tmp[0]]
    ENDFOR

    ; Prepare
    MESSAGE, /INFORMATIONAL, '- Preparing files (' + STRTRIM(N_ELEMENTS(raw_files),2) + ')...'
    ; This doesn't normalise by default
    ; This is good because dn2dem_map_pos expects unnormalised files
    AIA_PREP, raw_files, -1, index, data

    ; Sort by wavelength
    reord = SORT(index.wavelnth)

    ; Generate map
    MESSAGE, /INFORMATIONAL, '- Creating map...'
    INDEX2MAP, index[reord], data[*, *, reord], map_in

    ; If cutout specified, and is a four element array then create sub-map
    IF KEYWORD_SET(cutout) AND ISA(cutout, /ARRAY) AND N_ELEMENTS(cutout) EQ 4 THEN BEGIN
        MESSAGE, /INFORMATIONAL, '- Cutting out sub-map'
        SUB_MAP, map_in, arrMap, xrange=[cutout[0],cutout[1]], yrange=[cutout[2],cutout[3]]
    ENDIF ELSE arrMap = map_in

    ; Save the map
    MESSAGE, /INFORMATIONAL, 'Saving data in ' + saveFile + '.'
    SAVE, arrMap, FILENAME=saveFile, DESCRIPTION = 'Snapshot of SDO AIA ' + event + ' ' + name

    MESSAGE, /INFORMATIONAL, '*** Complete ***'
END