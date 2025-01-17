/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HMonthCalendar class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define MCS_DAYSTATE             1
#define MCS_MULTISELECT          2
#define MCS_WEEKNUMBERS          4
#define MCS_NOTODAYCIRCLE        8
#define MCS_NOTODAY             16

CLASS HMonthCalendar INHERIT HControl

   CLASS VAR winclass   INIT "SysMonthCal32"

   DATA dValue
   DATA bChange

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
               lWeekNumbers )
   METHOD Activate()
   METHOD Init()
   METHOD Value ( dValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
            lWeekNumbers ) CLASS HMonthCalendar

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP )
   nStyle   += IIf( lNoToday == Nil.OR. ! lNoToday, 0, MCS_NOTODAY )
   nStyle   += IIf( lNoTodayCircle == Nil.OR. ! lNoTodayCircle, 0, MCS_NOTODAYCIRCLE )
   nStyle   += IIf( lWeekNumbers == Nil.OR. ! lWeekNumbers, 0, MCS_WEEKNUMBERS )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              ,, cTooltip )

   ::dValue   := IIf( ValType( vari ) == "D" .And. ! Empty( vari ), vari, Date() )

   ::bChange := bChange

   HWG_InitCommonControlsEx()

   IF bChange != Nil
      ::oParent:AddEvent( MCN_SELECT, ::id, bChange, .T., "onChange" )
      ::oParent:AddEvent( MCN_SELCHANGE, ::id, bChange, .T., "onChange" )
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HMonthCalendar

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_initmonthcalendar ( ::oParent:handle, ::id, ::style, ;
                                      ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HMonthCalendar

   IF ! ::lInit
      ::Super:Init()
      IF ! Empty( ::dValue )
         hwg_setmonthcalendardate( ::handle , ::dValue )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Value( dValue ) CLASS HMonthCalendar

   IF dValue != Nil
      IF ValType( dValue ) == "D" .And. ! Empty( dValue )
         hwg_setmonthcalendardate( ::handle, dValue )
         ::dValue := dValue
      ENDIF
   ELSE
      ::dValue := hwg_getmonthcalendardate( ::handle )
   ENDIF
   RETURN ::dValue

//--------------------------------------------------------------------------//

#pragma BEGINDUMP

#define _WIN32_IE      0x0500
#define HB_OS_WIN_32_USED
#ifndef _WIN32_WINNT
   #define _WIN32_WINNT   0x0400
#endif
#include "guilib.h"
#include <windows.h>
#include <commctrl.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbdate.h"

#if defined(__DMC__)
#include "missing.h"
#endif

HB_FUNC( HWG_INITMONTHCALENDAR )
{
   HWND hMC;
   RECT rc;

   hMC = CreateWindowEx( 0,
                         MONTHCAL_CLASS,
                         "",
                         (LONG) hb_parnl(3), /* 0,0,0,0, */
                         hb_parni(4), hb_parni(5),      /* x, y       */
                         hb_parni(6), hb_parni(7),      /* nWidth, nHeight */
                         (HWND) HB_PARHANDLE(1),
                         (HMENU) ( UINT_PTR ) hb_parni(2),
                         GetModuleHandle(NULL),
                         NULL );

   MonthCal_GetMinReqRect( hMC, &rc );

   //Setwindowpos( hMC, NULL, hb_parni(4), hb_parni(5), rc.right, rc.bottom, SWP_NOZORDER );
   SetWindowPos( hMC, NULL, hb_parni(4), hb_parni(5), hb_parni(6),hb_parni(7), SWP_NOZORDER );

    HB_RETHANDLE(  hMC );
}

HB_FUNC( HWG_SETMONTHCALENDARDATE ) // adaptation of hwg_Setdatepicker of file Control.c
{
   PHB_ITEM pDate = hb_param( 2, HB_IT_DATE );

   if( pDate )
   {
      SYSTEMTIME sysTime;
      #ifndef HARBOUR_OLD_VERSION
      int lYear, lMonth, lDay;
      #else
      long lYear, lMonth, lDay;
      #endif

      hb_dateDecode( hb_itemGetDL( pDate ), &lYear, &lMonth, &lDay );

      sysTime.wYear = (unsigned short) lYear;
      sysTime.wMonth = (unsigned short) lMonth;
      sysTime.wDay = (unsigned short) lDay;
      sysTime.wDayOfWeek = 0;
      sysTime.wHour = 0;
      sysTime.wMinute = 0;
      sysTime.wSecond = 0;
      sysTime.wMilliseconds = 0;

      MonthCal_SetCurSel( (HWND) HB_PARHANDLE (1), &sysTime);

   }
}

HB_FUNC( HWG_GETMONTHCALENDARDATE ) // adaptation of hwg_Getdatepicker of file Control.c
{
   SYSTEMTIME st;
   char szDate[9];

   SendMessage( (HWND) HB_PARHANDLE (1), MCM_GETCURSEL, 0, (LPARAM) &st);

   hb_dateStrPut( szDate, st.wYear, st.wMonth, st.wDay );
   szDate[8] = 0;
   hb_retds( szDate );
}

#pragma ENDDUMP


* --------------------------------------------------------------------------

FUNCTION hwg_pCalendar(dstartdate, cTitle , cOK, cCancel , nx , ny , wid, hei )

   * Date picker command for all platforms in the design of original
   * Windows only DATEPICKER command

   LOCAL oDlg, oMC , oFont , dolddate , dnewdate,  lcancel

  IF cTitle == NIL
     cTitle := "Calendar"
  ENDIF

  IF cOK == NIL
     cOK := "OK"
  ENDIF

  IF cCancel == NIL
     cCancel := "Cancel"
  ENDIF

  IF dstartdate == NIL
     dstartdate := DATE()
  ENDIF

  IF nx == NIL
     nx := 0  && old: 20
  ENDIF

  IF ny == NIL
     ny := 0  && old: 20
  ENDIF

  IF wid == NIL
     wid := 200 && old: 80
  ENDIF

  IF hei == NIL
     hei := 160 && old: 20
  ENDIF

  oFont := hwg_DefaultFont()

  lcancel := .T.

  * Remember old date
  dolddate := dstartdate

   INIT DIALOG oDlg TITLE cTitle ;
      AT nx,ny SIZE  wid , hei + 23 && wid , hei , 22 = height of buttons

   @ 0,0 MONTHCALENDAR oMC ;
      SIZE wid - 1 , hei - 1 ;
      INIT dstartdate ;   && Date(), if NIL
      FONT oFont

   @ 0 ,hei BUTTON cOK FONT oFont ;
      ON CLICK {|| lcancel := .F., dnewdate := oMC:Value , oDlg:Close() } SIZE 80 , 22
   @ 81,hei BUTTON cCancel FONT oFont ;
      ON CLICK {|| oDlg:Close() } SIZE 80, 22

   ACTIVATE DIALOG oDlg

   IF lcancel
      dnewdate := dolddate
   ENDIF

   RETURN dnewdate

FUNCTION hwg_oDatepicker_bmp()

   * Returns the bimap object of image Datepick_Button2.bmp
   * (size 11 x 11 )
   * for the multi platform datepicker based on HMONTHCALENDAR class

RETURN HBitmap():AddString("Datepick_Button", hwg_cHex2Bin(;
   "42 4D 6A 00 00 00 00 00 00 00 3E 00 00 00 28 00 " + ;
   "00 00 0B 00 00 00 0B 00 00 00 01 00 01 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 F0 FB FF 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 04 00 00 00 0E 00 " + ;
   "00 00 1F 00 00 00 3F 80 00 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 " ) )
