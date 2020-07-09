*DECK MOCCAL
      SUBROUTINE MOCCAL(N,NOMCEL,NREG,MCUW,MCUI,LMCU,LMXMCU)
*
*-----------------------------------------------------------------------
*
*Purpose:
* calculation of connection matrices.
*
*Copyright:
* Copyright (C) 2002 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): I. Suslov
*
*Parameters: input
* N       number of segments on this track.
* NOMCEL  integer tracking elements.
* NREG    number of volumes.
* LMCU    dimension (used) of MCUW.
* LMXMCU  real dimension of MCUW MCUI.
*
*Parameters: input/output
* MCUW
* MCUI
*
*-----------------------------------------------------------------------
*
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER N,NOMCEL(N),NREG,MCUW(LMXMCU),MCUI(LMXMCU),LMCU,LMXMCU
*
      CHARACTER HSMG*131
*
      DO 10 I=1,N
      ICEL=NOMCEL(I)
      IF (ICEL.LE.NREG) THEN
         IF (I.EQ.N) THEN
            ICEL1=NOMCEL(1)
         ELSE
            ICEL1=NOMCEL(I+1)
         ENDIF
         IF((ICEL.EQ.ICEL1).OR.(ICEL1.GT.NREG)) GOTO 6
*        IS THERE AREADY AN ELEMENT IN MATRIX FOR CELL ICEL ?
         IF (MCUW(ICEL).NE.0) GOTO 5
*        NO :
         MCUW(ICEL)=ICEL1
         GOTO 6
*        YES :
 5       II=ICEL
         IF(MCUW(II).EQ.ICEL1) GOTO 6
         ICEL=MCUI(II)
         IF(ICEL.NE.0) GOTO 5
*        ADD NEW ELEMENT 
         LMCU=LMCU+1
         IF(LMCU.GT.LMXMCU) THEN
            WRITE(HSMG,'(42HMOCCAL: MEMORY OVERFLOW. INCREASE MCU. LMX,
     1      4HMCU=,I10,1H.)') LMXMCU
            CALL XABORT(HSMG)
         ENDIF
         MCUW(LMCU)=ICEL1
         MCUI(II)=LMCU
 6       CONTINUE
      ENDIF
 10   CONTINUE
*     
      RETURN
      END
