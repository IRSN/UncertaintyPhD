*DECK XCGGEO
      SUBROUTINE XCGGEO(IPGEOM,IROT,NSOUT,NVOL,NBAN,MNAN,NRT,MSROD,
     >                  IPRT,ILK,NMAT,RAN,NRODS,RODS,NRODR,RODR,NRINFO,
     >                  MATALB,VOLSUR,COTE,RADMIN,NCODE,ICODE,ZCODE,
     >                  ALBEDO,KEYMRG,NXRS,NXRI)
C
C----------------------------------------------------------------------
C
C 1-  SUBROUTINE STATISTICS:
C
C          NAME      -> XCGGEO
C          USE       -> READ AND ANALYSE 2-D CLUSTER GEOMETRY
C          DATE      -> 15-06-1990
C          AUTHOR    -> G. MARLEAU
C
C 2-  PARAMETERS:
C
C INPUT
C  IPGEOM  : POINTER TO THE GEOMETRY                     I
C  IROT    : TYPE OF PIJ RECONSTRUCTION                  I
C            IROT < 0 -> CP CALCULATIONS WITH SYMMETRIES
C            IROT = 0 -> CP CALCULATIONS
C            IROT = 1 -> DIRECT JPM RECONSTRUCTION
C            IROT=  2 -> ROT2 TYPE RECONSTRUCTION
C  NSOUT   : NUMBER OF OUTER SURFACE                     I
C  NVOL    : MAXIMUM NUMBER OF REGIONS                   I
C  NBAN    : NUMBER OF CONCENTRIC REGIONS                I
C  MNAN    : MAXIMUM NUMBER OF RADIUS TO READ            I
C  NRT     : NUMBER OF ROD TYPES                         I
C  MSROD   : MAXIMUM NUMBER OF SUBRODS PER RODS          I
C  IPRT    : IMPRESSION LEVEL                            I
C
C OUTPUT
C  ILK     : ILK=.TRUE. IF NEUTRON LEAKAGE THROUGH       L
C            EXTERNAL BOUNDARY IS PRESENT.
C  NMAT    : TOTAL NUMBER OF MATERIALS                   I
C  RAN     : RADIUS OF ANNULAR REGIONS                   R(NBAN)
C  NRODS   : INTEGER DESCRIPTION OF ROD OF A GIVEN TYPE  I(3,NRT)
C            NRODS(1,IRT) = NUMBER OF ROD
C            NRODS(2,IRT) = NUMBER OF SUBRODS IN ROD
C            NRODS(3,IRT) = FIRST CONCENTRIC REGION
C  RODS    : REAL DESCRIPTION OF ROD OF A GIVEN TYPE     R(2,NRT)
C            RODS(1,IRT) = ROD CENTER RADIUS
C            RODS(2,IRT) = ANGULAR POSITION OF FIRST ROD
C  NRODR   : SUBROD REGION                               I(NRT)
C  RODR    : SUBROD RADIUS                               R(MSROD,NRT)
C  NRINFO  : ANNULAR REGION CONTENT                      I(2,NBAN)
C            NRINFO(1,IAN) = NEW REGION NUMBER
C            NRINFO(2,IAN) = +I CLUSTER NUMBER        (ALL)
C                          = 1000000+I CLUSTER NUMBER CUT (IN)
C                          = 2000000+I CLUSTER NUMBER CUT (PART)
C                          = 3000000+I CLUSTER NUMBER CUT (OUT)
C                          = 0 NO CLUSTER ASSOCIATED
C                          = -I CLUSTER AT CENTER     (ALL)
C  MATALB  : ALBEDO-MATERIAL OF REGIONS                  I(-NSOUT:NVOL)
C  VOLSUR  : SURFACE/4-VOLUME OF REGIONS                 R(-NSOUT:NVOL)
C  COTE    : ADDITIONAL SIDE LENGTH FOR RECTANGLE        R
C  RADMIN  : MINIMUM RADIUS OF REGION                    R
C  NCODE   : ALBEDO TYPE                                 I(6)
C  ICODE   : ALBEDO NUMBER ASSOCIATED WITH FACE          I(6)
C  ZCODE   : ALBEDO ZCODE VECTOR                         R(6)
C  ALBEDO  : ALBEDO                                      R(6)
C  KEYMRG  : REGION-SURFACE MERGE VECTOR                 I(-NSOUT:NVOL)
C  NXRS    : INTEGER DESCRIPTION OF ROD OF A GIVEN TYPE  I(NRT)
C            LAST CONCENTRIC REGION
C  NXRI    : ANNULAR REGION CONTENT MULTI-ROD            I(NRT,NBAN)
C
C----------------------------------------------------------------------
C
      USE        GANLIB
      IMPLICIT   NONE
      INTEGER    IOUT,NSTATE,NMCOD
      REAL       PI,THSQ3
      PARAMETER (IOUT=6,NSTATE=40,NMCOD=6,PI=3.1415926535898,
     >           THSQ3=2.598076212)
      CHARACTER  NAMSBR*6
      PARAMETER (NAMSBR='XCGGEO')
*-----
*  ROUTINE PARAMETERS
*----
      TYPE(C_PTR) IPGEOM
      LOGICAL    ILK,EMPTY,LCM
      INTEGER    IROT,NSOUT,NVOL,NBAN,MNAN,NRT,MSROD,IPRT,
     >           NMAT,NRODS(3,NRT),NRODR(NRT),NRINFO(2,NBAN),
     >           MATALB(-NSOUT:NVOL),NCODE(NMCOD),ICODE(NMCOD),
     >           KEYMRG(-NSOUT:NVOL),NXRS(NRT),NXRI(NRT,NBAN)
      REAL       RAN(NBAN),RODS(2,NRT),RODR(MSROD,NRT),
     >           VOLSUR(-NSOUT:NVOL),COTE,RADMIN,ALBEDO(NMCOD),
     >           ZCODE(NMCOD)
*----
*  LOCAL VARIABLES
*----
      INTEGER    ISTATE(NSTATE)
      CHARACTER  GEONAM*12,TEXT12*12,CMSG*131
      INTEGER    IRT,IAN,IS,IC,ITRAN,I,NRANN,NRRANN,NSPLIT,ISA,ILSTP,
     >           ISPL,ISURW,NTAN,IPOS,ITYPE,IM,ISR,IZRT,JAN,JRT,KRT,
     >           ILR,JSUR,JSW,ISV,ILSTR,JPRT,LRT,IREG,ILONG
      REAL       RADL,RADN,VFIN,DELV,XTOP,XBOT,VOLI,VOLROD,VOLF,
     >           VOLIS,XNROD,VOLFS,VANSPI,VRPSPI,VRDSPI,XINT,
     >           YINT,ANGR,ANGA,VRGOU1,VRGIN1
      INTEGER, ALLOCATABLE, DIMENSION(:) :: MATANN,ISPLIT,JGEOM
      INTEGER, ALLOCATABLE, DIMENSION(:,:) :: MATROD
      REAL, ALLOCATABLE, DIMENSION(:) :: RAD
      REAL, ALLOCATABLE, DIMENSION(:,:) :: VRGIO
C----
C  SCRATCH STORAGE ALLOCATION
C   MATANN  : TYPE OF MATERIAL FOR ANNULAR REGIONS        I(NBAN)
C   MATROD  : TYPE OF MATERIAL FOR EACH SUBROD            I(MSROD,NRT)
C   ISPLIT  : SPLITTING VECTOR FOR RODS                   I(NBAN)
C   RAD     : RADIUS VECTOR                               R(MNAN)
C   VRGIO   : DIVIDED ROD VOLUME                          R(2,NRT)
C           : 2 - INSIDE REGION
C           : 1 - OUTSIDE REGION
C----
      ALLOCATE(MATANN(NBAN),MATROD(MSROD,NRT),ISPLIT(NBAN))
      ALLOCATE(RAD(MNAN),VRGIO(2,NRT))
C----
C  INITIALIZE NRINFO, NXRI AND NXRS TO 0
C----
      DO 3 IRT=1,NRT
        NXRS(IRT)=0
        NRODR(IRT)=0
 3    CONTINUE
      DO 4 IAN=1,NBAN
        NRINFO(1,IAN)=0
        NRINFO(2,IAN)=0
        DO 5 IRT=1,NRT
          NXRI(IRT,IAN)=0
 5      CONTINUE
 4    CONTINUE
      DO 6 IS=-NSOUT,NVOL
        KEYMRG(IS)=IS
 6    CONTINUE
      VOLSUR(0)=0.0
      MATALB(0)=0
C----
C  READ GEOMETRY INFORMATIONS
C----
      CALL XDISET(ISTATE,NSTATE,0)
      CALL LCMGET(IPGEOM,'STATE-VECTOR',ISTATE)
C----
C  RECOVER THE BOUNDARY CONDITIONS.
C----
      CALL LCMGET(IPGEOM,'NCODE',NCODE)
      CALL LCMGET(IPGEOM,'ZCODE',ALBEDO)
      CALL LCMGET(IPGEOM,'ICODE',ICODE)
      DO 7 IC=1,NMCOD
        ZCODE(IC)=ALBEDO(IC)
        IF(ICODE(IC).NE.0) CALL XABORT(NAMSBR//
     >': MACROLIB DEFINED ALBEDOS ARE NOT IMPLEMENTED.')
 7    CONTINUE
      ITRAN=0
      DO 100 I=1,NMCOD
        IF ((NCODE(I) .EQ. 3) .OR. (NCODE(I) .EQ. 5) .OR.
     >      (NCODE(I) .GE. 7)) THEN
          CALL XABORT(NAMSBR//': INVALID TYPE OF B.C.')
        ELSE IF(NCODE(I).EQ.2) THEN
          ZCODE(I)=1.0
          ALBEDO(I)=1.0
        ELSE IF(NCODE(I).EQ.4) THEN
          ITRAN=ITRAN+1
          ZCODE(I)=1.0
          ALBEDO(I)=1.0
        ELSE IF(NCODE(I).EQ.6) THEN
           NCODE(I)=1
        ENDIF
 100  CONTINUE
      IF(NSOUT.EQ.1.AND.IROT.GT.-400) THEN
        MATALB(-1)=-2
        IF (NCODE(2).EQ.0)
     >    CALL XABORT(NAMSBR//': ANNULAR BOUNDARY CONDITION MISSING.')
        IF(ITRAN.NE.0) THEN
           NCODE(2)=2
        ENDIF
        IF(ICODE(2).EQ.0) ICODE(2)=-2
        ILK=( (NCODE(2).EQ.1) .OR. (ZCODE(2).NE.1.0) )
      ELSE IF(NSOUT.EQ.6.OR.IROT.LT.-600) THEN
        IF(ITRAN.NE.0) THEN
           NCODE(1)=2
        ENDIF
        IF(IROT.LT.0) THEN
          MATALB(-1)=-1
        ELSE
          MATALB(-1)=-1
          DO 101 IS=2,6
            ZCODE(IS)=ZCODE(1)
            MATALB(-IS)=-1
 101      CONTINUE
        ENDIF
        IF (NCODE(1).EQ.0) CALL XABORT(NAMSBR//
     >    ': HEXAGONAL BOUNDARY CONDITION MISSING.')
        IF(ICODE(1).EQ.0) ICODE(1)=-1
        ILK=( (NCODE(1).EQ.1) .OR. (ZCODE(1).NE.1.0) )
      ELSE
        IF(IROT.LT.0) THEN
          IF(ITRAN.NE.0) CALL XABORT(NAMSBR//
     >    ': CARTESIAN SYMMETRY NO TRANSLATION BOUNDARY CONDITIONS')
          IF(ZCODE(1).NE.ZCODE(2).OR.ZCODE(1).NE.ZCODE(3).OR.
     >       ZCODE(1).NE.ZCODE(4)) CALL XABORT(NAMSBR//
     >    ': CARTESIAN SYMMETRY REQUIRES '//
     >    ' IDENTICAL BOUNDARY CONDITION IN ALL DIRECTIONS.')
          MATALB(-1)=-1
          IF (NCODE(1).EQ.0) CALL XABORT(NAMSBR//
     >      ': CARTESIAN BOUNDARY CONDITION MISSING.')
          IF(ICODE(1).EQ.0) ICODE(1)=-1
          ILK=( (NCODE(1).EQ.1) .OR. (ZCODE(1).NE.1.0) )
        ELSE
          MATALB(-1)=-2
          MATALB(-2)=-4
          MATALB(-3)=-1
          MATALB(-4)=-3
          ZCODE(5)=ZCODE(1)
          ZCODE(1)=ZCODE(2)
          ZCODE(2)=ZCODE(4)
          ZCODE(4)=ZCODE(3)
          ZCODE(3)=ZCODE(5)
          ILK=.FALSE.
          DO 102 IS=1,NSOUT
            IF (NCODE(IS).EQ.0) CALL XABORT(NAMSBR//
     >      ': RECTANGLE BOUNDARY CONDITION MISSING.')
            IF(.NOT. ILK) THEN
              IF( (NCODE(IS).EQ.1) .OR. (ZCODE(IS).NE.1.0) ) THEN
                ILK=.TRUE.
              ENDIF
            ENDIF
            IF(ICODE(IS).EQ.0) ICODE(IS)=-IS
 102      CONTINUE
          IF(ITRAN .GT. 0) THEN
            IF(MOD(ITRAN,2) .EQ. 1) CALL XABORT(NAMSBR//
     >        ': TRANSLATION SYMMETRIES COME IN PAIRS')
            IF((NCODE(1) .EQ. 4) .AND. (NCODE(2) .EQ. 4)) THEN
              ITRAN=ITRAN-2
            ENDIF
            IF((NCODE(3) .EQ. 4) .AND. (NCODE(4) .EQ. 4)) THEN
              ITRAN=ITRAN-2
            ENDIF
            IF(ITRAN .NE. 0) CALL XABORT(NAMSBR//
     >        ': WRONG PAIRS OF TRANSLATION SYMMETRIES')
          ENDIF
        ENDIF
      ENDIF
C----
C  RECOVER THE MIXTURE FOR ANNULAR REGIONS
C----
      NRANN=ISTATE(6)
      CALL LCMGET(IPGEOM,'MIX',MATANN)
      NMAT=0
      DO 110 I=1,NRANN
        NMAT=MAX(NMAT,MATANN(I))
 110  CONTINUE
C----
C  RECOVER THE MESH COORDINATES
C----
      IF((IROT.LT.-400).OR.(NSOUT.GT.1)) THEN
        NRRANN=NRANN-1
        MATANN(NBAN)=MATANN(NRANN)
      ELSE
        NRRANN=NRANN
      ENDIF
      CALL LCMGET(IPGEOM,'RADIUS',RAD)
      IF(ISTATE(11).EQ.1) THEN
C----
C  SPLIT ANNULUS WHEN REQUIRED
C----
        CALL LCMLEN(IPGEOM,'SPLITR',ILONG,ITYPE)
        IF(ILONG.GT.NBAN) CALL XABORT(NAMSBR//': SPLITR OVERFLOW')
        CALL LCMGET(IPGEOM,'SPLITR',ISPLIT)
        NSPLIT=0
        DO 145 ISA=1,NRRANN
          NSPLIT=NSPLIT+ABS(ISPLIT(ISA))
 145    CONTINUE
        ILSTP=NSPLIT
        RADL=RAD(NRRANN+1)
        DO 155 ISA=NRRANN,1,-1
          RADN=RAD(ISA)
          RAN(ILSTP)=RADL
          MATANN(ILSTP)=MATANN(ISA)
          IF(ISPLIT(ISA).LT.0) THEN
C----
C  ANNULUS EQUAL VOLUMES SPLIT
C----
            VFIN=RADL*RADL
            DELV=(VFIN-RADN*RADN)/FLOAT(ABS(ISPLIT(ISA)))
            DO 165 ISPL=ABS(ISPLIT(ISA))-1,1,-1
              ILSTP=ILSTP-1
              VFIN=VFIN-DELV
              RAN(ILSTP)=SQRT(VFIN)
              MATANN(ILSTP)=MATANN(ISA)
 165        CONTINUE
          ELSE IF(ISPLIT(ISA).GT.0) THEN
C----
C  ANNULUS EQUAL TICKNESS SPLIT
C----
            VFIN=RADL
            DELV=(VFIN-RADN)/FLOAT(ISPLIT(ISA))
            DO 175 ISPL=ISPLIT(ISA)-1,1,-1
              ILSTP=ILSTP-1
              VFIN=VFIN-DELV
              RAN(ILSTP)=VFIN
              MATANN(ILSTP)=MATANN(ISA)
 175        CONTINUE
          ELSE
            CALL XABORT(NAMSBR//': A SPLIT OF 0 IS INVALID')
          ENDIF
          RADL=RADN
          ILSTP=ILSTP-1
 155    CONTINUE
      ELSE
        DO 20 IAN=1,NRRANN
          RAN(IAN)=RAD(IAN+1)
 20     CONTINUE
      ENDIF
      RADMIN=RAN(1)
      NTAN=NBAN
      IF(NSOUT.EQ.1.AND.IROT.GT.-400) THEN
        VOLSUR(-1)=0.5*PI*RAN(NBAN)
      ELSE IF(NSOUT.EQ.6.OR.IROT.LT.-600) THEN
        CALL LCMGET(IPGEOM,'SIDE',RAN(NBAN))
        NTAN=NBAN-1
        IF(IROT.LT.0) THEN
          VOLSUR(-1)=1.5*RAN(NBAN)
        ELSE
          VOLSUR(-1)=0.25*RAN(NBAN)
          DO 30 ISURW=-2,-6,-1
            VOLSUR(ISURW)=VOLSUR(-1)
 30       CONTINUE
        ENDIF
      ELSE
        CALL LCMGET(IPGEOM,'MESHX',RAD(1))
        CALL LCMGET(IPGEOM,'MESHY',RAD(3))
        RAN(NBAN)=RAD(2)-RAD(1)
        COTE=RAD(4)-RAD(3)
        NTAN=NBAN-1
        IF(IROT.LT.0) THEN
          IF(RAN(NBAN).NE.COTE) CALL XABORT(NAMSBR//
     >    ': CARTESIAN SYMMETRY REQUIRES  SQUARE CELL.')
          VOLSUR(-1)=COTE
        ELSE
          VOLSUR(-1)=0.25*COTE
          VOLSUR(-2)=0.25*RAN(NBAN)
          VOLSUR(-3)=VOLSUR(-1)
          VOLSUR(-4)=VOLSUR(-2)
        ENDIF
      ENDIF
C----
C  READ CLUSTER GEOMETRY AND ANALYSE
C----
      ALLOCATE(JGEOM(3*NRT))
      IPOS=1
      CALL LCMGET(IPGEOM,'CLUSTER',JGEOM)
C----
C  READ ROD DESCRIPTION AND SAVE
C----
      DO 120 IRT=1,NRT
        WRITE(TEXT12(1:4),'(A4)')  JGEOM(IPOS)
        WRITE(TEXT12(5:8),'(A4)')  JGEOM(IPOS+1)
        WRITE(TEXT12(9:12),'(A4)') JGEOM(IPOS+2)
        IPOS=IPOS+3
        CALL LCMSIX(IPGEOM,TEXT12,1)
        CALL XDISET(ISTATE,NSTATE,0)
        CALL LCMGET(IPGEOM,'STATE-VECTOR',ISTATE)
        CALL LCMGET(IPGEOM,'MIX',MATROD(1,IRT))
        CALL LCMLEN(IPGEOM,'RADIUS',NRODS(2,IRT),ITYPE)
        CALL LCMGET(IPGEOM,'NPIN',NRODS(1,IRT))
        CALL LCMGET(IPGEOM,'RPIN',RODS(1,IRT))
        CALL LCMGET(IPGEOM,'APIN',RODS(2,IRT))
        NRODS(2,IRT)=NRODS(2,IRT)-1
        CALL LCMGET(IPGEOM,'RADIUS',RAD)
        DO 121 IM=1,NRODS(2,IRT)
          RODR(IM,IRT)=RAD(IM+1)
          NMAT=MAX(NMAT,MATROD(IM,IRT))
 121    CONTINUE
        IF(ISTATE(11).EQ.1) THEN
C----
C  SPLIT RODS WHEN REQUIRED
C----
          CALL LCMLEN(IPGEOM,'SPLITR',ILONG,ITYPE)
          IF(ILONG.GT.NBAN) CALL XABORT(NAMSBR//': SPLITR OVERFLOW')
          CALL LCMGET(IPGEOM,'SPLITR',ISPLIT)
          NSPLIT=0
          DO 140 ISR=1,NRODS(2,IRT)
            NSPLIT=NSPLIT+ABS(ISPLIT(ISR))
 140      CONTINUE
          ILSTP=NSPLIT
          RADL=RODR(NRODS(2,IRT),IRT)
          DO 150 ISR=NRODS(2,IRT),1,-1
            IF(ISR.EQ.1) THEN
              RADN=0.0
            ELSE
              RADN=RODR(ISR-1,IRT)
            ENDIF
            IF(ISPLIT(ISR).LT.0) THEN
C----
C  RODS EQUAL VOLUMES SPLIT
C----
              RODR(ILSTP,IRT)=RADL
              MATROD(ILSTP,IRT)=MATROD(ISR,IRT)
              VFIN=RADL*RADL
              DELV=(VFIN-RADN*RADN)/FLOAT(ABS(ISPLIT(ISR)))
              DO 160 ISPL=ABS(ISPLIT(ISR))-1,1,-1
                ILSTP=ILSTP-1
                VFIN=VFIN-DELV
                RODR(ILSTP,IRT)=SQRT(VFIN)
                MATROD(ILSTP,IRT)=MATROD(ISR,IRT)
 160          CONTINUE
            ELSE IF(ISPLIT(ISR).GT.0) THEN
C----
C  RODS EQUAL TICKNESS SPLIT
C----
              RODR(ILSTP,IRT)=RADL
              MATROD(ILSTP,IRT)=MATROD(ISR,IRT)
              VFIN=RADL
              DELV=(VFIN-RADN)/FLOAT(ISPLIT(ISR))
              DO 170 ISPL=ISPLIT(ISR)-1,1,-1
                ILSTP=ILSTP-1
                VFIN=VFIN-DELV
                RODR(ILSTP,IRT)=VFIN
                MATROD(ILSTP,IRT)=MATROD(ISR,IRT)
 170          CONTINUE
            ELSE
              CALL XABORT(NAMSBR//': A SPLIT OF 0 IS INVALID')
            ENDIF
            RADL=RADN
            ILSTP=ILSTP-1
 150      CONTINUE
          NRODS(2,IRT)=NSPLIT
        ENDIF
        RADMIN=MIN(RADMIN,RODR(1,IRT))
        CALL LCMSIX(IPGEOM,' ',2)
 120  CONTINUE
C----
C  CHECK ROD GEOMETRY AND REORDER IF NECESSARY
C----
      CALL XCGROD(NRT,MSROD,NRODS,RODS,MATROD,RODR)
C----
C  LOCALIZE ROD POSITION WITH RESPECT TO ANNULUS
C----
      IZRT=0
      DO 122 IRT=1,NRT
        XTOP=RODS(1,IRT)+RODR(NRODS(2,IRT),IRT)
        XBOT=RODS(1,IRT)-RODR(NRODS(2,IRT),IRT)
        IF((XBOT.LT.0.0).AND.(NRODS(1,IRT).GT.1)) THEN
          CALL XABORT(NAMSBR//': OVERLAPPING RODS')
        ELSE IF(RODS(1,IRT).EQ.0.0) THEN
          IF(RODR(NRODS(2,IRT),IRT).LE.RAN(1)) THEN
            NRODS(3,IRT)=-1
            NXRS(IRT)=-1
            NXRI(IRT,1)=-1
            NRINFO(2,1)=-IRT
          ELSE
            CALL XABORT(NAMSBR//': CENTRAL ROD OVERLAPP WITH ANNULUS')
          ENDIF
        ELSE
C----
C  SEARCH IN ANNULUS SINCE RODS MAY NOT BE LOCATED IN
C  SQUARE OR HEXAGONAL CROWN WHERE NTAN=NBAN-1
C----
          JAN=0
          KRT=0
          DO 130 IAN=1,NTAN
            JAN=IAN
            IF(XBOT.LE.RAN(IAN)) THEN
              NRODS(3,IRT)=IAN
              NXRS(IRT)=IAN
              NRINFO(2,IAN)=IRT
              DO 134 JRT=1,NRT
                KRT=JRT
                IF(NXRI(KRT,IAN).EQ.0) THEN
                  NXRI(KRT,IAN)=IRT
                  IZRT=MAX(IZRT,KRT)
                  GO TO 131
                ENDIF
 134          CONTINUE
            ENDIF
 130      CONTINUE
          WRITE(CMSG,9001) NAMSBR,IRT
          CALL XABORT(CMSG)
 131      CONTINUE
          IF(XTOP.GT.RAN(JAN)) THEN
            NXRI(KRT,IAN)=IRT+1000000
            DO 132 IAN=JAN+1,NTAN
              IF(XTOP.LE.RAN(IAN)) THEN
                NXRS(IRT)=IAN
                NRINFO(2,IAN)=IRT
                DO 135 JRT=1,NRT
                  KRT=JRT
                  IF(NXRI(KRT,IAN).EQ.0) THEN
                    NXRI(KRT,IAN)=IRT+3000000
                    IZRT=MAX(IZRT,KRT)
                    GO TO 133
                  ENDIF
 135            CONTINUE
              ELSE
                NXRS(IRT)=IAN
                NRINFO(2,IAN)=IRT
                DO 136 JRT=1,NRT
                  KRT=JRT
                  IF(NXRI(KRT,IAN).EQ.0) THEN
                    NXRI(KRT,IAN)=IRT+2000000
                    IZRT=MAX(IZRT,KRT)
                    GO TO 137
                  ENDIF
 136            CONTINUE
 137            CONTINUE
              ENDIF
 132        CONTINUE
            WRITE(CMSG,9001) NAMSBR,IRT
            CALL XABORT(CMSG)
 133        CONTINUE
          ENDIF
        ENDIF
C----
C  GEOMETRY CANNOT BE TRACKED BY JPM
C---
        IF(IROT.GT.0.AND.IZRT.GT.1) CALL XABORT(NAMSBR//
     >  ': ROD OVERLAPP -- JPM CAN NOT TRACK THIS GEOMETRY')
 122  CONTINUE
C----
C  CHECK FOR VALID CLUSTER IN JPM TRACKING
C----
      IF(IROT.GT.0) THEN
        DO  180 IAN=1,NTAN
          ILR=NRINFO(2,IAN)
          IF(ILR.GT.0) THEN
            IF(NXRI(1,IAN).NE.ILR) CALL XABORT(NAMSBR//
     >      ': ANNULUS OVERLAP PIN -- JPM CAN NOT TRACK THIS GEOMETRY')
          ENDIF
 180    CONTINUE
      ENDIF
      DEALLOCATE(JGEOM)
      IF(IPRT.GT.2) THEN
        WRITE(IOUT,6010)
        DO 600 IAN=1,NTAN
          IF((NRINFO(2,IAN).EQ.0).OR.
     >       (NRINFO(2,IAN).EQ.NXRI(1,IAN))) THEN
            WRITE(IOUT,6013) IAN,NRINFO(2,IAN),
     >                   RAN(IAN),MATANN(IAN)
          ELSE
            DO 601 IRT=1,NRT
              IF(NXRI(IRT,IAN).EQ.0) GO TO 602
              WRITE(IOUT,6013) IAN,NXRI(IRT,IAN),
     >                     RAN(IAN),MATANN(IAN)
 601        CONTINUE
          ENDIF
 602      CONTINUE
 600    CONTINUE
        IF(NSOUT.EQ.6.OR.IROT.LT.-600) THEN
          WRITE(IOUT,6030) NBAN,NRINFO(2,NBAN),RAN(NBAN),MATANN(NBAN)
        ELSE IF(NSOUT.EQ.4.OR.IROT.LT.-400) THEN
          WRITE(IOUT,6040) NBAN,NRINFO(2,NBAN),RAN(NBAN),
     >                       COTE,MATANN(NBAN)
        ENDIF
        WRITE(IOUT,6021) (4.0*VOLSUR(JSUR),JSUR=-1,-NSOUT,-1)
        WRITE(IOUT,6022) (ICODE(-MATALB(JSUR)),JSUR=-1,-NSOUT,-1)
        WRITE(IOUT,6023) (-JSW,ALBEDO(JSW),JSW=1,NMCOD)
        WRITE(IOUT,6011) (IRT,NRODS(1,IRT),NRODS(2,IRT),NRODS(3,IRT),
     >               NXRS(IRT),RODS(1,IRT),RODS(2,IRT),IRT=1,NRT)
        WRITE(IOUT,6012) ((IRT,ISR,RODR(ISR,IRT),MATROD(ISR,IRT),
     >                ISR=1,NRODS(2,IRT)),IRT=1,NRT)
      ENDIF
C----
C  FILL IN VOLSUR AND MATALB VECTORS
C----
      VOLI=0.0
      IPOS=0
      VOLFS=0.0
      DO 200 IAN=1,NTAN
        VOLROD=0.0
        VOLF=PI*RAN(IAN)*RAN(IAN)
        IF(NRINFO(2,IAN).NE.0) THEN
          IF(NRINFO(2,IAN).EQ.NXRI(1,IAN)) THEN
            VOLIS=0.0
            IRT=ABS(NRINFO(2,IAN))
            XNROD=FLOAT(NRODS(1,IRT))
            DO 202 ISV=1,NRODS(2,IRT)
              IPOS=IPOS+1
              VOLFS=PI*RODR(ISV,IRT)*RODR(ISV,IRT)*XNROD
              VOLSUR(IPOS)=VOLFS-VOLIS
              MATALB(IPOS)=MATROD(ISV,IRT)
              VOLIS=VOLFS
 202        CONTINUE
            NRODR(IRT)=IPOS
            VOLROD=VOLROD+VOLFS
          ELSE
            DO 210 IRT=1,NRT
              JRT=ABS(NXRI(IRT,IAN))
              IF(JRT.LT.1000000.AND.JRT.GT.0) THEN
                XNROD=FLOAT(NRODS(1,JRT))
                VOLIS=0.0
                ILSTR=NRODS(2,JRT)
                DO 211 ISV=1,ILSTR
                  IPOS=IPOS+1
                  VOLFS=PI*RODR(ISV,JRT)*RODR(ISV,JRT)*XNROD
                  VOLSUR(IPOS)=(VOLFS-VOLIS)
                  MATALB(IPOS)=MATROD(ISV,JRT)
                  VOLIS=VOLFS
 211            CONTINUE
                NRODR(JRT)=IPOS
                VOLROD=VOLROD+VOLFS
              ELSE IF(JRT.GT.0) THEN
C----
C  ANNULUS INTERSECT RODS
C  1) FIND X (XINT) AND Y (YINT) INTERSECTION
C     XINT=(RAN**2+RPIN**2-RODR**2)/(2*RPIN)
C     YINT=SQRT(RAN**2-XINT**2)
C  2) FIND OPENNING ANGLE FOR VOLUME LIMITED BY
C     ANNULUS (ANGA) AND ROD (ANGR)
C     ANGA=ACOS(XINT/RAN)
C     ANGR=ACOS((XINT-RPIN)/RODR)
C  3) EVALUATE VOLUME
C     VRDOUT=ANGR*RODR**2-YINT*(XINT-RPIN)
C     VANIN=ANGA*RAN**2-YINT*XINT
C     VRGOUT=VRDOUT-VANIN
C           =ANGR*RODR**2-ANGA*RAN**2+YINT*RPIN
C     VRGIN=PI*RODR*RODR-VRGOUT
C----
                JPRT=JRT/1000000
                JRT=MOD(JRT,1000000)
                ILSTR=NRODS(2,JRT)
                XNROD=FLOAT(NRODS(1,JRT))
                IF(JPRT.EQ.1) THEN
                  VANSPI=RAN(IAN)*RAN(IAN)
                  VRPSPI=RODS(1,JRT)*RODS(1,JRT)
                  VRDSPI=RODR(ILSTR,JRT)*RODR(ILSTR,JRT)
                  XINT=(VANSPI+VRPSPI-VRDSPI)/(2*RODS(1,JRT))
                  YINT=SQRT(VANSPI-XINT*XINT)
                  ANGR=ACOS((XINT-RODS(1,JRT))/RODR(ILSTR,JRT))
                  ANGA=ACOS(XINT/RAN(IAN))
                  VRGIO(1,JRT)=(ANGR*VRDSPI-ANGA*VANSPI)
     >                       +YINT*RODS(1,JRT)
                  VRGIO(2,JRT)=PI*VRDSPI-VRGIO(1,JRT)
C----
C  FIRST ANNULUS CROSSING ROD
C  COMPUTE ROD VOLUME AND ROD REGION NUMBER
C----
                  VOLIS=0.0
                  DO 212 ISV=1,ILSTR
                    IPOS=IPOS+1
                    VOLFS=PI*RODR(ISV,JRT)*RODR(ISV,JRT)*XNROD
                    VOLSUR(IPOS)=(VOLFS-VOLIS)
                    MATALB(IPOS)=MATROD(ISV,JRT)
                    VOLIS=VOLFS
 212              CONTINUE
                  NRODR(JRT)=IPOS
                  VOLROD=VOLROD+XNROD*VRGIO(2,JRT)
                ELSE IF(JPRT.EQ.2) THEN
C----
C  ROD OVERLAPP THIS ANNULUS AND PRECEEDING ANNULUS
C----
                  VANSPI=RAN(IAN)*RAN(IAN)
                  VRPSPI=RODS(1,JRT)*RODS(1,JRT)
                  VRDSPI=RODR(ILSTR,JRT)*RODR(ILSTR,JRT)
                  XINT=(VANSPI+VRPSPI-VRDSPI)/(2*RODS(1,JRT))
                  YINT=SQRT(VANSPI-XINT*XINT)
                  ANGR=ACOS((XINT-RODS(1,JRT))/RODR(ILSTR,JRT))
                  ANGA=ACOS(XINT/RAN(IAN))
                  VRGOU1=ANGR*VRDSPI-ANGA*VANSPI
     >                       +YINT*RODS(1,JRT)
                  VRGIN1=PI*VRDSPI-VRGOU1
                  VOLROD=VOLROD+XNROD*(VRGIN1-VRGIO(2,JRT))
                  VRGIO(1,JRT)=VRGOU1
                  VRGIO(2,JRT)=VRGIN1
                ELSE
C----
C  LAST ANNULUS CROSSING ROD
C----
                  VOLROD=VOLROD+XNROD*VRGIO(1,JRT)
                ENDIF
              ENDIF
 210        CONTINUE
          ENDIF
        ENDIF
        IPOS=IPOS+1
        VOLSUR(IPOS)=VOLF-VOLI-VOLROD
        MATALB(IPOS)=MATANN(IAN)
        NRINFO(1,IAN)=IPOS
        VOLI=VOLF
 200  CONTINUE
C----
C  FINAL REGION ANALYSIS FOR RECTANGLE AND HEXAGONE
C----
      IF(NSOUT.EQ.6.OR.IROT.LT.-600) THEN
        IPOS=IPOS+1
        MATALB(IPOS)=MATANN(NBAN)
        NRINFO(1,NBAN)=IPOS
        VOLF=THSQ3*RAN(NBAN)*RAN(NBAN)
        VOLSUR(IPOS)=VOLF-VOLI
      ELSE IF(NSOUT.EQ.4.OR.IROT.LT.-400) THEN
        IPOS=IPOS+1
        MATALB(IPOS)=MATANN(NBAN)
        NRINFO(1,NBAN)=IPOS
        VOLF=RAN(NBAN)*COTE
        VOLSUR(IPOS)=VOLF-VOLI
      ENDIF
C----
C  PRINT GEOMETRY INFORMATION IF REQUIRED
C----
      IF(IPRT.GT.0) THEN
        CALL LCMINF(IPGEOM,GEONAM,TEXT12,EMPTY,ILONG,LCM)
        IF(NSOUT.EQ.6.OR.IROT.LT.-600) THEN
          WRITE(IOUT,'(/31H 2-D HEXAGONAL CLUSTER GEOMETRY,
     >    21H BASED ON GEOMETRY : ,A12,1H./)') GEONAM
        ELSE IF(NSOUT.EQ.4.OR.IROT.LT.-400) THEN
          WRITE(IOUT,'(/28H 2-D SQUARE CLUSTER GEOMETRY,
     >    21H BASED ON GEOMETRY : ,A12,1H./)') GEONAM
        ELSE
          WRITE(IOUT,'(/33H 2-D CYLINDRICAL CLUSTER GEOMETRY,
     >    21H BASED ON GEOMETRY : ,A12,1H./)') GEONAM
        ENDIF
        IF (.NOT.ILK) WRITE(IOUT,'(17H INFINITE DOMAIN.)')
      ENDIF
C----
C  PRINT REGION VOLUME AND MATERIAL INFORMATION WHEN REQUIRED
C----
      IF(IPRT.GT.2) THEN
        WRITE(IOUT,6000)
        IREG=0
        DO 610 IAN=1,NTAN
          IREG=IREG+1
          IF(NRINFO(2,IAN).EQ.0) THEN
            WRITE(IOUT,6001) IAN,IREG,MATALB(IREG),VOLSUR(IREG)
          ELSE
            IF(NRINFO(2,IAN).EQ.NXRI(1,IAN)) THEN
              IRT=ABS(NRINFO(2,IAN))
              IF(IRT.LT.2000000) THEN
                LRT=MOD(IRT,1000000)
                DO 612 ISV=1,NRODS(2,LRT)
                  WRITE(IOUT,6002) ISV,IREG,
     >                   MATALB(IREG),VOLSUR(IREG)
                  IREG=IREG+1
 612            CONTINUE
              ENDIF
            ELSE
              DO 613 JRT=1,NRT
                KRT=ABS(NXRI(JRT,IAN))
                IF((KRT.LT.2000000).AND.(KRT.GE.1)) THEN
                  LRT=MOD(KRT,1000000)
                  DO 614 ISV=1,NRODS(2,LRT)
                    WRITE(IOUT,6002) ISV,IREG,
     >                MATALB(IREG),VOLSUR(IREG)
                    IREG=IREG+1
 614              CONTINUE
                ENDIF
 613          CONTINUE
            ENDIF
            WRITE(IOUT,6001) IAN,IREG,MATALB(IREG),VOLSUR(IREG)
          ENDIF
 610    CONTINUE
C----
C  LAST REGION FOR SQUARE AND HEXAGONES
C----
        IF(NSOUT.EQ.6.OR.IROT.LT.-600) THEN
          IREG=IREG+1
          WRITE(IOUT,6001) IAN,IREG,MATALB(IREG),VOLSUR(IREG)
        ELSE IF(NSOUT.EQ.4.OR.IROT.LT.-400) THEN
          IREG=IREG+1
          WRITE(IOUT,6001) IAN,IREG,MATALB(IREG),VOLSUR(IREG)
        ENDIF
      ENDIF
C----
C  SCRATCH STORAGE DEALLOCATION
C----
      DEALLOCATE(VRGIO,RAD)
      DEALLOCATE(ISPLIT,MATROD,MATANN)
      RETURN
C----
C  GEOMETRY DESCRIPTION FORMATS
C----
 6000 FORMAT(//1X,'CLUSTER GEOMETRICAL DESCRIPTION.'/
     >1X,'ANN',2X,'ROD',2X,'REG',9X,'MATERIAL',7X,'VOLUME')
 6001 FORMAT(1X,I3,6X,I4,3X,I10,1P,5X,E15.7)
 6002 FORMAT(5X,I4,1X,I4,3X,I10,1P,5X,E15.7)
 6010 FORMAT(1X,'ANNULAR REGIONS DESCRIPTION'/
     >4X,'ANNULUS',5X,'ROD ARRAY',8X,'OUTER RADIUS',6X,'MIXTURE')
 6011 FORMAT(1X,'ROD CLUSTER DESCRIPTION'/
     >2X,'ROD ARRAY',5X,'NRODS',5X,'NSUBR',7X,'AND',7X,'ANF',8X,
     >'PITCH RADIUS',5X,'FIRST ROD ANGLE'/
     >(1X,5I10,5X,E15.7,5X,E15.7))
 6012 FORMAT(1X,'SUBROD DESCRIPTION'/
     >8X,'IRT',7X,'ISR',8X,'OUTER RADIUS',6X,'MIXTURE',1P/
     >(1X,2I10,5X,E15.7,1X,I10))
 6013 FORMAT(1P,(1X,I10,4X,I10,5X,E15.7,1X,I10))
 6021 FORMAT(1X,'OUTER SURFACE DESCRIPTION'/1P,6(5X,E15.7))
 6022 FORMAT(1X,'OUTER SURFACE ICODES     '/1P,6(5X,I10,5X))
 6023 FORMAT(1X,'GEOMETRICAL ALBEDOS      '/1P,6(2X,I3,E15.7))
 6040 FORMAT(1X,'RECTANGULAR REGION DESCRIPTION'/
     >2X,'RECTANGLE',5X,'ROD ARRAY',
     >8X,'X SIDE WIDTH',8X,'Y SIDE WIDTH',8X,'MIXTURE',1P/
     >(1X,I10,4X,I10,5X,E15.7,5X,E15.7,5X,I10))
 6030 FORMAT(1X,'HEXAGONAL REGIONS DESCRIPTION'/
     >3X,'HEXAHONE',5X,'ROD ARRAY',
     >10X,'SIDE WIDTH',8X,'MIXTURE',1P/
     >(1X,I10,4X,I10,5X,E15.7,5X,I10))
C----
C  ERROR MESSAGE FORMAT
C----
 9001 FORMAT(A6,': ROD TYPE ',I10,5X,'NOT INSIDE CLUSTER')
      END
