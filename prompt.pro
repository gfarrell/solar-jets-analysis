; NAME:
;   PROMPT
;
; PURPOSE:
;   Makes lots of user input stuff easier
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
FUNCTION Prompt, TEXT=txt, DEFAULT=dflt, ALLOWED=allowed, TYPE=type, MIN=min, MAX=max
    ; Autotype
    IF NOT KEYWORD_SET(type) THEN type = 'string'

    ; Add details to prompt
    IF NOT KEYWORD_SET(txt) THEN txt = ''
    IF type EQ 'number' THEN BEGIN
        IF KEYWORD_SET(min) AND KEYWORD_SET(max) THEN $
            txt = txt + ' (' + STRTRIM(min,2) + '-' + STRTRIM(max,2)+')' $
        ELSE IF KEYWORD_SET(min) THEN $
            txt = txt + ' (' + '> '+STRTRIM(min,2)+')' $
        ELSE IF KEYWORD_SET(max) THEN $
            txt = txt + ' (' + '< '+STRTRIM(max,2)+')'
    ENDIF
    IF KEYWORD_SET(dflt) THEN txt = txt + ' ['+STRTRIM(dflt,2)+']'

    txt = txt + ': '

    WHILE 1 DO BEGIN
        ; Get user input
        READ, choice, PROMPT=txt

        ; Check to see type conversion
        IF type EQ 'string' THEN $
            choice = STRTRIM(choice, 2) $
        ELSE IF type EQ 'number' THEN $
            choice = FIX(choice)

        ; If numeric, check to see if within min/max
        IF type EQ 'number' THEN BEGIN
            IF KEYWORD_SET(min) AND choice LT min THEN BEGIN
                MESSAGE, /INFORMATIONAL, 'Must be greater than ' + STRTRIM(min,2)
                CONTINUE
            ENDIF
            IF KEYWORD_SET(max) AND choice GT max THEN BEGIN
                MESSAGE, /INFORMATIONAL, 'Must be less than ' + STRTRIM(max,2)
            ENDIF
        ENDIF

        ; If some allowed values are set, then check we're within them
        IF KEYWORD_SET(allowed) THEN BEGIN
            IF WHERE(allowed EQ choice) EQ -1 THEN BEGIN
                MESSAGE, /INFORMATIONAL, 'Must be one of [' + STRJOIN(STRTRIM(allowed,2),', ')+']'
                CONTINUE
            ENDIF
        ENDIF

        ; If nothing is specified, revert to the default
        IF choice EQ '' OR choice EQ !NULL THEN choice = dflt
        BREAK
    ENDWHILE

    RETURN, choice
END