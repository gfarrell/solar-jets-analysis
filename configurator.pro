; NAME:
;   CONFIGURATOR
;
; PURPOSE:
;   Configures various variables relating to the programmes herein
;
; AUTHOR:
;   Gideon Farrell <gtf21@cam.ac.uk>
;
; OUPUTS:
;   DATA_DIR   the directory events are stored in
;   DEMMAP_DIR the location of IGH's DEM library
;
PRO CONFIGURATOR, DATA_DIR=data_dir, DEMMAP_DIR=demmap_dir
    data_dir   = '/local/data/public/gtf21/sdo/aia'
    demmap_dir = '~/idl/lib/iain/demmap'
END