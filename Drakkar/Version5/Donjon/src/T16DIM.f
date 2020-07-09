*DECK T16DIM
      SUBROUTINE T16DIM(IFT16 ,IPRINT,MXGRP ,LSUBT ,ISUBT ,NEL   ,
     >                  NG    ,NGMTR ,NMATZ ,NM    ,MTRMSH,NFPR  ,
     >                  NZONE ,NREGON,NGREAC,NRCELA,NRREGI,
     >                  IFGMTR,IFGEDI)
C
C----
C  1- PROGRAMME STATISTICS:
C      NAME     : T16DIM
C      USE      : SCAN WIMS-AECL TAPE16 FILE
C                 FOR GENERAL DIMENSIONING INFORMATION
C      AUTHOR   : G.MARLEAU
C      CREATED  : 1999/10/22
C      REF      : EPM  IGE-244 REV.1
C                 EACL RC-1176 (COG-94-52)
C
C      MODIFICATION LOG
C      --------------------------------------------------------------
C      | DATE AND INITIALS  | MOTIVATIONS
C      --------------------------------------------------------------
C      | 1999/10/22 G.M.    | SCAN WIMS-AECL TAPE16 FILE
C      |                    | FOR GENERAL DIMENSIONING INFORMATION
C      --------------------------------------------------------------
C
C  2- ROUTINE PARAMETERS:
C    INPUT
C      IFT16  : TAPE16 FILE UNIT                         I
C      IPRINT : PRINT LEVEL                              I
C               =   0 NO PRINT
C               >=  1 PRINT RECORD TO READ
C               >= 10 PRINT ALL RECORD READ TO REACH
C                     REQUESTED RECORD
C      MXGRP  : MAXIMUM NUMBER OF GROUPS PERMITTED       I
C      LSUBT  : MAXIMUM LENGHT OF SUBTITLE               I
C    OUTPUT
C      ISUBT  : INTEGER VECTOR FOR TITLE                 I(LSUBT)
C      NEL    : NUMBER OF ISOTOPES ON THE CROSS SECTION  I
C               LIBRARY
C      NG     : NUMBER OF GROUPS ON CROSS SECTION        I
C               LIBRARY
C      NGMTR  : NUMBER OF MAIN TRANSPORT GROUP           I
C      NMATZ  : NUMBER OF MIXTURES                       I
C      NM     : NUMBER OF BURNABLE MATERIALS             I
C      MTRMSH : NUMBER OF MAIN TRANSPORT MESH POINTS     I
C      NFPR   : NUMBER OF FUEL PIN RINGS                 I
C      NZONE  : NUMBER OF ZONES                          I
C      NREGON : NUMBER OF EDIT REGIONS                   I
C      NGREAC : NUMBER OF EDIT GROUPS                    I
C      NRCELA : NUMBER OF CELLAV SETS OF RECORDS         I
C      NRREGI : NUMBER OF REGION SETS OF RECORDS         I
C      IFGMTR : FEWGROUPS FOR MAIN TRANSPORT             I(MXGRP)
C      IFGEDI : FEWGROUPS FOR EDIT                       I(MXGRP)
C
C  3- ROUTINES CALLED
C    SPECIFIC T16CPO ROUTINES
C      T16FND : FIND A TAPE16 RECORD
C               EQUIVALENT TO FIND FUNCTION
C               IN APPENDIX E OF EACL RC-1176
C    UTILITIES ROUTINES
C      XABORT : ABORT ROUTINE
C
C----
C
      IMPLICIT         NONE
      INTEGER          IFT16,IPRINT,MXGRP,LSUBT,NEL,NG,NGMTR,
     >                 NMATZ,NM,MTRMSH,NFPR,NZONE,NREGON,
     >                 NGREAC,NRCELA,NRREGI
      INTEGER          ISUBT(LSUBT),IFGMTR(MXGRP),IFGEDI(MXGRP)
C----
C  T16 KEYS
C----
      CHARACTER        CWVER*80,CLIBN*80,CASETL*128,
     >                 TKEY1*10,TKEY2*10,RKEY1*10,RKEY2*10,
     >                 CID*10
      INTEGER          NKEY,IOPT,NBE,NID,NJD,IR,JR
      REAL             RID
C----
C  LOCAL VARIABLES
C----
      INTEGER          IOUT
      CHARACTER        NAMSBR*6
      PARAMETER       (IOUT=6,NAMSBR='T16DIM')
C----
C  READ GENERAL TAPE16 INFORMATION
C----
      IOPT=0
      NKEY=1
      REWIND(IFT16)
C----
C  1) WIMS-AECL VERSION
C----
      TKEY1='PROCESSING'
      TKEY2='PROCESSING'
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,CWVER
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
      READ(CWVER,'(20A4)') (ISUBT(IR),IR=1,MIN(20,LSUBT))
C----
C  2) LIBRARY NAME
C----
      TKEY1='PROCESSING'
      TKEY2='PROCESSING'
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,
     >             (CLIBN(1+IR*8:8+IR*8),IR=0,9)
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
      READ(CLIBN,'(20A4)') (ISUBT(IR),IR=21,MIN(40,LSUBT))
C----
C  3) CASE TITLE
C----
      TKEY1='TITLE     '
      TKEY2='CARD      '
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,CASETL
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
      READ(CASETL,'(32A4)') (ISUBT(IR),IR=41,MIN(72,LSUBT))
C----
C  4) WIMS CONSTANTS
C----
      TKEY1='WIMS      '
      TKEY2='CONSTANTS '
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,NEL,NG,(NID,IR=1,8),NGMTR,
     >              (NID,IR=1,5),NMATZ,NM
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
C----
C  5) MAIN TRANSPORT GROUPS
C----
      TKEY1='MTR       '
      TKEY2='FEWGROUPS '
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,(IFGMTR(IR),IR=1,NGMTR)
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
C----
C  6) DIMENSION OF TRANSPORT MESH
C     PRESENT ONLY IF MTRFLX KEY ACTIVATED
C----
      TKEY1='MTRFLX    '
      TKEY2='FLUX      '
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,NID,MTRMSH
      ELSE
        REWIND(IFT16)
        MTRMSH=0
        IF(IPRINT .GE. 10)
     >  WRITE(IOUT,8000) NAMSBR,TKEY1,TKEY2,'MTRMSH',MTRMSH
      ENDIF
C----
C  7) NUMBER OF FUEL PIN RINGS
C     PRESENT ONLY FOR BURNUP CASES WITH CLUSTER GEOMETRY
C----
      TKEY1='CELLAV    '
      TKEY2='PINBURNUP '
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE
        NFPR=(NBE-1)/3
      ELSE
        REWIND(IFT16)
        NFPR=0
        IF(IPRINT .GE. 10)
     >  WRITE(IOUT,8000) NAMSBR,TKEY1,TKEY2,'NFPR  ',NFPR
      ENDIF
C----
C  8) NUMBER OF ZONES
C----
      TKEY1='REGION    '
      TKEY2='DESCRIPTON'
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,NZONE
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
C----
C  9) NUMBER OF EDIT REGIONS
C----
      TKEY1='REGION    '
      TKEY2='DIMENSIONS'
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,NREGON
      ELSE
        CALL XABORT(NAMSBR//': KEYS '//TKEY1//','//
     >              TKEY2//' NOT FOUND ON TAPE16')
      ENDIF
C----
C 10) NUMBER OF EDIT GROUPS
C     PRESENT ONLY IF REACTION KEY ACTIVATED
C----
      TKEY1='REACTION  '
      TKEY2='FLUX      '
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        READ(IFT16) RKEY1,RKEY2,NBE,(CID,IR=1,3),
     >             (NID,IR=1,2),NGREAC,
     >            ((RID,IR=1,NZONE),JR=1,NG),
     >             (IFGEDI(IR),IR=1,NGREAC)
      ELSE
        NGREAC=0
        IF(IPRINT .GE. 10)
     >  WRITE(IOUT,8000) NAMSBR,TKEY1,TKEY2,'NGREAC',NGREAC
      ENDIF
C----
C  FIND THE NUMBER OF SETS OF CELLAV RECORDS
C  BASED ON THE PRESENCE OF CELLAV,NGROUP KEYS
C  ALSO TEST FOR NGMTR CONSISTENCY
C----
      REWIND(IFT16)
      NRCELA=0
      TKEY1='CELLAV    '
      TKEY2='NGROUPS   '
 100  CONTINUE
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .EQ. 1) THEN
        NRCELA=NRCELA+1
        READ(IFT16) RKEY1,RKEY2,NBE,NID
        IF(NID .NE. NGMTR) THEN
          WRITE(IOUT,9000) NAMSBR,NGMTR,NRCELA,NID
          CALL XABORT(NAMSBR//': INVALID CELLAV STRUCTURE')
        ENDIF
        GO TO 100
      ELSE IF(NBE .EQ. -1) THEN
        GO TO 105
      ELSE
        WRITE(IOUT,9001) NAMSBR,1,NBE
        CALL XABORT(NAMSBR//': INVALID CELLAV STRUCTURE')
      ENDIF
 105  CONTINUE
C----
C  FIND THE NUMBER OF SETS OF REGION RECORD NRREGI
C  BASED ON THE PRESENCE OF REGION,DESCRIPTON KEYS
C  ALSO TEST FOR NZONE, NGMTR AND NREGON CONSISTENCY
C----
      REWIND(IFT16)
      NRREGI=0
      TKEY1='REGION    '
      TKEY2='DESCRIPTON'
 110  CONTINUE
      CALL T16FND(IFT16 ,IPRINT,IOPT  ,NKEY  ,TKEY1  ,TKEY2  ,
     >            NBE   )
      IF(NBE .GT. 0) THEN
        NRREGI=NRREGI+1
        READ(IFT16) RKEY1,RKEY2,NBE,NID
        IF(NID .NE. NZONE ) THEN
          WRITE(IOUT,9010) NAMSBR,NZONE,NRREGI,NID
          CALL XABORT(NAMSBR//': INVALID REGION STRUCTURE')
        ENDIF
        READ(IFT16) RKEY1,RKEY2,NBE,NID,NJD
        IF(NID .NE. NREGON ) THEN
          WRITE(IOUT,9010) NAMSBR,NREGON,NRREGI,NID
          CALL XABORT(NAMSBR//': INVALID REGION STRUCTURE')
        ENDIF
        IF(NJD .NE. NGMTR ) THEN
          WRITE(IOUT,9010) NAMSBR,NGMTR,NRREGI,NJD
          CALL XABORT(NAMSBR//': INVALID REGION STRUCTURE')
        ENDIF
        GO TO 110
      ELSE
        GO TO 115
      ENDIF
 115  CONTINUE
C----
C  PROCESS PRINT LEVEL
C----
      IF(IPRINT .GE. 10) THEN
        WRITE(IOUT,6000) NAMSBR,CASETL,CWVER,CLIBN
        WRITE(IOUT,6010) NEL,NG,NGMTR,NMATZ,NM,MTRMSH,
     >                   NFPR,NZONE,NREGON,NGREAC,NRCELA,NRREGI
        WRITE(IOUT,6001)
      ENDIF
      RETURN
C----
C  PRINT FORMAT
C----
 6000 FORMAT(1X,5('*'),' OUTPUT FROM ',A6,1X,5('*')/
     >       6X,'CONTENTS OF TAPE16 FILE :'/A128/
     >       6X,'WIMS-AECL VERSION = ',A80/
     >       6X,'LIBRARY VERSION   = ',A80)
 6001 FORMAT(1X,30('*'))
 6010 FORMAT(6X,'DIMENSIONING DATA '/
     >       6X,'NEL    : NB. ISOTOPES             = ',I10/
     >       6X,'NG     : NB. GROUPS               = ',I10/
     >       6X,'NGMTR  : NB. MAIN TRANSPORT GROUP = ',I10/
     >       6X,'NMATZ  : NB. MIXTURES             = ',I10/
     >       6X,'NM     : NB. BURNABLE MATERIALS   = ',I10/
     >       6X,'MTRMSH : NB. TRANSPORT MESH POINTS= ',I10/
     >       6X,'NFPR   : NB. FUEL PIN RINGS       = ',I10/
     >       6X,'NZONE  : NB. ZONES                = ',I10/
     >       6X,'NREGON : NB. EDIT REGIONS         = ',I10/
     >       6X,'NGREAC : NB. EDIT GROUPS          = ',I10/
     >       6X,'NRCELA : NB. CELLAV  RECORDS      = ',I10/
     >       6X,'NRREGI : NB. REGION  RECORDS      = ',I10)
C----
C  WARNING FORMAT
C----
 8000 FORMAT(1X,A6,1X,6('*'),' WARNING ',6('*')/
     >       8X,'RECORD WITH KEYS ',2(A10,2X),'NOT FOUND'/
     >       8X,'USE DEFAULT VALUE FOR ',A6,' = ',I10/
     >       8X,21('*'))
C----
C  ABORT FORMAT
C----
 9000 FORMAT(1X,A6,1X,7('*'),' ERROR ',7('*')/
     >       8X,6X,' NUMBER OF MAIN TRANSPORT GROUP ',I10/
     >       8X,I6,' CELLAV NGROUPS RECORD GIVES    ',I10/
     >       8X,21('*'))
 9001 FORMAT(1X,A6,1X,7('*'),' ERROR ',7('*')/
     >       8X,' NB ELEMENT ALLOWED ON CELLAV NGROUPS  ',I10/
     >       8X,' NB ELEMENT READ ON CELLAV NGROUPS      ',I10/
     >       8X,21('*'))
 9010 FORMAT(1X,A6,1X,7('*'),' ERROR ',7('*')/
     >       8X,6X,' NUMBER OF ZONES     ',I10/
     >       8X,I6,' REGION RECORD ',I10,' GIVES ',I10/
     >       8X,21('*'))
      END
