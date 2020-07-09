*DECK SPHCPO
      SUBROUTINE SPHCPO(MAXISO,IPLIB,IPCPO,NMIL,NGRP,IMPX,ICAL)
*
*-----------------------------------------------------------------------
*
*Purpose:
* extract a Microlib corresponding to an elementary calculation in a
* Multicompo.
*
*Copyright:
* Copyright (C) 2012 Ecole Polytechnique de Montreal
*
*Author(s): A. Hebert
*
*Parameters: input
* MAXISO  maximum allocated space for output microlib TOC information.
* IPLIB   address of the output microlib LCM object.
* IPCPO   address of the multicompo object.
* NMIL    number of mixtures in the elementary calculation.
* NGRP    number of energy groups.
* IMPX    print parameter (equal to zero for no print).
* ICAL    index of the elementary calculation being considered.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPLIB,IPCPO
      INTEGER MAXISO,NMIL,NGRP,IMPX,ICAL
*----
*  LOCAL VARIABLES
*----
      PARAMETER (NSTATE=40,MAXED=50,IOUT=6)
      CHARACTER TEXT12*12,HSMG*131,HVECT1(MAXED)*8,HVECT2(MAXED)*8
      INTEGER ISTATE(NSTATE)
      TYPE(C_PTR) JPLIB,KPLIB,JPCPO,KPCPO,LPCPO,MPCPO,NPCPO,OPCPO
      INTEGER, ALLOCATABLE, DIMENSION(:) :: ITYP1,ITOD1,IMIX2,ITYP2,
     1 ITOD2,MILVO,MUP
      INTEGER, ALLOCATABLE, DIMENSION(:,:) :: HUSE1,HNAM1,HUSE2,HNAM2
      REAL, ALLOCATABLE, DIMENSION(:) :: DENS1,TEMP1,VOL1,DENS2,TEMP2,
     1 VOL2,ENER,DELT,VOLMI2
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(HUSE1(3,MAXISO),HNAM1(3,MAXISO),ITYP1(MAXISO),
     1 ITOD1(MAXISO),IMIX2(MAXISO),ITYP2(MAXISO),ITOD2(MAXISO),
     2 HUSE2(3,MAXISO),HNAM2(3,MAXISO),MILVO(NMIL))
      ALLOCATE(DENS1(MAXISO),TEMP1(MAXISO),VOL1(MAXISO),DENS2(MAXISO),
     1 TEMP2(MAXISO),VOL2(MAXISO),ENER(NGRP+1),DELT(NGRP),VOLMI2(NMIL))
*----
*  MICROLIB INITIALIZATION
*----
      NBISO2=0
      NCOMB2=0
      NED2=0
      TEXT12='L_LIBRARY'
      CALL LCMPTC(IPLIB,'SIGNATURE',12,1,TEXT12)
      CALL XDRSET(VOLMI2,NMIL,0.0)
      CALL XDRSET(DENS2,MAXISO,0.0)
      CALL XDRSET(VOL2,MAXISO,0.0)
      CALL XDRSET(TEMP2,MAXISO,0.0)
      CALL XDISET(IMIX2,MAXISO,0)
      CALL XDISET(ITYP2,MAXISO,0)
      CALL XDISET(ITOD2,MAXISO,0)
*----
*  RECOVER NDEPL
*----
      NDEPL=0
      CALL LCMLEN(IPCPO,'DEPL-CHAIN',ILONG,ITYLCM)
      IF(ILONG.NE.0) THEN
         CALL LCMSIX(IPCPO,'DEPL-CHAIN',1)
         CALL LCMGET(IPCPO,'STATE-VECTOR',ISTATE)
         NDEPL=ISTATE(1)
         CALL LCMSIX(IPCPO,' ',2)
      ENDIF
*----
*  LOOP OVER MICROLIB MIXTURES
*----
      CALL XDISET(MILVO,NMIL,0)
      NCOMB=0
      JPCPO=LCMGID(IPCPO,'MIXTURES')
      ITRANC=0
      NDEL=0
      NDFI=0
      NL=0
      NW=0
      DO 190 IBM=1,NMIL
      KPCPO=LCMGIL(JPCPO,IBM)
      LPCPO=LCMGID(KPCPO,'CALCULATIONS')
*----
*  SELECT ICAL-TH ELEMENTARY CALCULATION
*----
      MPCPO=LCMGIL(LPCPO,ICAL)
      IF(IMPX.GT.0) THEN
         WRITE(IOUT,'(33H SPHCPO: COMPO ACCESS FOR MIXTURE,I6,6H AND C,
     1   10HALCULATION,I5)') IBM,ICAL
         IF(IMPX.GT.50) CALL LCMLIB(MPCPO)
      ENDIF
      CALL LCMGET(MPCPO,'STATE-VECTOR',ISTATE)
      NL=ISTATE(4)
      ITRANC=ISTATE(5)
      NDEPL=MAX(ISTATE(11),NDEPL)
      NDEL=ISTATE(19)
      NDFI=ISTATE(20)
      NW=MAX(NW,ISTATE(25))
      IF(ISTATE(1).NE.1) CALL XABORT('SPHCPO: INVALID NUMBER OF MATERI'
     1 //'AL MIXTURES IN THE COMPO.')
      IF(ISTATE(3).NE.NGRP) CALL XABORT('SPHCPO: INVALID NUMBER OF ENE'
     1 //'RGY GROUPS IN THE COMPO.')
      NBISO1=ISTATE(2)
      IF(NBISO1.GT.MAXISO) CALL XABORT('SPHCPO: MAXISO OVERFLOW(1).')
      NED1=ISTATE(13)
      IF(NED1.GT.MAXED) CALL XABORT('SPHCPO: MAXED OVERFLOW.')
      CALL LCMLEN(MPCPO,'MIXTURESVOL',ILONG,ITYLCM)
      IF(ILONG.GT.0) CALL LCMGET(MPCPO,'MIXTURESVOL',VOLMI2(IBM))
      CALL LCMGET(MPCPO,'ISOTOPESUSED',HUSE1)
      CALL LCMGET(MPCPO,'ISOTOPERNAME',HNAM1)
      CALL LCMGET(MPCPO,'ISOTOPESDENS',DENS1)
      CALL LCMGET(MPCPO,'ISOTOPESTYPE',ITYP1)
      CALL LCMGET(MPCPO,'ISOTOPESTODO',ITOD1)
      CALL LCMGET(MPCPO,'ISOTOPESVOL',VOL1)
      CALL LCMGET(MPCPO,'ISOTOPESTEMP',TEMP1)
      IF(NED1.GT.0) CALL LCMGTC(MPCPO,'ADDXSNAME-P0',8,NED1,HVECT1)
      CALL LCMGET(MPCPO,'ENERGY',ENER)
      CALL LCMGET(MPCPO,'DELTAU',DELT)
      DO 30 IED1=1,NED1
      DO 20 IED2=1,NED2
      IF(HVECT1(IED1).EQ.HVECT2(IED2)) GO TO 30
   20 CONTINUE
      NED2=NED2+1
      HVECT2(NED2)=HVECT1(IED1)
   30 CONTINUE
      IF(IBM.GT.9999) CALL XABORT('SPHCPO: IBM OVERFLOW.')
      DO 100 ISO=1,NBISO1 ! compo isotope
      WRITE(TEXT12,'(2A4,I4.4)') (HUSE1(I,ISO),I=1,2),IBM
      DO 60 JSO=1,NBISO2 ! microlib isotope
      IF((HUSE1(1,ISO).EQ.HUSE2(1,JSO)).AND.(HUSE1(2,ISO).EQ.
     1 HUSE2(2,JSO)).AND.(IMIX2(JSO).EQ.IBM)) THEN
         IF(ITYP1(ISO).NE.ITYP2(JSO)) THEN
            WRITE(HSMG,500) 'ITYP',ISO,ITYP1(ISO),ITYP2(JSO)
            CALL XABORT(HSMG)
         ENDIF
         JSO1=JSO
         GO TO 90
      ENDIF
   60 CONTINUE
      NBISO2=NBISO2+1
      IF(NBISO2.GT.MAXISO) THEN
         WRITE(IOUT,'(/16H SPHCPO: NBISO2=,I6,8H MAXISO=,I6)') NBISO2,
     1   MAXISO
         CALL XABORT('SPHCPO: MAXISO OVERFLOW(2).')
      ENDIF
      READ(TEXT12,'(3A4)') (HUSE2(I0,NBISO2),I0=1,3)
      DO 70 I0=1,3
   70 HNAM2(I0,NBISO2)=HNAM1(I0,ISO)
      IMIX2(NBISO2)=IBM
      ITYP2(NBISO2)=ITYP1(ISO)
      ITOD2(NBISO2)=ITOD1(ISO)
      IF(ITYP2(NBISO2).EQ.1) ITOD2(NBISO2)=1
      DENS2(NBISO2)=0.0
      JSO1=NBISO2
      IF(ITOD2(NBISO2).NE.1) THEN
         DO 80 J=1,NCOMB
         IF(IBM.EQ.MILVO(J)) GO TO 90
   80    CONTINUE
         NCOMB=NCOMB+1
         IF(NCOMB.GT.NMIL) CALL XABORT('SPHCPO: MILVO OVERFLOW.')
         MILVO(NCOMB)=IBM
      ENDIF
   90 DENS2(JSO1)=DENS1(ISO)
      VOL2(JSO1)=VOL1(ISO)
      TEMP2(JSO1)=TEMP1(ISO)
  100 CONTINUE
*----
*  PROCESS ISOTOPE DIRECTORIES FOR MICROLIB MIXTURE IBM
*----
      JPLIB=LCMLID(IPLIB,'ISOTOPESLIST',NBISO2)
      DO 180 ISO=1,NBISO2 ! microlib isotope
      IF(IMIX2(ISO).NE.IBM) GO TO 180
      DO 120 JSO=1,NBISO1 ! compo isotope
      IF((HUSE1(1,JSO).EQ.HUSE2(1,ISO)).AND.(HUSE1(2,JSO).EQ.
     1 HUSE2(2,ISO))) THEN
        JSO1=JSO
        GO TO 130
      ENDIF
  120 CONTINUE
      WRITE(TEXT12,'(3A4)') (HUSE2(I0,ISO),I0=1,3)
      CALL XABORT('SPHCPO: UNABLE TO FIND '//TEXT12//'.')
  130 KPLIB=LCMDIL(JPLIB,ISO) ! set ISO-th isotope
      MPCPO=LCMGIL(LPCPO,ICAL)
      NPCPO=LCMGID(MPCPO,'ISOTOPESLIST')
      CALL LCMLEL(NPCPO,JSO1,ILENG,ITYLCM)
      IF(ILENG.NE.0) THEN
         OPCPO=LCMGIL(NPCPO,JSO1) ! set JSO1-th isotope
         CALL LCMEQU(OPCPO,KPLIB)
      ENDIF
  180 CONTINUE
  190 CONTINUE
*----
*  MICROLIB FINALIZATION
*----
      CALL XDISET(ISTATE,NSTATE,0)
      ISTATE(1)=NMIL
      ISTATE(2)=NBISO2
      ISTATE(3)=NGRP
      ISTATE(4)=NL
      ISTATE(5)=ITRANC
      ISTATE(7)=1
      ISTATE(11)=NDEPL
      ISTATE(12)=NCOMB+NCOMB2
      ISTATE(13)=NED2
      ISTATE(14)=NMIL
      ISTATE(18)=1
      ISTATE(19)=NDEL
      ISTATE(20)=NDFI
      ISTATE(22)=MAXISO/NMIL
      ISTATE(25)=NW
      IF(NBISO2.EQ.0) CALL XABORT('SPHCPO: NBISO2=0.')
      CALL LCMPUT(IPLIB,'STATE-VECTOR',NSTATE,1,ISTATE)
      CALL LCMPUT(IPLIB,'MIXTURESVOL',NMIL,2,VOLMI2)
      CALL LCMPUT(IPLIB,'ISOTOPESUSED',3*NBISO2,3,HUSE2)
      CALL LCMPUT(IPLIB,'ISOTOPERNAME',3*NBISO2,3,HNAM2)
      CALL LCMPUT(IPLIB,'ISOTOPESDENS',NBISO2,2,DENS2)
      CALL LCMPUT(IPLIB,'ISOTOPESMIX',NBISO2,1,IMIX2)
      CALL LCMPUT(IPLIB,'ISOTOPESTYPE',NBISO2,1,ITYP2)
      CALL LCMPUT(IPLIB,'ISOTOPESTODO',NBISO2,1,ITOD2)
      CALL LCMPUT(IPLIB,'ISOTOPESVOL',NBISO2,2,VOL2)
      CALL LCMPUT(IPLIB,'ISOTOPESTEMP',NBISO2,2,TEMP2)
      IF(NED2.GT.0) CALL LCMPTC(IPLIB,'ADDXSNAME-P0',8,NED2,HVECT2)
      CALL LCMPUT(IPLIB,'ENERGY',NGRP+1,2,ENER)
      CALL LCMPUT(IPLIB,'DELTAU',NGRP,2,DELT)
      IF(IMPX.GT.5) CALL LCMLIB(IPLIB)
*----
*  BUILD EMBEDDED MACROLIB
*----
      ALLOCATE(MUP(NMIL))
      CALL XDISET(MUP,NMIL,1)
      CALL SPHEMB(IPLIB,IPCPO,NGRP,NMIL,MUP)
      DEALLOCATE(MUP)
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(VOLMI2,DELT,ENER,VOL2,TEMP2,DENS2,VOL1,TEMP1,DENS1)
      DEALLOCATE(MILVO,HNAM2,HUSE2,ITOD2,ITYP2,IMIX2,ITOD1,ITYP1,HNAM1,
     1 HUSE1)
      RETURN
*
  500 FORMAT(8HSPHCPO: ,A,1H(,I4,2H)=,2I5)
      END