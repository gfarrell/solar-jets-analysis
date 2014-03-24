; NAME:
;   SDO_GET_SNAPSHOT
;
; PURPOSE:
;   Download full disc FITS files for a snapshot in time (select 12s with 12s cadence)
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   event (string) the name of the event
;   date  (string) YYYY/MM/DD date formatted string
;   time  (string) HH:MM:SS time formatted string
;
; OPTIONAL INPUTS:
;   name    (string) specify a name for the snapshot
;   filters (array)  specify a non-standard filter set e.g. [131, 171]
;
PRO SDO_GET_SNAPSHOT, event, date, time, NAME=name, FILTERS=filters
    ;;;;;;;;;;;;;;;;;;;;;
    ;;; CONFIGURATION ;;;
    ;;;;;;;;;;;;;;;;;;;;;

    ; The root directory in which we will store our data
    CONFIGURATOR, DATA_DIR=eventsDir

    ; The directory in which images will get stored
    imgDir = 'raw/snapshots'

    ; Default filters
    IF NOT KEYWORD_SET(filters) THEN filters = [94, 131, 171, 193, 211, 335]

    ; Separation between start and end times
    cadence = 12

    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    ; Default name is just combination of dates/times
    IF NOT KEYWORD_SET(name) THEN BEGIN
        name = date + time
        name = STRJOIN(STRSPLIT(name, '/-:.', /EXTRACT), '')
    ENDIF

    ; Root data dir for this event
    dataDir = eventsDir + '/' + event
    IF NOT FILE_TEST(dataDir) THEN FILE_MKDIR, dataDir

    ; Directory to store image files in
    imgDir = dataDir + '/' + imgDir + '/' + name
    IF NOT FILE_TEST(imgDir) THEN FILE_MKDIR, imgDir

    ; Count filters
    fc = N_ELEMENTS(filters)

    ; Calculate end time
    times = STRSPLIT(time, ':', /EXTRACT) ; split into [H, M, S]
    times = [FIX(times[0]), FIX(times[1]), FIX(times[2])]

    hh = cadence MOD 3600
    mm = hh MOD 60

    IF cadence GE 3600 THEN times[0] = times[0] + hh
    IF cadence LT 3600 AND cadence GE 60 THEN times[1] = mm
    IF cadence LT 60 THEN times[2] = times[2] + cadence

    end_time = STRTRIM(times[0], 2) + ':' + STRTRIM(times[1], 2) + ':' + STRTRIM(times[2], 2)

    ;;;;;;;;;;;;;;;;
    ;;; DOWNLOAD ;;;
    ;;;;;;;;;;;;;;;;

    MESSAGE, /INFORMATIONAL, 'Starting download process.'

    FOR i=0, fc-1 DO BEGIN
        filter = STRTRIM(filters[i], 2)

        MESSAGE, /INFORMATIONAL, '- Downloading data for ' + filter + '...'

        dl_metadata = vso_search(date + ' ' + time, date + ' ' + end_time, inst='aia', wave=filter, sample=cadence)

        stat = vso_get(dl_metadata, out_dir=imgDir, /FORCE)
    ENDFOR

    MESSAGE, /INFORMATIONAL, '*** Complete ***'
END