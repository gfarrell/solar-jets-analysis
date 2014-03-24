;+
;
; Name        : Maps2Gif_Movie
;
; Purpose     : make series of GIF images from series of Dominic
;               Zarro's maps
;
; Explanation: A series of gif images are written (and left) in a
;              subdirecotry called 'gifframes'. These gif images are 
;              created by using the Z buffer and using plot_map.
;              whirlgif is then used to create the animation.
; 
; Category    : imaging
;
; Syntax      : maps2gif_movie,map, name
;
; Inputs      : MAP = array of map structures
;               NAME = output GIF movie name [def = test.gif]
;
; Keywords    : dmin,dmax: min and max values to scale data
;               SIZE = [min,max], dimensions of  movie (def= [512,512])
;               NOSCALE = If set, don't scale to min/max of all images (def=0)
;               STATUS = Returns 0/1 for failure/success
;               FRAMEDELAY: number of frames per second
;               (default=3). Set this to a high number to 'slow' the
;               movie.
;               There are also extra keywords passed to plot_map
;
; History     : Modified 5 Jan 2014 Gideon Farrell <gtf21@cam.ac.uk>
;               Written 17 March 2008 Giulio Del Zanna (GDZ)
;               Code written using a modification of MAP2GIF
;                
; Version: 1,  17 March 2008
; 
; Contact     : GDZ
;-

PRO maps2gif_movie,map, movie_name,dmin=dmin,dmax=dmax,_extra=extra, size=gsize, noscale=noscale, status=status, FRAMEDELAY=FRAMEDELAY, titles=titles, color_map=color_map

    status = 0

    IF NOT VALID_MAP(map) THEN BEGIN
        pr_syntax,'map2gif,map,names'
        RETURN
    ENDIF

    IF N_ELEMENTS(movie_name) EQ 0 THEN movie_name='test.gif'

    IF NOT TEST_DIR(CURDIR()) THEN RETURN
    
    WHIRLGIF_COMMAND = SSW_BIN('whirlgif', FOUND=FOUND)
    
    IF WHIRLGIF_COMMAND EQ '' THEN BEGIN
        MESSAGE, /INFORMATIONAL, 'Unable to create GIF movie -- whirlgif not found'
        RETURN
    ENDIF

    ; Make a temporary directory to hold the individual frames of the the movie
    ; with each frame stored as GIF file.  Begin by setting TMPDIR to the name
    ; of the tempory directory to create or clear.
    tmpdir = 'tmp/gifframes'

    ; Clear or add the directory as needed.
    ;
    IF FILE_EXIST(TMPDIR) THEN BEGIN
        RMFILES = CALL_FUNCTION('FILE_SEARCH', tmpdir + '/*', COUNT=RMCOUNT)
        IF RMCOUNT GT 0 THEN FILE_DELETE, RMFILES
    END ELSE MK_DIR, tmpdir
    
    ;
    ; Open a file for recording which GIFs we created.
    ;
    OPENW, GIFLST, tmpdir + "/giflist", /GET_LUN 


    ;-- create output names
    nmaps = N_ELEMENTS(map)

    IF nmaps EQ 1 THEN MESSAGE,' ONLY one map -- EXIT !'

    nframes = nmaps

    ;
    ; Set NDIGITS to the minimum field length required to display largest frame
    ; number.  Can't be less than 2, or whirlgif won't work.
    ;
	ndigits = (1 + FIX (ALOG10 (nframes))) > 2

    ;
    ; Set FRMT to a format string that will result in the frame number of each 
    ; frame using the same number of characters with 0's padding left side as
    ; needed.
    ;
    frmt = '(i' + STRING (NDIGITS) + '.' + STRING (NDIGITS) + ')'
    frmt = STRCOMPRESS(frmt, /REMOVE_ALL) 


    ids = TRIM(STR_FORMAT(SINDGEN(nmaps),'(i4.2)'))
    IF DATATYPE(prefix) EQ 'STR' THEN gfix = prefix ELSE gfix = 'frame'
    
    fnames = gfix+ids+'.gif'

    IF KEYWORD_SET(noscale) THEN drange = [0.,0.] ELSE BEGIN
        IF N_ELEMENTS(dmin) NE 1 THEN  dmin = MIN(map.data) 
        IF N_ELEMENTS(dmax) NE 1 THEN  dmax = MAX(map.data)
        drange = [dmin,dmax]
    ENDELSE

    psave = !d.name

    SET_PLOT, 'z', /COPY

    xsize   = 500 & ysize = 500
    ncolors = !d.table_size
    csave   = ncolors
    
    IF NOT EXIST(gsize) THEN zsize = [xsize,ysize] else $
      zsize = [gsize(0),gsize(n_elements(gsize)-1)]
    device,/close,set_resolution=zsize,set_colors=ncolors

    !p.color      = 0
    !p.background = ncolors-1

    FOR i = 0, nmaps-1 DO BEGIN
        IF N_ELEMENTS(titles) EQ nmaps THEN title=titles[i]

        LOADCT,0
        PLOT_MAP, map(i), drange=drange, _extra=extra, title=title, /nodata

        ; label_image, title, CHARSIZE=CHARSIZE 

        IF N_ELEMENTS(color_map) EQ 0 THEN color_map=3

        LOADCT, color_map

        PLOT_MAP, map(i), drange=drange, _extra=extra, /noxticks, /noyticks, /nolabels, /noerase, title=title


        temp = tvrd()
        device, /close

        TVLCT, rs, gs, bs, /get

        SSW_WRITE_GIF, tmpdir + '/' + fnames(i), temp, rs, gs, bs

        ; Write the file name into our list of GIFs.
        ;
        PRINTF, GIFLST, TMPDIR + '/' +fnames(i)

        PRINT, ' wrote ', TMPDIR + '/' +fnames(i)
    ENDFOR

    IF EXIST(psave) THEN SET_PLOT, psave
    IF EXIST(csave) THEN !p.color = csave

    FREE_LUN, GIFLST

    ; Set FRAMEDELAY and LOOPCNT to determine how the GIF will be displayed by
    ; netscape.
    ;
    IF NOT EXIST(FRAMEDELAY) THEN FRAMEDELAY = 3  ; 3 frames per second
    IF NOT EXIST(LOOPCNT) THEN LOOPCNT       = 0  ; Infinite repititions

    ;
    ; Create a unix command to make GIF movie from all of our gif frames
    ;
    CMD =  WHIRLGIF_COMMAND + " -loop " + STRING (LOOPCNT, FORMAT = FRMT)
    CMD = CMD + " -time " + STRING (FRAMEDELAY, FORMAT = FRMT)
    CMD = CMD + " -o " + movie_name + " -i "+ TMPDIR + "/giflist"

    ; other options: 
    ; -background  -trans 

    PRINT, 'executing:  ' + cmd 

    ;
    ;
    ; Spawn the command.
    ;

    SPAWN, CMD

    RETURN
END