; NAME:
;   DLoad
;
; PURPOSE:
;   Load map from save files relating to a specific event
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; CALLS:
;   ChooseFile
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   event  (string)  the event to look for files in
;   search (string)  a glob string to narrow the search down
;
; OUTPUTS:
;   event     string  the event that we're loading from
;   RETURN    map     the arrMap variable from the save data
;   filename  string  the file name that we're loading from
;
FUNCTION DLoad, EVENT=event, SEARCH=search, FILE=file, DIR=dataDir
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; Where events are stored
    CONFIGURATOR, DATA_DIR=eventsDir

    ; The save data subdirectory
    IF NOT KEYWORD_SET(dataDir) THEN dataDir = 'maps'

    ;;;;;;;;;;;;
    ;;; FUNC ;;;
    ;;;;;;;;;;;;

    ; If no event specified, prompt
    IF event EQ !NULL THEN event = FILE_BASENAME(ChooseFile(eventsDir, /DIR))

    ; Setup the data directory
    dataDir = eventsDir + '/' + event + '/' + dataDir

    IF NOT KEYWORD_SET(search) THEN search = '*.save'

    ; Get the file
    file = ChooseFile(dataDir, SEARCH=search)

    ; If the file is null, then return null
    IF file EQ !NULL THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Either no file found or EXIT requested.'
        RETURN, !NULL
    ENDIF

    MESSAGE, /INFORMATIONAL, 'Restoring ' + file + '...'
    RESTORE, file

    ; Return the arrMap variable
    RETURN, arrMap
END