; NAME:
;   DATA2MOVIE
;
; PURPOSE:
;   Creates a movie from a map.
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   NONE
;
; OPTIONAL INPUTS:
;   colmap (number) the colour map to use, default: 3 (red)
;   anything that DLoad, MOVIE_MAP, take as well.
;
PRO DATA2MOVIE, COLMAP=colmap, _extra=extra, CUTOUT=cutout
    CONFIGURATOR, DATA_DIR=eventsDir

    IF NOT KEYWORD_SET(colmap) THEN colmap = 3

    arrMap = DLoad(_extra=extra)

    IF arrMap EQ !NULL THEN RETURN

    IF cutout NE !NULL THEN BEGIN
        SUB_MAP, arrMap, newMap, xrange=cutout[0:1], yrange=cutout[2:3]

        arrMap = newMap
    ENDIF

    ; Convert arrMap into a movie
    LOADCT, COLMAP
    MOVIE_MAP, arrMap, _extra=extra
END