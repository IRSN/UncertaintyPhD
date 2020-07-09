*DECK INFTR1
      SUBROUTINE INFTR1(CFILNA,IPRINT,NBISO,HNAMIS,AWRISO)
C
C------------------------------  INFTR1  ------------------------------
C
C   TO RECOVER MASS FOR ISOTOPES OF MATXS TYPE LIBRARIES
C   USE MATXS FORMAT FROM NJOY-II OR NJOY89.
C   REFERENCE: R. E. MACFARLANE, TRANSX-CTR: A CODE FOR INTERFACING
C   MATXS CROSS-SECTION LIBRARIES TO NUCLEAR TRANSPORT CODES FOR
C   FUSION SYSTEMS ANALYSIS, LOS ALAMOS NATIONAL LABORATORY,
C   REPORT LA-9863-MS, NEW MEXICO, FEBRUARY 1984.
C
C   INPUT
C     CFILNA : DRAGON FILE NAME                     C*64
C     IPRINT : PRINT FLAG                           I
C     NBISO  : NUMBER OF ISOTOPES                   I
C     HNAMIS : ISOTOPE NAMES                        C(NBISO)*8
C   OUTPUT
C     AWRISO : ISOTOPE WEIGHTS                      R(NBISO)
C
C------------------------------  INFTR1  ------------------------------
C
      IMPLICIT         NONE
      INTEGER          IPRINT,NBISO
      CHARACTER        CFILNA*64,HNAMIS(NBISO)*8
      REAL             AWRISO(NBISO)
C----
C  LOCAL VARIABLES
C----
      INTEGER          IOUT,MULT,MAXA
      CHARACTER        FORM*4
      PARAMETER       (IOUT=6,MULT=2,MAXA=1000,FORM='(A6)')
C----
C FUNCTIONS
C----
      INTEGER          KDROPN,KDRCLS
      DOUBLE PRECISION XDRCST
      INTEGER          NIN,IREC,NWDS,NPART,NTYPE,L2,L2H,IRZT,IT,
     >                 NDEX,NMAT,NINP,NING,NOUTP,NOUTG,LOCT,LMC,
     >                 IRZM,IM,ISO,LOC,IER,IA(MAXA)
      CHARACTER        HSMG*131,HTYPE*6,HMAT*6
      REAL             RA(MAXA)
      DOUBLE PRECISION DA(MAXA/2)
      REAL             CONVM
      EQUIVALENCE     (RA(1),IA(1),DA(1))
C----
C  OPEN MATXS FILE AND INITIALIZE LIBRARY
C----
      CONVM=REAL(XDRCST('Neutron mass','amu'))
      NIN=KDROPN(CFILNA,2,2,0)
      IF(NIN.LE.0) THEN
        WRITE(HSMG,9000) CFILNA
        CALL XABORT(HSMG)
      ENDIF
      IREC=2
      NWDS=3
C-------FILE CONTROL---------------
      CALL XDREED(NIN,IREC,RA,NWDS)
C----------------------------------
      NPART=IA(1)
      NTYPE=IA(2)
      IREC=4
      NWDS=(NPART+NTYPE)*MULT+6*NTYPE+NPART
      IF(NWDS.GT.MAXA) CALL XABORT
     >  ('INFTR1: LENGTH OF RECORD 4 > MAXA ')
C-------FILE DATA------------------
      CALL XDREED(NIN,IREC,RA,NWDS)
C----------------------------------
      IF((NWDS/2)*2.NE.NWDS) NWDS=NWDS+1
      L2=1+NWDS
      L2H=(L2-1)/MULT+1
      IRZT=5+NPART
C----
C  DATA TYPE LOOP
C----
      DO 100 IT=1,NTYPE
        WRITE(HTYPE,FORM) DA(NPART+IT)
        CALL XDRCAS('LOWTOUP',HTYPE)
        IF(HTYPE.NE.'NSCAT'.AND.HTYPE.NE.'NTHERM') GO TO 105
        NDEX=(NPART+NTYPE)*MULT+IT
        NMAT=IA(NDEX)
        NDEX=NDEX+NTYPE
        NINP=IA(NDEX)
        NDEX=NDEX+NTYPE
        NING=IA(NDEX)
        NDEX=NDEX+NTYPE
        NOUTP=IA(NDEX)
        NDEX=NDEX+NTYPE
        NOUTG=IA(NDEX)
        NDEX=NDEX+NTYPE
        LOCT=IA(NDEX)
C----
C  DATA TYPE CONTROL
C----
        IREC=LOCT+IRZT
        NWDS=(2+MULT)*NMAT+NINP+NOUTP+1
        IF(L2+NWDS-1.GT.MAXA)  CALL XABORT
     >    ('INFTR1: LENGTH OF CURRENT RECORD > MAXA ')
C----------------------------------------
        CALL XDREED(NIN,IREC,RA(L2),NWDS)
C----------------------------------------
        IF((NWDS/2)*2.NE.NWDS) NWDS=NWDS+1
        LMC=L2+NWDS
        IRZM=IREC+1
C----
C  READ THROUGH MATXS FILE AND GET AWR FOR ISOTOPES
C----
        DO 110 IM=1,NMAT
          WRITE(HMAT,FORM) DA(L2H-1+IM)
          DO 120 ISO=1,NBISO
            IF(HMAT.EQ.HNAMIS(ISO)(:6)) THEN
              LOC=L2-1+MULT*NMAT+IM
              IREC=IA(LOC+NMAT)+IRZM
              NWDS=MULT+1+6*IA(LOC)
              IF(LMC+NWDS-1.GT.MAXA) CALL XABORT
     >          ('INFTR1: LENGTH OF CURRENT RECORD > MAXA ')
C-------------------------------------------
              CALL XDREED(NIN,IREC,RA(LMC),NWDS)
C-------------------------------------------
              AWRISO(ISO)=RA(LMC+MULT)*CONVM
              IF(IPRINT.GE.100) THEN
                WRITE(IOUT,6000) HNAMIS(ISO),AWRISO(ISO)
              ENDIF
            ENDIF
 120      CONTINUE
 110    CONTINUE
 105    CONTINUE
 100  CONTINUE
C----
C  CLOSE MATXS FILE.
C----
      IER=KDRCLS(NIN,1)
      IF(IER.LT.0) THEN
        WRITE(HSMG,9001) CFILNA
        CALL XABORT(HSMG)
      ENDIF
      RETURN
C----
C  PRINT FORMATS
C----
 6000 FORMAT(' MATXS ISOTOPE =',A8,
     >       ' HAS ATOMIC WEIGHT RATIO = ',F10.3)
C----
C  ABORT FORMATS
C----
 9000 FORMAT('INFTR1: UNABLE TO OPEN MATXS LIBRARY FILE ',A64)
 9001 FORMAT('INFTR1: UNABLE TO CLOSE MATXS LIBRARY FILE ',A64)
      END
