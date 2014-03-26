FUNCTION SIGFIGS, n, sf
    n = DOUBLE(n)
    tens = CEIL(ALOG10(n))

    factor = - tens + sf

    reduced = n * 10.00 ^ (factor)

    rounded = DOUBLE(ROUND(reduced))

    final = rounded * 10.00 ^ (-factor)

    RETURN, final
END