*DECK PSSREG
      SUBROUTINE PSSREG(ISPSP,NPTS,XYPTS)
C
C---------------------------  PSSREG  ---------------------------------
C
C  1- PROGRAMME STATISTICS:
C      NAME     : PSSREG
C      USE      : DRAW REGION
C                 ADAPTED FROM PSPLOT ROUTINE FILRGNC
C
C  2- ROUTINE PARAMETERS:
C    INPUT/OUTPUT
C      ISPSP    : PSP FILE UNIT                          I
C      NPTS     : NUMBER OF POINTS                       I
C      YXPTS    : POSITION (X,Y) OF LINE INTERSECTION    R(2,NPTS)
C
C---------------------------   PSSREG  --------------------------------
C
      IMPLICIT         NONE
      INTEGER          ISPSP,NPTS
      REAL             XYPTS(2,NPTS)
C----
C  LOCAL VARIABLES
C----
      CHARACTER        NAMSBR*6
      REAL             CONVER
      PARAMETER       (NAMSBR='PSSREG',CONVER=72.0)
      INTEGER          IPT
      CHARACTER        CMDSTR*132
      CMDSTR='Np'
      CALL PSCPUT(ISPSP,CMDSTR)
      CMDSTR=' '
      WRITE(CMDSTR,'(2(F8.2,1X),A1)')
     >  XYPTS(1,1)*CONVER,XYPTS(2,1)*CONVER,'M'
      CALL PSCPUT(ISPSP,CMDSTR)
      DO 100 IPT=2,NPTS
        CMDSTR=' '
        WRITE(CMDSTR,'(2(F8.2,1X),A1)')
     >    XYPTS(1,IPT)*CONVER,XYPTS(2,IPT)*CONVER,'L'
        CALL PSCPUT(ISPSP,CMDSTR)
 100  CONTINUE
      CMDSTR='Cs'
      CALL PSCPUT(ISPSP,CMDSTR)
      RETURN
      END
