; NAME:
;   PromptChoice
;
; PURPOSE:
;   Prompt the user to make a numeric choice.
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; CALLS:
;   None
;
; INPUTS:
;   choice_max (number) the maximum possible choice value
;
; OPTIONAL INPUTS:
;   prompt     (string)  a custom prompt to use (default to 'Please choose one')
;   choice_min (number)  the minimum possible choice value (defaults to 1)
;   required   (boolean) removes the option to exit if set
;
; OUTPUTS:
;   (number) the choice made by the user
;
FUNCTION PromptChoice, choice_max, prompt=prompt, choice_min=mn, REQUIRED=REQUIRED
    ; If prompt isn't specified, use default
    IF NOT KEYWORD_SET(prompt) THEN prompt = 'Please choose one'

    ; add exit instrux to prompt
    IF NOT KEYWORD_SET(REQUIRED) THEN prompt = prompt + ' (-1 to exit)'

    ; add colon and space to prompt
    prompt = prompt + ': '

    ; If no min value is specified, then use 1
    IF NOT KEYWORD_SET(mn) THEN mn = 1

    ; Read the user's choice
    valid = 0
    choice = ''
    WHILE valid EQ 0 DO BEGIN
        READ, choice, PROMPT=prompt
        choice = FIX(choice)

        ; Always use -1 to exit, unless answer is required
        IF NOT KEYWORD_SET(REQUIRED) THEN BEGIN
            IF choice EQ -1 THEN RETURN, !NULL
        ENDIF

        ; Validate choice
        IF (choice LT mn) OR (choice GT choice_max) THEN BEGIN
            PRINT, 'Invalid choice "' + STRTRIM(choice, 2) + '".'
            valid = 0
        ENDIF ELSE valid = 1
    ENDWHILE

    ; Return the answer

    RETURN, choice
END