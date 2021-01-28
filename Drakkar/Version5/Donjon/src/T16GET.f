*DECK T16GET
      SUBROUTINE T16GET(MAXMIX,MNLOCP,MNCPLP,MNPERT,NALOCP,IDLCPL,
     >                  NCMIXS,MNBURN,
     >                  NAMMIX,MIXRCI,PARRCI,MIXPER,PARPER,MIXREG)
*
*----
*  1- PROGRAMME STATISTICS:
*      NAME     : T16GET
*
*Purpose:
*  READ FROM INPUT T16CPO PROCESSING OPTIONS
*
*Author(s): 
* G.MARLEAU
*
*      CREATED  : 1999/10/21
*      REF      : IGE-244 REV.1
*
*      MODIFICATION LOG
*      --------------------------------------------------------------
*      | DATE AND INITIALS  | MOTIVATIONS
*      --------------------------------------------------------------
*      | 1999/10/21 G.M.    | READ FROM INPUT T16CPO
*      |                    | PROCESSING OPTIONS
*      --------------------------------------------------------------
*
*  2- ROUTINE PARAMETERS:
*Parameters: input
* MAXMIX  MAXIMUM NUMBER OF MIXTURE PERMITTED      I
* MNLOCP  MAXIMUM NUMBER OF LOCAL PARAMETERS       I
* MNCPLP  MAXIMUM NUMBER OF COUPLED  PARAMETERS    I
* MNPERT  MAXIMUM NUMBER OF PERTURBATION PER       I
*         LOCAL PARAMETERS
* NALOCP  LOCAL PARAMETER NAMES PERMITTED          C(MNLOCP
*                                                  +MNCPLP)*4
* IDLCPL  LOCAL PARAMETER ID FOR PERTURBATION      I(2,MNLOCP
*         PARAMETER                                  +MNCPLP)
*
*Parameters: input/output
* NCMIXS  NUMBER OF CURRENT MIXTURES SAVED         I
*         (I) OLD MIXTURE ALREADY SAVED
*         (O) TOTAL NUMBER OF MIXTURE SAVED
* MNBURN  MAXIMUNM NUMBER OF BURNUP STEPS          I
*         (I) OLD MAXIMUM
*         (O) NEW MAXIMUM
* NAMMIX  NAME OF MIXTURE                          I(2,MAXMIX)
*         (I) OLD MIXTURE NAMES ALREADY SAVED
*         (O) ALL MIXTURE NAMES TO SAVE
*         CONTAINS VARIABLE CHARACTER*6 NAME
*         READ(NAME,'(A4,A2)') (NAMMIX(J,*),J=1,2)
* MIXRCI  REFERENCE INFORMATION FOR A MIXTURE      I(2+MNLOCP+
*         (I) = 0 NO INFORMATION FOR MIXTURE  MNCPLP,MAXMIX)
*             > 0 INFORMATION FOR MIXTURE
*         (O) = 0 NO INFORMATION FOR MIXTURE
*             > 0 INFORMATION NOT UPDATED
*             < 0 INFORMATION TO BE UPDATED
* PARRCI  REFERENCE LOCAL PARAMETERS FOR A         R(MNLOCP,
*         MIXTURE                                    MAXMIX)
* MIXPER  PERTUBATION INFORMATION FOR A MIXTURE    I(MNPERT,
*                                      MNLOCP+MNCPLP,MAXMIX)
* PARPER  PERTURBATION PARAMETERS FOR A            R(MNPERT,2,
*         MIXTURE                      MNLOCP+MNCPLP,MAXMIX)
*
*Parameters: output
* MIXREG  MIXTURE UPDATE IDENTIFIER                I(MAXMIX)
*         =  0 DO NOT UPDATE
*         = -1 UPDATE USING CELLAV INFORMATION
*         >  0 UPDATE USING SPECIFIED REGION NUMBER
*
*  3- ROUTINES CALLED
*    UTILITIES ROUTINES
*      XABORT : ABORT ROUTINE
*      REDGET : FREE FORMAT READ
*  4- INPUT REQUIREMENTS
*    INPUT FORMAT
*    [[ MIXNAM [ { CELLAV | REGION noreg } ]
*    [ RC [ nburn ] frstrec ]
*    [[ NAMPER valref npert
*       (valper(i),frstrec(i),i=1,npert)]]
*    ]]
*    [ MTMD [ valreft valrefd ] npert
*       (valpert(i), valperd(i), frstrec(i),i=1,npert)]]
*    ]
*
*----
*
      IMPLICIT         NONE
      INTEGER          MAXMIX,MNLOCP,MNCPLP,MNPERT,NCMIXS,MNBURN
      CHARACTER        NALOCP(MNLOCP+MNCPLP)*4
      INTEGER          IDLCPL(2,MNLOCP+MNCPLP),NAMMIX(2,MAXMIX),
     >                 MIXRCI(2+MNLOCP+MNCPLP,MAXMIX),
     >                 MIXPER(MNPERT,MNLOCP+MNCPLP,MAXMIX),
     >                 MIXREG(MAXMIX)
      REAL             PARRCI(MNLOCP,MAXMIX),
     >                 PARPER(MNPERT,2,MNLOCP+MNCPLP,MAXMIX)
C----
C  READ VARIABLES
C----
      CHARACTER        TEXT12*12
      INTEGER          ITYPE,NITMA
      REAL             FLOTT
      DOUBLE PRECISION DFLOTT
C----
C  LOCAL VARIABLES
C----
      INTEGER          IOUT,NTC
      CHARACTER        NAMSBR*6
      PARAMETER       (IOUT=6,NTC=3,NAMSBR='T16GET')
      INTEGER          KCHAR(NTC),INEXTM,ILOCP,ILOCL,NLPAR,
     >                 ILPAR,NBRCI,IPAR,IMIX,IRLOC
C----
C  READ INPUT DATA.
C----
      INEXTM=0
 100  CONTINUE
      CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
 101  CONTINUE
      IF(ITYPE .NE. 3) CALL XABORT(NAMSBR//
     >  ': KEYWORD EXPECTED')
      IF(TEXT12 .EQ. ';') THEN
C----
C  END OF INPUT REACHED
C  EXIT READ
C----
        GO TO 105
      ELSE IF(TEXT12 .EQ. 'CELLAV') THEN
C----
C  CELLAV KEYWORD FOUND
C----
        IF(INEXTM .EQ. 0) CALL XABORT(NAMSBR//
     >  ': MIXTURE NAME MUST BE DEFINED BEFORE CELLAV')
        MIXREG(INEXTM)=-1
      ELSE IF(TEXT12 .EQ. 'REGION') THEN
C----
C  REGION KEYWORD FOUND
C----
        IF(INEXTM .EQ. 0) CALL XABORT(NAMSBR//
     >  ': MIXTURE NAME MUST BE DEFINED BEFORE REGION')
        CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
        IF(ITYPE .NE. 1) CALL XABORT(NAMSBR//
     >  ': REGION NUMBER MUST FOLLOW REGION KEYWORD')
        IF(NITMA .LT. 1) CALL XABORT(NAMSBR//
     >  ': REGION NUMBER MUST BE > 0')
        MIXREG(INEXTM)=NITMA
      ELSE IF(TEXT12 .EQ. 'RC') THEN
C----
C  REFERENCE CASE INFORMATION
C----
        IF(INEXTM .EQ. 0) CALL XABORT(NAMSBR//
     >  ': MIXTURE NAME MUST BE DEFINED RC')
        CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
        IF(ITYPE .NE. 1) CALL XABORT(NAMSBR//
     >  ': DATA TYPE FOLLOWING RC MUST BE INTEGER')
        IF(NITMA .LT. 1) CALL XABORT(NAMSBR//
     >  ': FIRST INTEGER VALUE FOLLOWING RC MUST BE > 0')
        MIXRCI(1,INEXTM)=NITMA
        IF(MIXRCI(2,INEXTM) .EQ. 0) THEN
          MIXRCI(2,INEXTM)=-1
        ENDIF
        CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
        IF(ITYPE .NE. 1) GO TO 101
        IF(NITMA .LT. 1) CALL XABORT(NAMSBR//
     >  ': SECOND INTEGER VALUE FOLLOWING RC MUST BE > 0')
        MNBURN=MAX(MNBURN,MIXRCI(1,INEXTM))
        MIXRCI(2,INEXTM)=-MIXRCI(1,INEXTM)
        MIXRCI(1,INEXTM)=NITMA
      ELSE
C----
C  EITHER PERTURBATION OR NEW MIXTURE
C  1) IF PERTURBATION
C     TREAT INPUT AND RETURN TO READ NEXT KEYWORD
C     OTHERWISE TEXT12 IS NEW MIXTURE NAME
C----
        IRLOC=2
        DO 110 ILOCP=1,MNLOCP+MNCPLP
          NLPAR=1
          IF(ILOCP .GT. MNLOCP) NLPAR=2
          IF(TEXT12 .EQ. NALOCP(ILOCP)) THEN
            IF(INEXTM .EQ. 0) CALL XABORT(NAMSBR//
     >      ': MIXTURE NAME REQUIRED FOR PERTURBATIONS')
C----
C  SAVE REFERENCE PARAMETER AND TEST FOR COHERENCE
C----
            CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
            IF(ITYPE .EQ. 2) THEN
              DO 120 ILPAR=1,NLPAR
                IF(ITYPE .NE. 2) CALL XABORT(NAMSBR//
     >          ': REFERENCES EXPECTED FOR PERTURBATIONS')
                ILOCL=IDLCPL(ILPAR,ILOCP)
                IF(MIXRCI(IRLOC+ILOCL,INEXTM) .EQ. 0) THEN
                  PARRCI(ILOCL,INEXTM)=FLOTT
                ELSE IF(PARRCI(ILOCL,INEXTM) .NE. FLOTT) THEN
                  CALL XABORT(NAMSBR//
     >            ': REFERENCE PARAMETER NOT COHERENT FOR '//
     >            NALOCP(ILOCP)//
     >            ' PERTURBATION INITIALIZATION')
                ENDIF
                CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
 120          CONTINUE
            ELSE IF( MIXRCI(IRLOC+ILOCP,INEXTM) .EQ. 0) THEN
              CALL XABORT(NAMSBR//
     >        ': REFERENCE CASE NOT INITIALIZED FOR '//
     >        NALOCP(ILOCP)//' PERTURBATION')
            ENDIF
C----
C  READ NUMBER OF PERTURBATIONS
C----
            IF(ITYPE .NE. 1) CALL XABORT(NAMSBR//
     >      ': INVALID RECORD FOLLOWING PERTURBATION')
            IF(NITMA .LT. 0) CALL XABORT(NAMSBR//
     >      ': NUMBER OF PERTURBATION MUST BE >= 0')
            NBRCI=NITMA
            MIXRCI(IRLOC+ILOCP,INEXTM)=-NITMA
C----
C  READ PERTURBATIONS PARAMETERS
C----
            DO 130 IPAR=1,NBRCI
              DO 131 ILPAR=1,NLPAR
                ILOCL=IDLCPL(ILPAR,ILOCP)
                CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
                IF(ITYPE .NE. 2) CALL XABORT(NAMSBR//
     >          ': INVALID RECORD FOR REFERENCE PARAMETER')
                PARPER(IPAR,ILPAR,ILOCP,INEXTM)=FLOTT
 131          CONTINUE
              CALL REDGET(ITYPE,NITMA,FLOTT,TEXT12,DFLOTT)
              IF(ITYPE .NE. 1) CALL XABORT(NAMSBR//
     >        ': INVALID RECORD FOLLOWING PERTURBATION')
              IF(NITMA .LT. 0) CALL XABORT(NAMSBR//
     >        ': NUMBER OF PERTURBATION MUST BE >= 0')
              MIXPER(IPAR,ILOCP,INEXTM)=NITMA
 130        CONTINUE
            GO TO 100
          ENDIF
 110    CONTINUE
C----
C  3) TEXT12 IS A NEW MIXTURE NAME
C     TREAT INPUT AND RETURN TO READ NEXT KEYWORD
C----
        READ(TEXT12,'(A4,A2)') KCHAR(1),KCHAR(2)
        DO 140 IMIX=1,NCMIXS
          IF(KCHAR(1) .EQ. NAMMIX(1,IMIX) .AND.
     >       KCHAR(2) .EQ. NAMMIX(2,IMIX) ) THEN
            INEXTM=IMIX
            GO TO 145
          ENDIF
 140    CONTINUE
        NCMIXS=NCMIXS+1
        NAMMIX(1,NCMIXS)=KCHAR(1)
        NAMMIX(2,NCMIXS)=KCHAR(2)
        IF(NCMIXS .GT. MAXMIX) CALL XABORT(NAMSBR//
     >  ': TOO MANY MIXTURES READ')
        INEXTM=NCMIXS
 145    CONTINUE
C----
C  ASSUME CELLAV BY DEFAULT
C----
        MIXREG(INEXTM)=-1
      ENDIF
      GO TO 100
 105  CONTINUE
C----
C  ALL THE REQUIRED INFORMATION READ
C  RETURN
C----
      RETURN
      END