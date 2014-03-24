FUNCTION SIGFIGS, n, sf
    n = DOUBLE(n)
    tens = CEIL(ALOG10(n))

    factor = - tens + sf

    reduced = n * 10.00 ^ (factor)

    rounded = DOUBLE(ROUND(reduced))

    final = rounded * 10.00 ^ (-factor)

    MESSAGE, /INFORMATIONAL, 'Tens = ' + STRTRIM(tens, 2)
    MESSAGE, /INFORMATIONAL, 'Factor = ' + STRTRIM(factor, 2)
    MESSAGE, /INFORMATIONAL, 'Reduced = ' + STRTRIM(reduced, 2)
    MESSAGE, /INFORMATIONAL, 'Rounded = ' + STRTRIM(rounded, 2)
    MESSAGE, /INFORMATIONAL, 'Final = ' + STRTRIM(final, 2)

    RETURN, final
END