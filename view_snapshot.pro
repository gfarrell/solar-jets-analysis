; NAME:
;   VIEW_SNAPSHOT
;
; PURPOSE:
;   Displays all of the filters in a snapshot in one image
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; OPTIONAL INPUTS:
;   event   (string) the event name
;   scale   (number) scaling factor for the images
;   notitle (flag)   if set won't add a title to the image
;
PRO VIEW_SNAPSHOT, EVENT=event, SCALE=s, NOTITLE=notitle, _EXTRA=_extra
    d = DLOAD(EVENT=event, FILE=file, SEARCH='_composite')

    LOADCT, 3

    titles = STREGEX(d.id, '([0-9]{2,4})', /EXTRACT) + 'A'

    IMAGES_LAYOUT, d, /MAPS, TITLES=titles, SCALE=s, XSIZE=x, YSIZE=y, _EXTRA=_extra

    cs = (1 + (s-1)/2)
    IF NOT KEYWORD_SET(notitle) THEN $
        XYOUTS, x/2, y-25, d[0].TIME, /DEVICE, CHARSIZE=cs, COLOR='fff'x, ALIGNMENT=0.5
END