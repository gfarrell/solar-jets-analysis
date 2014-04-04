; NAME:
;   DemLoad
;
; PURPOSE:
;   Loads DEM data from save files relating to a specific event
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
;   RETURN      array   the DEM data
;   event       string  the event that we're loading from
;   filename    string  the file name that we're loading from
;   h_err       array   errors on the x-axis (logT)
;   v_err       array   errors on the y-axis (DEM)
;   bin_size    number  the bin size
;   ti          number  the temperature interval
;   temps       array   the temperature arrays
;
FUNCTION DemLoad, EVENT=event, SEARCH=search, FILE=file, DIR=dataDir, H_ERR=h_err, V_ERR=v_err, BIN_SIZE=bin_size, TI=ti, TEMPS=temps
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; Where events are stored
    CONFIGURATOR, DATA_DIR=eventsDir

    ; The save data subdirectory
    IF NOT KEYWORD_SET(dataDir) THEN dataDir = 'dem'

    ;;;;;;;;;;;;
    ;;; FUNC ;;;
    ;;;;;;;;;;;;

    ; If no event specified, prompt
    cE = ChooseFile(eventsDir, /DIR)
    IF cE NE !NULL THEN BEGIN
        IF event EQ !NULL THEN event = FILE_BASENAME(cE)

        ; Setup the data directory
        dataDir = eventsDir + '/' + event + '/' + dataDir

        IF NOT KEYWORD_SET(search) THEN search = '*.save'

        ; Get the file
        file = ChooseFile(dataDir, SEARCH=search)

        If file NE !NULL THEN BEGIN
            MESSAGE, /INFORMATIONAL, 'Restoring ' + file + '...'
            RESTORE, file

            RETURN, dem
        ENDIF
    ENDIF

    MESSAGE, /INFORMATIONAL, 'Either no file found or EXIT requested.'
    RETURN, !NULL    
END