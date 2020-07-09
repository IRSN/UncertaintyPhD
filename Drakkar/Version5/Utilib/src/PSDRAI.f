*DECK PSDRAI
      SUBROUTINE PSDRAI(ISPSP,NSEG,IORDER,CENTER,RADANG)
C
C-------------------------    PSDRAI    -------------------------------
C
C 1- SUBROUTINE STATISTICS:
C     NAME     : PSDRAI
C     USE      : DRAW RECTANGULAR/ANNULAR INTERSECTION REGION
C
C 2- PARAMETERS:
C  INPUT
C     ISPSP  : POSTSCRIPT STRUCTURE                    I
C     NSEG   : NUMBER OF REGION INTERSECTION           I
C              NUMBER OF SEGMENTS IS NSEG-1
C     IORDER : TYPE OF REGION                          R(NSEG)
C              = -2 : ARC SEGMENT BEGINS
C              = -1 : ARC SEGMENT ENDS
C              =  0 : CLOSE PATH
C              >  0 : CORNER
C     CENTER : X AND Y POSITION OF ANNULUS CENTER      R(2)
C     RADANG : SEGMENTS INTERSECTION POINTS            R(2,NSEG)
C              WITH RESPECT TO ANNULAR REGION CENTER
C              RADANG(1) = RADIAL POSITION
C              RADANG(2) = ANGULAR POSITION
C
C----------------------------------------------------------------------
C
      IMPLICIT         NONE
      INTEGER          ISPSP,NSEG
      INTEGER          IORDER(NSEG)
      REAL             CENTER(2),RADANG(2,NSEG)
C----
C  LOCAL PARAMETERS
C----
      REAL             CONVER,PI
      CHARACTER        NAMSBR*6
      PARAMETER       (CONVER=72.0,PI=3.1415926535897932,
     >                 NAMSBR='PSDRAI')
      CHARACTER        CMDSTR*132
      INTEGER          IPT,IDEP,IFIN
      REAL             XYDEP(2),ANGL(2),XYFIN(2)
C----
C  POSITION REFERENCE POINT AT CENTER OF ANNULAR REGION
C----
      XYDEP(1)=CENTER(1)
      XYDEP(2)=CENTER(2)
*      CALL PSMOVE(ISPSP,XYDEP,-3)
C----
C  MOVE TO FIRST POINT
C----
      CMDSTR='Np'
      CALL PSCPUT(ISPSP,CMDSTR)
      IDEP=IORDER(1)
      XYDEP(1)=RADANG(1,1)*COS(RADANG(2,1))
      XYDEP(2)=RADANG(1,1)*SIN(RADANG(2,1))
      ANGL(1)=180.0*RADANG(2,1)/PI
      IF(IDEP .EQ. -1 .OR. IDEP .GT. 0) THEN
        CALL PSMOVE(ISPSP,XYDEP,3)
      ENDIF
C----
C  SCAN SEGMENTS
C----
      DO 100 IPT=2,NSEG
        CMDSTR=' '
        IFIN=IORDER(IPT)
        XYFIN(1)=RADANG(1,IPT)*COS(RADANG(2,IPT))
        XYFIN(2)=RADANG(1,IPT)*SIN(RADANG(2,IPT))
        IF     (IDEP .EQ. -2) THEN
C----
C  ARC SEGMENT
C  FIND ANGLES ASSOCIATED WITH ARC
C----
          ANGL(2)=180.0*RADANG(2,IPT)/PI
          IF(ANGL(2) .LT. ANGL(1)) THEN
            ANGL(2)=ANGL(2)+360.0
          ENDIF
          WRITE(CMDSTR,'(5(F8.2,1X),A3)')
     >       0.0,0.0,RADANG(1,IPT)*CONVER,ANGL(1),ANGL(2),'arc'
          CALL PSCPUT(ISPSP,CMDSTR)
        ELSE
C----
C  LINE
C----
          WRITE(CMDSTR,'(2(F8.2,1X),A1)')
     >      XYFIN(1)*CONVER,XYFIN(2)*CONVER,'L'
          CALL PSCPUT(ISPSP,CMDSTR)
        ENDIF
        IDEP=IFIN
        XYDEP(1)=XYFIN(1)
        XYDEP(2)=XYFIN(2)
        ANGL(1)=180.0*RADANG(2,IPT)/PI
 100  CONTINUE
C----
C  RESET REFERENCE POINT AT ORIGINAL POSITION
C----
      CMDSTR='closepath'
      CALL PSCPUT(ISPSP,CMDSTR)
      XYDEP(1)=-CENTER(1)
      XYDEP(2)=-CENTER(2)
*      CALL PSMOVE(ISPSP,XYDEP,-3)
      RETURN
      END
