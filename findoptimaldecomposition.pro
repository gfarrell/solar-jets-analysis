; NAME:
;   FindOptimalDecomposition
;
; PURPOSE:
;   Decomposes a number into the two closest factors to the square root
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; INPUTS:
;   N (number) the number to decompose
;
FUNCTION FindOptimalDecomposition, N
    a = FLOOR(SQRT(N))

    WHILE N MOD a NE 0 DO a = a - 1

    b = FIX(N / a)

    RETURN, [a, b]
END