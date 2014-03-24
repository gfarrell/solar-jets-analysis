; NAME:
;   DATA2GIF
;
; PURPOSE:
;   Converts a map to a GIF movie
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   NONE
;
; OPTIONAL INPUTS:
;   event  (string) an event to use
;   search (string) a glob to narrow down the list
;
PRO Data2Gif, EVENT=event, SEARCH=search
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; event storage
    CONFIGURATOR, DATA_DIR=eventsDir

    ; maps storage
    mapDir = 'maps'

    ; movie output
    gifDir = 'movies'

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Choose an event if not set
    IF NOT KEYWORD_SET(event) THEN event = FILE_BASENAME(ChooseFile(eventsDir))

    ; Set directories
    rootDir = eventsDir + '/' + event
    mapDir = rootDir + '/' + mapDir
    gifDir = rootDir + '/' + gifDir

    ; default search string
    IF NOT KEYWORD_SET(search) THEN search = '*.save'

    ; Build dirs if non-existent
    IF NOT FILE_TEST(gifDir, /DIRECTORY, /WRITE) THEN FILE_MKDIR, gifDir

    ;;;;;;;;;;;;;;;;;;
    ;;; PROCESSING ;;;
    ;;;;;;;;;;;;;;;;;;

    ; Load data
    file = ChooseFile(mapDir, SEARCH=search)
    RESTORE, file

    ; Output file is just the same filename as the map but with .gif instead of .save
    fNames = STRSPLIT(FILE_BASENAME(file), '.', /EXTRACT)
    ; We want to remove the extension
    saveFile = gifDir + '/' + fNames[0] + '.gif'

    ; Create the gif
    MAPS2GIF_MOVIE, arrMap, saveFile
END