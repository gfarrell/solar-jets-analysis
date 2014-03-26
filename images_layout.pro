; NAME:
;   IMAGES_LAYOUT
;
; PURPOSE:
;   Lays out a series of images or maps in a window
;   Can add titles if specified
;   Chooses optimal decomposition of the number of items into rows/columns
;   Can add a scale for maps
;   Resizes them to all be the same size as the first
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   images (array) the array of images or maps to lay out
;
; OPTIONAL INPUTS:
;   titles      (array)  an array of titles for the images
;   scale       (number) scale factor to enlarge images by
;   /LARGETEXT  (flag)   set if you want extra large text
;   /MAPS       (flag)   set if these are maps not images
;   /PREFERCOLS (flag)   set if columns are preferred to rows (default: rows)
;   save        (string) file to save an image to (PNG)
;
; OUTPUTS:
;   xsize       (number) width of window in pixels
;   ysize       (number) height of window in pixels
;   col_size    (number) # images per column
;   row_size    (number) # images per row
;
PRO IMAGES_LAYOUT, images, titles=titles, scale=scale, LARGETEXT=large_text, save=save, MAPS=flag_maps, PREFERCOLS=flag_cols, XSIZE=xsize, YSIZE=ysize, COL_SIZE=cols, ROW_SIZE=rows
    ; Decompose the count
    ; First value is shorter, second is longer
    s = SIZE(images)
    IF KEYWORD_SET(flag_maps) THEN img_count = s[1] ELSE img_count = s[3]
    MESSAGE, /INFORMATIONAL, 'Finding the right decomposition for ' + STRTRIM(img_count,2) + ' images.'
    layout = FindOptimalDecomposition(img_count)

    ; Prefer longer rows by default, but if flag is set, prefer longer cols
    ; NB: rows = # els per row, cols = # els per column, non-intuitive
    IF NOT KEYWORD_SET(flag_cols) THEN BEGIN
        rows = layout[1]
        cols = layout[0]
    ENDIF ELSE BEGIN
        rows = layout[0]
        cols = layout[1]
    ENDELSE

    ; If scale isn't set, make it 1
    IF NOT KEYWORD_SET(scale) THEN scale = 1

    ; Get the size of the first image
    ; We're using this to set the size for all the images henceforth
    IF KEYWORD_SET(flag_maps) THEN sz = SIZE(images[0].DATA) ELSE sz = SIZE(images[*,*,0])
    sz = sz * scale

    ; Text scaling
    txsz = sz[1]*0.005
    IF KEYWORD_SET(large_text) THEN txsz = txsz * 2
    txth = 1
    IF KEYWORD_SET(large_text) THEN txth = 1.5

    ; Create an appropriately sized window
    xsize = (sz[1] * rows)
    ysize = (sz[2] * cols)
    MESSAGE, /INFORMATIONAL, 'Creating a window for '+STRTRIM(rows,2)+'x'+STRTRIM(cols,2)+' at '+STRTRIM(xsize,2)+' x '+STRTRIM(ysize,2)+' px.'
    WINDOW, 0, XSIZE=xsize, YSIZE=ysize

    ; How many titles do we have?
    IF KEYWORD_SET(titles) THEN tcount = N_ELEMENTS(titles) ELSE tcount = 0

    ; Cycle over our row and col indices, placing images appropriately
    ; Also place titles while we're at it
    MESSAGE, /INFORMATIONAL, 'Drawing '+STRTRIM(img_count,2)+' images on '+STRTRIM(rows,2)+' x '+STRTRIM(cols,2)+' grid.'
    FOR r = 0, rows-1 DO BEGIN
        FOR c = 0, cols-1 DO BEGIN
            ; The index in the flat arrays
            i = r + c*rows

            MESSAGE, /INFORMATIONAL, 'Processing ['+STRTRIM(r,2)+', '+STRTRIM(c,2)+']'
            
            ; The coordinates of the image, NB origin at bottom-left
            x = r * sz[1]
            y = (cols - c - 1) * sz[2]

            ; Get the image
            IF KEYWORD_SET(flag_maps) THEN img = images[i].DATA ELSE img = images[*,*,i]

            ; Write the image to the window
            MESSAGE, /INFORMATIONAL, '- Drawing image at ('+STRTRIM(x,2)+', '+STRTRIM(y,2)+').'
            EXPAND_TV, img, sz[1], sz[2], x, y
            
            ; Write the title to the window if it exists
            IF i LT tcount THEN BEGIN
                t = titles[i]
                tx = FIX(x + sz[1]/10)
                ty = FIX(y + sz[2]/10)

                MESSAGE, /INFORMATIONAL, '- Drawing title "'+STRTRIM(t,2)+'" at ('+STRTRIM(tx, 2) + ', ' + STRTRIM(ty, 2) + ').'
                XYOUTS, FIX(x + sz[1]/10), FIX(y + sz[2]/10), STRTRIM(titles[i],2), COLOR='FFF'x, /DEVICE, CHARSIZE=txsz, CHARTHICK=txth
            ENDIF
        ENDFOR
    ENDFOR

    ; Save the image if requested
    IF KEYWORD_SET(save) THEN BEGIN
        SAVE_WINDOW, 0, save
    ENDIF
END