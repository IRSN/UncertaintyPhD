*DECK XELCOP
      SUBROUTINE XELCOP( IFILE1, IFILE2)
************************************************************************
*                                                                      *
*           NAME: XELCOP                                               *
*      COMPONENT: EXCELL                                               *
*          LEVEL: 2 (CALLED BY 'EXCELT')                               *
*        VERSION: 1.0                                                  *
*       CREATION: 91/07                                                *
*       MODIFIED: 00/03 (R.R.) DECLARE ALL VARIABLE TYPES              *
*         AUTHOR: ROBERT ROY                                           *
*                                                                      *
*     SUBROUTINE: THIS ROUTINE WILL COPY A DRAGON TRACKING FILE;       *
*                 THE FILE *IFILE1* IS COPIED OVER *IFILE2*.           *
*                                                                      *
*           NOTE: THE FILES "IFILE1" AND "IFILE2" ARE SUPPOSED TO BE:  *
*                 1) CONNECTED AND OPENED;                             *
*                 2) PLACED FOR ACCESSING THE FIRST RECORD (REWIND).   *
*                                                                      *
*--------+-------------- V A R I A B L E S -------------+--+-----------*
*  NAME  /                  DESCRIPTION                 /IO/MOD(DIMENS)*
*--------+----------------------------------------------+--+-----------*
* IFILE1 / FIRST  TRACKING FILE # (AT INPUT).           /I./INT        *
* IFILE2 / SECOND TRACKING FILE # (AT OUTPUT).          /I./INT        *
************************************************************************
      IMPLICIT          NONE
C
      DOUBLE PRECISION  WEIGHT
      INTEGER           IFILE1,IFILE2,NCOMNT,NTRK,IFMT,IREC,IC,IR,NDIM,
     >                  ISPEC,NV,NS,NALBG,NCOR,NANGL,MXSUB,MXSEG,NSUB,
     >                  LINE,NUNKNO
      CHARACTER         CTRK*4, COMENT*80
      INTEGER           IOUT
      PARAMETER       ( IOUT=6 )
C----
C  ALLOCATABLE ARRAYS
C----
      INTEGER, ALLOCATABLE, DIMENSION(:) :: MATALB,ICODE,NRSEG,KANGL
      REAL, ALLOCATABLE, DIMENSION(:) :: VOLSUR,ALBEDO
      DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:) :: ANGLES,DENSTY
      DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:) :: SEGLEN
C
C.1)  READ AND COPY FIRST RECORDS (HEADER, COMMENTS) ------------------
C
      IREC= 1
      READ (IFILE1,ERR=991) CTRK,NCOMNT,NTRK,IFMT
      WRITE(IFILE2,ERR=992) CTRK,NCOMNT,NTRK,IFMT
      DO 10 IC= 1, NCOMNT
         IREC= IREC+1
         READ (IFILE1,ERR=991) COMENT
         WRITE(IFILE2,ERR=992) COMENT
   10 CONTINUE
C
C.2)  READ AND COPY MAIN RECORD AND GET USEFUL DIMENSIONS -------------
C
      IREC= IREC+1
      READ (IFILE1,ERR=991) NDIM,ISPEC,NV,NS,NALBG,NCOR,NANGL,MXSUB,
     > MXSEG
      WRITE(IFILE2,ERR=992) NDIM,ISPEC,NV,NS,NALBG,NCOR,NANGL,MXSUB,
     > MXSEG
      NUNKNO= NV+NS+1
C
C.2.1) ALLOCATE SPACE TO COPY SUBSEQUENT RECORDS
      ALLOCATE(MATALB(NUNKNO),ICODE(NALBG),NRSEG(MXSEG),KANGL(MXSUB))
      ALLOCATE(VOLSUR(NUNKNO),ALBEDO(NALBG),ANGLES(NDIM*NANGL),
     > DENSTY(NANGL),SEGLEN(MXSEG))
C
C.2.2) COPY ALL RECORDS BEFORE TRACKS
      IREC= IREC+1
      READ (IFILE1,ERR=991) (VOLSUR(IR),IR=1,NUNKNO)
      WRITE(IFILE2,ERR=992) (VOLSUR(IR),IR=1,NUNKNO)
      IREC= IREC+1
      READ (IFILE1,ERR=991) (MATALB(IR),IR=1,NUNKNO)
      WRITE(IFILE2,ERR=992) (MATALB(IR),IR=1,NUNKNO)
      IREC= IREC+1
      READ (IFILE1,ERR=991) (ICODE(IR),IR=1,NALBG)
      WRITE(IFILE2,ERR=992) (ICODE(IR),IR=1,NALBG)
      IREC= IREC+1
      READ (IFILE1,ERR=991) (ALBEDO(IR),IR=1,NALBG)
      WRITE(IFILE2,ERR=992) (ALBEDO(IR),IR=1,NALBG)
      IREC= IREC+1
      READ (IFILE1,ERR=991) (ANGLES(IR),IR=1,NDIM*NANGL)
      WRITE(IFILE2,ERR=992) (ANGLES(IR),IR=1,NDIM*NANGL)
      IREC= IREC+1
      READ (IFILE1,ERR=991) (DENSTY(IR),IR=1,NANGL)
      WRITE(IFILE2,ERR=992) (DENSTY(IR),IR=1,NANGL)
C
C.3)   NOW, COPY ALL TRACKS -------------------------------------------
C
   20 CONTINUE
         IREC= IREC + 1
         READ (IFILE1,END=40,ERR=991) NSUB,LINE,WEIGHT,
     >                      (KANGL(IR),IR=1,NSUB),
     >                      (NRSEG(IR),IR=1,LINE),(SEGLEN(IR),IR=1,LINE)
         IF(NSUB.GT.MXSUB) CALL XABORT('XELCOP: MXSUB OVERFLOW.')
         WRITE(IFILE2,       ERR=992) NSUB,LINE,WEIGHT,
     >                      (KANGL(IR),IR=1,NSUB),
     >                      (NRSEG(IR),IR=1,LINE),(SEGLEN(IR),IR=1,LINE)
      GO TO 20
C
   40 CONTINUE
C
C.4)   RELEASE TEMPORARY SPACE AND REWIND BOTH FILES ------------------
C
      DEALLOCATE(KANGL,SEGLEN,DENSTY,ANGLES,ALBEDO,VOLSUR)
      DEALLOCATE(NRSEG,ICODE,MATALB)
      REWIND IFILE1
      REWIND IFILE2
      RETURN
C
  991 WRITE(IOUT,'(30H ERROR= RECORD DESTROYED...    )')
      WRITE(IOUT,'(31H ERROR= UNABLE TO READ  RECORD ,I10)') IREC
      WRITE(IOUT,'(31H ERROR=              ON FILE FT,I2.2)') IFILE1
      CALL XABORT( 'XELCOP: --- READ  TRACKING FILE FAILED' )
  992 WRITE(IOUT,'(30H ERROR= NOT ENOUGH SPACE...    )')
      WRITE(IOUT,'(31H ERROR= UNABLE TO WRITE RECORD ,I8.8)') IREC
      WRITE(IOUT,'(31H ERROR=              ON FILE FT,I2.2)') IFILE1
      CALL XABORT( 'XELCOP: --- WRITE TRACKING FILE FAILED' )
C
      END
