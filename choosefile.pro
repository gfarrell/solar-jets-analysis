; NAME:
;   ChooseFile
;
; PURPOSE:
;   Present the user with a choice of files from a given directory.
;   If only one choice is available, use that one.
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; CALLS:
;   PromptChoice
;
; INPUTS:
;   rootDir (string)  the root directory to search in
;
; OPTIONAL INPUTS:
;   search  (string)  a glob string to narrow searches down with, e.g. '*.fits'
;   dir     (boolean) whether or not to narrow down to directories
;   first   (boolean) if set, automatically uses the first file found
;
; OUTPUTS:
;   (string) path to selected file
;
FUNCTION ChooseFile, rootDir, SEARCH = search, DIR=DIR, FIRST=FIRST
    ;;;;;;;;;;;;;
    ;;; SETUP ;;;
    ;;;;;;;;;;;;;

    searchPattern = '*'

    ; Check our rootDir exists
    IF FILE_TEST(rootDir, /DIRECTORY, /READ) EQ 0 THEN BEGIN
        PRINT, 'Root search directory "' + rootDir + '" not found.'
        RETURN, !NULL
    ENDIF

    ; If a match string has been specified, incorporate it
    IF KEYWORD_SET(search) THEN searchPattern = '*' + search + searchPattern

    ;;;;;;;;;;;;;;;;
    ;;; FUNCTION ;;;
    ;;;;;;;;;;;;;;;;

    ; If there aren't any files, exit
    ; NB can't use N_ELEMENTS because it returns 1 even if no files found (bug?)
    IF FILE_TEST(rootDir + '/' + searchPattern) EQ 0 THEN BEGIN
        PRINT, 'No files found.'
        RETURN, !NULL
    ENDIF

    ; Search for files or folders (if /DIR is set)
    IF KEYWORD_SET(DIR) THEN BEGIN
        files = FILE_SEARCH(rootDir + '/' + searchPattern, /TEST_READ, /TEST_DIRECTORY)
    ENDIF ELSE BEGIN
        files = FILE_SEARCH(rootDir + '/' + searchPattern, /TEST_READ)
    ENDELSE

    fCount = N_ELEMENTS(files)

    ; If there is only one file, just use that one (or if /FIRST set)
    IF fCount EQ 1 OR KEYWORD_SET(first) THEN BEGIN
        file = files[0]
    ENDIF ELSE BEGIN
        ; Display a choice of files to the user
        PRINT, 'I have found the following:'
        FOR i = 1, fCount DO BEGIN
            PRINT, STRTRIM(i, 2) + ') ' + FILE_BASENAME(files[i - 1])
        ENDFOR

        ; Read the user's choice
        choice = PromptChoice(fCount)

        IF choice EQ !NULL THEN BEGIN
            MESSAGE, /INFORMATIONAL, 'Exit requested.'
            RETURN, !NULL
        ENDIF

        file = files[choice - 1]
    ENDELSE

    RETURN, file
END