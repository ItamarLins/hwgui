/*
 * $Id: hlistbox.prg,v 1.14 2008-07-25 00:29:50 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HListBox class
 *
 * Copyright 2004 Vic McClung
 * 
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define LB_ERR              (-1)
#define LBN_SELCHANGE       1
#define LBN_DBLCLK          2
#define LBN_SETFOCUS        3
#define LBN_KILLFOCUS       4
#define LBN_EDITCHANGE      5
#define LBN_EDITUPDATE      6
#define LBN_DROPDOWN        7
#define LBN_CLOSEUP         8
#define LBN_SELENDOK        9
#define LBN_SELENDCANCEL    10


CLASS HListBox INHERIT HControl

   CLASS VAR winclass   INIT "LISTBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value         INIT 1
   DATA  bChangeSel
   DATA  lnoValid       INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,cTooltip )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bDraw,bChange,cTooltip )
   METHOD Init( aListbox, nCurrent )
   METHOD Refresh()
   METHOD Setitem( nPos )
   METHOD AddItems(p)
   METHOD Clear()
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
                  bInit,bSize,bPaint,bChange,cTooltip ) CLASS HListBox

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP+WS_VSCROLL+LBS_DISABLENOSCROLL+LBS_NOTIFY+LBS_NOINTEGRALHEIGHT+WS_BORDER )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet

   if aItems == Nil
        ::aItems := {}
   else
        ::aItems  := aItems
   endif

   ::Activate()

   IF bSetGet != Nil
      ::bChangeSel := bChange
      IF bChange != Nil
         ::lnoValid := .T.
      ENDIF
      ::oParent:AddEvent( LBN_SELCHANGE,self,{|o,id|__Valid(o:FindControl(id))},,"onChange" )
   ELSEIF bChange != Nil
      ::oParent:AddEvent( LBN_SELCHANGE,self,bChange,,"onChange" )
   ENDIF

Return Self

METHOD Activate CLASS HListBox
   IF !empty( ::oParent:handle ) 
      ::handle := CreateListbox( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,aItems,oFont,bInit,bSize,bPaint, ;
                  bChange,cTooltip ) CLASS HListBox

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
   ::bSetGet := bSetGet
   if aItems == Nil
        ::aItems := {}
   else
        ::aItems  := aItems
   endif

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE,self,{|o,id|__Valid(o:FindControl(id))},"onChange" )
   ENDIF
Return Self

METHOD Init() CLASS HListBox
Local i

   IF !::lInit
      Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            ::value := 1
         ENDIF
         SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            ListboxAddString( ::handle, ::aItems[i] )
         NEXT
         ListboxSetString( ::handle, ::value )
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HListBox
        Local vari
        IF ::bSetGet != Nil
                vari := Eval( ::bSetGet )
        ENDIF

        ::value := Iif( vari==Nil .OR. Valtype(vari)!="N",1,vari )
        ::SetItem(::value )
Return Nil

METHOD SetItem(nPos) CLASS HListBox
        ::value := nPos
        SendMessage( ::handle, LB_SETCURSEL, nPos - 1, 0)

        IF ::bSetGet != Nil
                Eval( ::bSetGet, ::value )
        ENDIF

        IF ::bChangeSel != Nil
                Eval( ::bChangeSel, ::value, Self )
        ENDIF
Return Nil

METHOD AddItems(p)
// Local i
   aadd(::aItems,p)
   ListboxAddString( ::handle, p )
//   SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
//   FOR i := 1 TO Len( ::aItems )
//      ListboxAddString( ::handle, ::aItems[i] )
//   NEXT
   ListboxSetString( ::handle, ::value )
return self

METHOD Clear()
   ::aItems := {}
   ::value := 1
   SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
   ListboxSetString( ::handle, ::value )
Return .T.

Static Function __Valid( oCtrl )
Local  res := .t., aMsgs

   IF oCtrl:lnoValid
      RETURN .T.
   ENDIF
   IF oCtrl:bSetGet != Nil
      oCtrl:value := SendMessage( oCtrl:handle,LB_GETCURSEL,0,0 ) + 1
   ENDIF
   aMsgs := SuspendMsgsHandling(oCtrl)
   IF oCtrl:bChangeSel != Nil
	   res := Eval( oCtrl:bLostFocus, oCtrl:value,  oCtrl )
   ENDIF
   RestoreMsgsHandling(oCtrl, aMsgs)
Return res
