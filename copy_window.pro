PRO COPY_WINDOW, original_index, new_index
    WSET, original_index
    i = TVRD()
    sz = SIZE(i)

    WINDOW, new_index, XSIZE=sz[1], YSIZE=sz[2]

    EXPAND_TV, i, sz[1], sz[2], 0, 0

    WSET, original_index
END