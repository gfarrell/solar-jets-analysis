; NAME:
;   PLOT_FRAMES
;
; PURPOSE:
;   Plots a pixel map of any frames for a given data set in a given event.
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; CALLS:
;   ChooseFile, DLoad, PromptChoice, PLOT_IMAGE
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   event  (string) the name of the event to look at
;   search (string) a glob string to filter results with
;
PRO Plot_Frames, EVENT=event, SEARCH=search
    ; Where events are stored
    CONFIGURATOR, DATA_DIR=eventsDir

    ; Where data is stored
    dataDir = 'maps'

    ; If no event specified, select one
    IF NOT KEYWORD_SET(event) THEN event = FILE_BASENAME(ChooseFile(eventsDir, /DIR))

    ; Load the data
    IF NOT KEYWORD_SET(search) THEN search = '*.save'
    arrMap = DLoad(EVENT=event, SEARCH=search)

    IF arrMap EQ !NULL THEN BEGIN
        MESSAGE, 'Unable to load file.'
        RETURN
    ENDIF

    ; What is the max. no. of frames?
    max_frame = N_ELEMENTS(arrMap) - 1
        
    ; Let the user choose a frame
    ; Keep allowing this until they are done
    
    REPEAT BEGIN
        frame = PromptChoice(max_frame, PROMPT='Please choose a frame between 0 and ' + STRTRIM(max_frame, 2))

        IF frame NE !NULL THEN BEGIN
            LOADCT, 3

            ; Now plot the frame
            PLOT_IMAGE, arrMap[frame].data
        ENDIF
    ENDREP UNTIL frame EQ !NULL
END