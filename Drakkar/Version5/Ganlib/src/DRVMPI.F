#if defined(MPI)
*DECK DRVMPI
      SUBROUTINE DRVMPI(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
* MPI INITIALIZATION.
*
* INPUT/OUTPUT PARAMETERS:
*  NENTRY : NUMBER OF LCM OBJECTS AND FILES USED BY THE MODULE.
*  HENTRY : CHARACTER*12 NAME OF EACH LCM OBJECT OR FILE.
*  IENTRY : =1 LCM OBJECT; =2 XSM FILE;
*           =3 SEQUENTIAL BINARY FILE; =4 SEQUENTIAL ASCII FILE;
*           =5 DIRECT ACCESS FILE.
*  JENTRY : =0 THE LCM OBJECT OR FILE IS CREATED.
*           =1 THE LCM OBJECT OR FILE IS OPEN FOR MODIFICATIONS;
*           =2 THE LCM OBJECT OR FILE IS OPEN IN READ-ONLY MODE.
*  KENTRY : =FILE UNIT NUMBER; =LCM OBJECT ADDRESS OTHERWISE.
*           DIMENSION HENTRY(NENTRY),IENTRY(NENTRY),JENTRY(NENTRY),
*           KENTRY(NENTRY)
*
*--------------------------------------- AUTHOR: R.CHAMBON ; 04/2003 ---
*
      USE GANLIB
      include 'mpif.h'
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      CHARACTER HENTRY(NENTRY)*12
      TYPE(C_PTR) KENTRY(NENTRY)
*----
*  LOCAL VARIABLES
*----
      CHARACTER TEXT12*12
      LOGICAL   LLCMCR
      INTEGER   BGLOOP,EDLOOP,NTLOOP,ITYP,INIPOS
      INTEGER   IPRINT
      REAL      FLOTT,FLOTT2
      INTEGER   NITMA,NITMA2
      DOUBLE PRECISION DFLOTT,DFLOTT2,DTIME
      INTEGER*4 RANK32,SIZE32,IPROC,IERR
      INTEGER   RANK,SIZE
*----
*  ALLOCATABLE STATEMENTS
*----
      INTEGER, ALLOCATABLE, DIMENSION(:) :: IPOSBG,INBPOS

#if defined(__x86_64__)
#  define M64 2
#else
#  define M64 1
#endif

*----
*  PARAMETER VALIDATION.
*----
      IF(NENTRY.GE.2) THEN
         CALL XABORT('DRVMPI: ONE ENTRY MAX EXPECTED')
      ENDIF
      IF(NENTRY.EQ.1) THEN
         IF(JENTRY(1).NE.0) THEN 
            CALL XABORT('DRVMPI: IF ONE ENTRY, HAS TO BE'
     1               //' IN CREATE MODE'//HENTRY(1))
         ELSEIF((IENTRY(1).LE.0).OR.(IENTRY(1).GE.3)) THEN 
            CALL XABORT('DRVMPI: ONE ENTRY, HAS TO BE'
     1               //' LINKED_LIST OR XSM_FILE'//HENTRY(1))
         ELSE
            LLCMCR=.TRUE.
            WRITE(6,*) 'LLCMCR : ',LLCMCR
         ENDIF
         CALL LCMVAL(KENTRY(1),' ')
      ENDIF
*
      IPRINT= 0
        
      CALL MPI_COMM_RANK(MPI_COMM_WORLD,RANK32,IERR)
      RANK=RANK32
      CALL MPI_COMM_SIZE(MPI_COMM_WORLD,SIZE32,IERR)
      SIZE=SIZE32

      ALLOCATE(IPOSBG(SIZE),INBPOS(SIZE))
*----
*  READ INPUT
*----
   20 CALL REDGET(ITYP,NITMA,FLOTT,TEXT12,DFLOTT)
      IF( ITYP.NE.3 ) CALL XABORT('DRVMPI: CHARACTER DATA EXPECTED.')
* EDITION LEVEL      
        IF( TEXT12.EQ.'EDIT' )THEN
         CALL REDGET(ITYP,IPRINT,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.1 ) CALL XABORT('DRVMPI: NO INTEGER AFTER *EDIT*.')
* TOTAL NUMBER OF CPU
      ELSEIF( TEXT12.EQ.'WORLD-SIZE' )THEN
         CALL REDGET(ITYP,NTLOOP,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.-1 ) CALL XABORT('DRVMPI: NO INTEGER VARIABLE '//
     1   'AFTER *SETLOOP*.')
         ITYP = 1
         CALL REDPUT(ITYP,SIZE,FLOTT,TEXT12,DFLOTT)
         IF(IPRINT.GE.1)  WRITE(6,1000) SIZE
* CPU NUMBER
      ELSEIF( TEXT12.EQ.'MY-ID' )THEN
         CALL REDGET(ITYP,NTLOOP,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.-1 ) CALL XABORT('DRVMPI: NO INTEGER VARIABLE '//
     1   'AFTER *SETLOOP*.')
         ITYP = 1
         CALL REDPUT(ITYP,RANK,FLOTT,TEXT12,DFLOTT)
         IF(IPRINT.GE.1)  WRITE(6,1010) RANK
* CPU REPARTITION FOR A LOOP
      ELSEIF( TEXT12.EQ.'SETLOOP' )THEN
         CALL REDGET(ITYP,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(ITYP.NE.3.AND.TEXT12.NE.'B0'.AND.TEXT12.NE.'B1' ) THEN 
            CALL XABORT('DRVMPI: BO OR B1 KEYWORD EXPECTED '//
     1      'AFTER *SETLOOP*.')
         ENDIF
         INIPOS=-99999
         IF(TEXT12.EQ.'B0') INIPOS=0
         IF(TEXT12.EQ.'B1') INIPOS=1
         CALL REDGET(ITYP,NTLOOP,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.1 ) CALL XABORT('DRVMPI: NO INTEGER '//
     1   'AFTER *SETLOOP*.')
         CALL REDGET(ITYP,BGLOOP,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.-1 ) CALL XABORT('DRVMPI: NO INTEGER VARIABLE '//
     1   'AFTER *SETLOOP*.')
         CALL REDGET(ITYP,EDLOOP,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.-1 ) CALL XABORT('DRVMPI: NO INTEGER VARIABLE '//
     1   'AFTER *SETLOOP*.')
         IF(SIZE.GT.NTLOOP) THEN 
            DO 3 IPROC=0,SIZE-1
            IPOSBG(IPROC+1)=MIN0(IPROC,NTLOOP-1)+INIPOS
            INBPOS(IPROC+1)=1
    3       CONTINUE
         ELSE
            DO 4 IPROC=0,SIZE-1
            IPOSBG(IPROC+1) = INIPOS +
     1          IPROC * (NTLOOP / SIZE) + MIN0(IPROC, MOD(NTLOOP, SIZE))
            INBPOS(IPROC+1) = 
     1          (NTLOOP / SIZE) + MIN0(1, MOD(NTLOOP, SIZE)/(IPROC + 1))
    4       CONTINUE
         ENDIF
         BGLOOP=IPOSBG(RANK+1)
         EDLOOP=IPOSBG(RANK+1)+INBPOS(RANK+1)-1
         ITYP = 1
         CALL REDPUT(ITYP,EDLOOP,FLOTT,TEXT12,DFLOTT)
         CALL REDPUT(ITYP,BGLOOP,FLOTT,TEXT12,DFLOTT)
          IF(IPRINT.GE.1) THEN
            WRITE(6,1020) BGLOOP,EDLOOP
            IF(IPRINT.GE.2) THEN
               WRITE (6,1030)
               DO 5 IPROC=0,SIZE-1
                  WRITE (6,1031) IPROC,IPOSBG(IPROC+1),
     1                  IPOSBG(IPROC+1)+INBPOS(IPROC+1)-1
    5          CONTINUE
            ENDIF
         ENDIF
* REDUCTION OPERATION
      ELSEIF( TEXT12.EQ.'ALLREDUCE' )THEN
         CALL REDGET(ITYP,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(ITYP.NE.3.AND.TEXT12.NE.'SUM'.AND.TEXT12.NE.'PROD'
     1      .AND.TEXT12.NE.'MAX'.AND.TEXT12.NE.'MIN') THEN 
            CALL XABORT('DRVMPI: REDUCE OPERATOR KEYWORD EXPECTED '//
     1      'AFTER *ALLREDUCE*.')
         ENDIF
         IF(TEXT12.EQ.'SUM') IOPERT=MPI_SUM
         IF(TEXT12.EQ.'PROD') IOPERT=MPI_PROD
         IF(TEXT12.EQ.'MAX') IOPERT=MPI_MAX
         IF(TEXT12.EQ.'MIN') IOPERT=MPI_MIN
         CALL REDGET(ITYP,NITMA,FLOTT,TEXT12,DFLOTT)
         IF( ITYP.NE.1.AND.ITYP.NE.2.AND.ITYP.NE.4 )
     1    CALL XABORT('DRVMPI: SCALAR VARIABLE TO REDUCE '// 
     2    'EXPECTED FOR *ALLREDUCE*.')
         ITYPE=ITYP
         CALL REDGET(ITYP,NITMA2,FLOTT2,TEXT12,DFLOTT2)
         IF(-ITYP.NE.ITYPE ) CALL XABORT('DRVMPI: DESTINATION '//
     1   'AND SOURCE NOT SAME TYPE FOR *ALLREDUCE*.')
         IF( ITYPE.EQ.1 ) THEN
              CALL MPI_ALLREDUCE(NITMA,NITMA2,1*M64,MPI_INTEGER,
     1              IOPERT,MPI_COMM_WORLD,IERR)
              CALL REDPUT(ITYPE,NITMA2,FLOTT2,TEXT12,DFLOTT2)
              IF(IPRINT.GE.1) 
     1         WRITE(6,*) 'RESULT OF THE ALLREDUCE',NITMA2
         ELSEIF( ITYPE.EQ.2 ) THEN
              CALL MPI_ALLREDUCE(FLOTT,FLOTT2,1*M64,MPI_REAL,
     1              IOPERT,MPI_COMM_WORLD,IERR)
              CALL REDPUT(ITYPE,NITMA2,FLOTT2,TEXT12,DFLOTT2)
              IF(IPRINT.GE.1)
     1         WRITE(6,*) 'RESULT OF THE ALLREDUCE',FLOTT2
         ELSEIF( ITYPE.EQ.4 ) THEN
           CALL MPI_ALLREDUCE(DFLOTT,DFLOTT2,1*M64,MPI_DOUBLE_PRECISION,
     1              IOPERT,MPI_COMM_WORLD,IERR)
              CALL REDPUT(ITYPE,NITMA2,FLOTT2,TEXT12,DFLOTT2)
              IF(IPRINT.GE.1) 
     1         WRITE(6,*) 'RESULT OF THE ALLREDUCE',DFLOTT2
         ELSE
              CALL  XABORT('DRVMPI: NO LOGICAL OR STRING VARIABLE '//
     1        'ACCEPTED FOR *ALLREDUCE*.')
         ENDIF
* TIME
      ELSEIF( TEXT12.EQ.'TIME' )THEN
         CALL REDGET(ITYP,NTLOOP,FLOTT,TEXT12,DTIME)
         IF( ITYP.NE.-4 ) CALL XABORT('DRVMPI: NO DOUBLE VARIABLE ' //
     1   'AFTER *TIME*.')
         ITYP = 4
         DTIME = MPI_WTIME()
         CALL REDPUT(ITYP,SIZE,FLOTT,TEXT12,DTIME)
         IF(IPRINT.GE.1)  WRITE(6,1040) DTIME 
* BARRIER
      ELSEIF( TEXT12.EQ.'BARRIER' )THEN
         CALL MPI_BARRIER(MPI_COMM_WORLD,IERR)
         IF(IPRINT.GE.1)  WRITE(6,1050)  
* END OF THIS SUBROUTINE
      ELSEIF( TEXT12.EQ.';' )THEN
         GO TO 40
      ELSE
         CALL XABORT('DRVMPI: '//TEXT12//' IS AN INVALID KEYWORD.')
      ENDIF
      GO TO 20
*----
*  END OF INPUT OPTIONS
*----
   40 DEALLOCATE(INBPOS,IPOSBG)
      RETURN
*----
*  FORMATS
*----
 1000 FORMAT(35H TOTAL NUMBER OF CPU (WORLD-SIZE): ,I4)
 1010 FORMAT(35H NUMBER OF THIS CPU  (MY-ID)     : ,I4)
 1020 FORMAT(35H FOR THIS CPU: BEGIN LOOP (BGLOOP) ,I8,
     1       20H  END LOOP (EDLOOP) ,I8)
 1030 FORMAT(37H FOR CPU #: BEGIN LOOP   -   END LOOP) 
 1031 FORMAT(4H #  ,I4,2X,1H:,1X,I8,5X,1H-,1X,I8) 
 1040 FORMAT(35H TIME                     (DTIME): ,D20.14)
 1050 FORMAT(35H ALL CPU HAVE BEEN SYNCHRONISED.   )
      END
#endif /* defined(MPI) */
