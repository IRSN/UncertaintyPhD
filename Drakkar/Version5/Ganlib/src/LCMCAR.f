*DECK LCMCAR
      SUBROUTINE LCMCAR(TEXT,LACTIO,NITMA)
*
*-----------------------------------------------------------------------
*
* TRANSFORM A CHARACTER VARIABLE INTO INTEGER VECTOR BACK AND FORTH.
* THIS ROUTINE IS PORTABLE AND BASED ON THE *ASCII* COLLATING SEQUENCE,
* EQUIVALENCE BETWEEN: TEXT='    ' <=> NITMA=0, IS IMPOSED.
*
* INPUT/OUTPUT PARAMETERS:
*  TEXT   : CHARACTER VARIABLE.
*  LACT   : LOGICAL: .TRUE.   CHARACTER TO INTEGER   CONVERSION;
*                    .FALSE.  INTEGER   TO CHARACTER CONVERSION.
*  NITMA  : INTEGER (32 BITS) VECTOR.
*
* LIMITATIONS:
*           IT IS ASSUMED THAT:  0 <= ICHAR() <= 255,
*           OTHERWISE A CHARACTER WOULD NOT STAND IN ONE BYTE.
*
* INTERNAL PARAMETERS:
*  ALPHAB : LIMITED ALPHABET USED FOR VARIABLE NAMES (CHARACTER*96).
*  TASCII : TABLE TO CONVERT ICHAR() VALUES INTO *ASCII* CODES.
*  IASCII : INVERSION OF TASCII().
*  IBASE1 : INTEGRAL BASIS DEFINED AS MAXIMUM VALUE OF ICHAR()+1;
*           TO OPTIMIZE CALCULATIONS, IT IS A POWER OF 2 (128 OR 256).
*
*------------------------------------- AUTHOR: R. ROY ; 17/06/99 -------
*
      IMPLICIT    NONE
      CHARACTER   TEXT*(*)
      LOGICAL     LACTIO
      CHARACTER   ALPHAB*96
      INTEGER     NITMA(*)
      INTEGER     IBASE1,IBASE2,TASCII(0:255),IASCII(0:127)
      INTEGER     I0,I1,I2,I3,J01,J23,K,LMAX,L1,NBDIM,IBDIM
      INTEGER     IWRITE
      PARAMETER ( IWRITE= 6 )
      SAVE IBASE1,IBASE2,TASCII,IASCII
      DATA IBASE1/0/
*
      IF(IBASE1.EQ.0) THEN
*        PREPARE TABLES TASCII() AND IASCII() AND SET INTEGERS IBASE1
*        + IBASE2 FOR CHARACTER/INTEGER CONVERSIONS.
*            0         1         2         3
*            0123456789012345678901234567890123456789
         ALPHAB=' !..$%&.()*+,-./0123456789:;<=>?.ABCDEF'//
     >      'GHIJKLMNOPQRSTUVWXYZ...._.abcdefghijklmn'//
     >      'opqrstuvwxyz.....'
*
         LMAX= 0
         DO 30 K=0,95
            L1= ICHAR(ALPHAB(K+1:K+1))
            LMAX= MAX(LMAX,L1)
            TASCII(L1)= K
            IASCII(K)= L1
   30    CONTINUE
         IF( LMAX.LT.128 )THEN
            IBASE1= 128
         ELSE
            IBASE1= 256
         ENDIF
         IBASE2= IBASE1*IBASE1
      ENDIF
*
      NBDIM= LEN(TEXT)
      IF( MOD(NBDIM,4).NE.0 )THEN
         WRITE(IWRITE,*) 'LCMCAR: LEN(TEXT)=',NBDIM,' NOT / BY 4'
         CALL XABORT('LCMCAR: INVALID CHARACTER <-> INTEGER CONVERSION')
      ELSE
         NBDIM= NBDIM/4
      ENDIF
      IF( LACTIO )THEN
*
*        CONVERT EACH CHARACTER*4 TO INTEGER
         DO 10 IBDIM= 1, NBDIM
            I0= TASCII(ICHAR(TEXT(IBDIM*4-3:IBDIM*4-3)))
            I1= TASCII(ICHAR(TEXT(IBDIM*4-2:IBDIM*4-2)))
            I2= TASCII(ICHAR(TEXT(IBDIM*4-1:IBDIM*4-1)))
            I3= TASCII(ICHAR(TEXT(IBDIM*4  :IBDIM*4  )))
            NITMA(IBDIM)= (I0+IBASE1*I1) + IBASE2*(I2+IBASE1*I3)
   10    CONTINUE
      ELSE
*
*        CONVERT INTEGER TO CHARACTER*4
         DO 20 IBDIM= 1, NBDIM
            J23=   NITMA(IBDIM)/IBASE2
            I3 =     J23/IBASE1
            I2 =     J23-IBASE1*I3
            J01=   NITMA(IBDIM)-J23*IBASE2
            I1 =     J01/IBASE1
            I0 =     J01-IBASE1*I1
            TEXT(IBDIM*4-3:IBDIM*4-3)= CHAR(IASCII(I0))
            TEXT(IBDIM*4-2:IBDIM*4-2)= CHAR(IASCII(I1))
            TEXT(IBDIM*4-1:IBDIM*4-1)= CHAR(IASCII(I2))
            TEXT(IBDIM*4  :IBDIM*4  )= CHAR(IASCII(I3))
   20    CONTINUE
      ENDIF
      RETURN
      END