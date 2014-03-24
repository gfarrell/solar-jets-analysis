PRO SAVE_WINDOW, index, filename
    WSET, index

    TVLCT, R, G, B, /GET
    i = TVRD()

    WRITE_PNG, filename, i, R, G, B
END