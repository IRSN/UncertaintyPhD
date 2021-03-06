*DECK AEXTPA
      SUBROUTINE AEXTPA(NOMFIC,ISFICH)
*
*-----------------------------------------------------------------------
*
* DETERMINATION OF A SAPHYR ARCHIVE FILE CHARACTERISTICS.
* COMPONENT OF A FORTRAN-77 EMULATOR OF THE SAPHYR ARCHIVE SYSTEM.
*
* INPUT PARAMETER:
*  NOMFIC : CHARACTER*(*) NAME OF SAPHYR ARCHIVE FILE.
*
* OUTPUT PARAMETER:
*  ISFICH : FILE CHARACTERISTICS. INTEGER ISFICH(3)
*           ISFICH(1) = ADDRESS OF THE TABLE OF CONTENT.
*           ISFICH(2) = NUMBER OF ARCHIVE OBJECTS ON FILE.
*           ISFICH(3) = DIRECT ACCESS RECORD LENGTH IN WORDS.
*
*----------------------------------- AUTHOR: A. HEBERT ; 05/10/1999 ----
*
      INTEGER    ISFICH(3)
      CHARACTER  NOMFIC*(*),HSMG*131
*
      IULFIC = KDROPN(NOMFIC,2,4,1)
      IF(IULFIC.LE.0) THEN
         WRITE(HSMG,'(33HAEXTPA: KDROPN FAILURE WITH CODE=,I3)') IULFIC
         CALL XABORT(HSMG)
      ENDIF
      ISTATE = 5
      I2 = 3
*
   40 READ(IULFIC,REC=I2,ERR=50,IOSTAT=IOS) MOTLU
      IF(IOS.NE.0) GO TO 50
*
      ISTATE = ISTATE + 1
      IF(ISTATE .EQ. 8) THEN
        ISFICH(3) = MOTLU
        I2 = 4
        GO TO 40
      ELSEIF(ISTATE .EQ. 9) THEN
        ISFICH(2) = MOTLU
      ELSEIF(ISTATE .EQ. 7) THEN
        I2 = MOTLU + 7
        GO TO 40
      ELSEIF(ISTATE .EQ. 6) THEN
        ISFICH(1) = MOTLU
        I2 = MOTLU + 3
        GO TO 40
      ENDIF
*
   50 IER = KDRCLS(IULFIC,1)
      IF(IER.LT.0) THEN
         WRITE(HSMG,'(33HAEXTPA: KDRCLS FAILURE WITH CODE=,I3)') IER
         CALL XABORT(HSMG)
      ENDIF
      RETURN
      END
