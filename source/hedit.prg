
/*
 *$Id: hedit.prg,v 1.87 2008-07-25 00:29:50 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

STATIC lColorinFocus := .F.

#include "windows.ch"
#include "hbclass.ch"
#include "hblang.ch"
#include "guilib.ch"

#ifndef GWL_STYLE
   #define GWL_STYLE           - 16
#endif

CLASS HEdit INHERIT HControl

CLASS VAR winclass   INIT "EDIT"
   DATA bColorOld
   DATA lMultiLine   INIT .F.
   DATA cType        INIT "C"
   DATA bSetGet
   DATA bValid
   DATA bkeydown, bkeyup
   DATA cPicFunc, cPicMask
   DATA lPicComplex    INIT .F.
   DATA lFirst         INIT .T.
   DATA lChanged       INIT .F.
   DATA nMaxLenght     INIT Nil
   DATA nColorinFocus  INIT vcolor( 'CCFFFF' )
   DATA lnoValid       INIT .F.

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, lNoBorder, nMaxLenght )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( oWnd, nId, vari, bSetGet, oFont, bInit, bSize, bDraw, bGfocus, ;
                    bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLenght, lMultiLine )
   METHOD Init()
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, Self )
   METHOD Refresh()
   METHOD SetText( c )
   METHOD ParsePict( cPicture, vari ) INLINE ParsePict( Self, cPicture, vari )

   /* AJ: 11-03-2007
      For More Cl*per like :-)
   */
   METHOD VarPut( value ) INLINE ::SetGet( value )
   METHOD VarGet() INLINE ::SetGet()

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
            tcolor, bcolor, cPicture, lNoBorder, nMaxLenght, lPassword, bKeyDown, bChange ) CLASS HEdit

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), ;
                        WS_TABSTOP + IIf( lNoBorder == Nil.OR. ! lNoBorder, WS_BORDER, 0 ) + ;
                        IIf( lPassword == Nil .or. ! lPassword, 0, ES_PASSWORD )  )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, GetSysColor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   IF bSetGet == Nil
      ::title := vari
   ENDIF
   ::bSetGet := bSetGet
   ::bKeyDown := bKeyDown
   IF Hwg_BitAnd( nStyle, ES_MULTILINE ) != 0
      ::style := Hwg_BitOr( ::style, ES_WANTRETURN )
      ::lMultiLine := .T.
   ENDIF
   IF ::cType == "N" .and. Hwg_BitAnd( nStyle, ES_LEFT + ES_CENTER ) == 0
      ::style := Hwg_BitOr( ::style, ES_RIGHT + ES_NUMBER )
   ENDIF
   IF ! Empty( cPicture ) .or. cPicture == Nil .And. nMaxLenght != Nil .or. ! Empty( nMaxLenght )
      ::nMaxLenght := nMaxLenght
   ENDIF

   ParsePict( Self, cPicture, vari )
   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      IF bGfocus != Nil
         ::lnoValid := .T.
      ENDIF
      ::oParent:AddEvent( EN_SETFOCUS, self, { | o, id | __When( o:FindControl( id ) ) },,"onGotFocus"  )
      ::oParent:AddEvent( EN_KILLFOCUS, self, { | o, id | __Valid( o:FindControl( id ) ) },,"onLostFocus" )
      ::bValid := { | o | __Valid( o ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, self, bGfocus,,"onGotFocus" )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, self, bLfocus,,"onLostFocus"  )
      ENDIF
   ENDIF
   IF bChange != Nil
      ::oParent:AddEvent( EN_CHANGE, self, bChange,,"onChange"  )
   ENDIF
   ::bColorOld:=::bColor

   RETURN Self

METHOD Activate CLASS HEdit
   IF !empty( ::oParent:handle ) 
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit
   LOCAL oParent := ::oParent, nPos, nctrl
   LOCAL nextHandle

   IF ::bOther != Nil
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF

   IF ! ::lMultiLine

      IF ::bSetGet != Nil
         IF msg == WM_CHAR

            IF wParam == VK_BACK
               ::lFirst := .F.
               SetGetUpdated( Self )
               DeleteChar( Self, .T. )
               RETURN 0
            ELSEIF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
               RETURN - 1
            ELSEIF wParam == VK_TAB
               RETURN 0
            ENDIF
            IF ! IsCtrlShift( , .F. )
               RETURN GetApplyKey( Self, Chr( wParam ) )
            ENDIF

         ELSEIF msg == WM_KEYDOWN
            IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
              IF !Eval( ::bKeyDown, Self, wParam )
                  RETURN 0
               ENDIF
            ENDIF

            IF wParam == 40     // KeyDown
               IF ! IsCtrlShift()
                  GetSkip( oParent, ::handle, , 1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 38     // KeyUp
               IF ! IsCtrlShift()
                  GetSkip( oParent, ::handle, , -1 )
                  RETURN 0
               ENDIF
            ELSEIF wParam == 39     // KeyRight
               IF ! IsCtrlShift()
                  ::lFirst := .F.
                  RETURN KeyRight( Self )
               ENDIF
            ELSEIF wParam == 37     // KeyLeft
               IF ! IsCtrlShift()
                  ::lFirst := .F.
                  RETURN KeyLeft( Self )
               ENDIF
            ELSEIF wParam == 35     // End
               IF ! IsCtrlShift()
					   ::lFirst := .F.
                  IF ::cType == "C"
                     nPos := Len( Trim( ::title ) )
                     SendMessage( ::handle, EM_SETSEL, nPos, nPos )
                     RETURN 0
                  ENDIF
               ENDIF
            ELSEIF wParam == 45     // Insert
               IF ! IsCtrlShift()
                  SET( _SET_INSERT, ! SET( _SET_INSERT ) )
               ENDIF
            ELSEIF wParam == 46     // Del
               ::lFirst := .F.
               SetGetUpdated( Self )
               DeleteChar( Self, .F. )
               RETURN 0
            ELSEIF wParam == VK_TAB     // Tab
               GetSkip( oParent, ::handle, , ;
					        iif( IsCtrlShift(.f., .t.), -1, 1) )
               RETURN 0
            ELSEIF wParam == VK_RETURN  // Enter
               GetSkip( oParent, ::handle, .T., 1 )
               RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONDOWN
            IF GetFocus() != ::handle
               SetFocus(::handle)
               RETURN 0
            ENDIF

         ELSEIF msg == WM_LBUTTONUP
            IF Empty( GetEditText( oParent:handle, ::id ) )
               SendMessage( ::handle, EM_SETSEL, 0, 0 )
            ENDIF

         ENDIF
      ELSE
         IF msg == WM_KEYDOWN
            IF wParam == VK_TAB     // Tab
               nexthandle := GetNextDlgTabItem ( GetActiveWindow(), GetFocus(), ;
					                                  IsCtrlShift(.f., .t.) )
               SetFocus( nexthandle )
               RETURN 0
            END
         END
      ENDIF
      IF lColorinFocus
         IF msg == WM_SETFOCUS
//            ::bColorOld := ::bcolor
            ::SetColor( ::tcolor , ::nColorinFocus, .T. )
         ELSEIF msg == WM_KILLFOCUS
            ::SetColor( ::tcolor, ::bColorOld, .t. )
         ENDIF
      ENDIF
   ELSE

      IF msg == WM_MOUSEWHEEL
         nPos := HIWORD( wParam )
         nPos := IIf( nPos > 32768, nPos - 65535, nPos )
         SendMessage( ::handle, EM_SCROLL, IIf( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
         SendMessage( ::handle, EM_SCROLL, IIf( nPos > 0, SB_LINEUP, SB_LINEDOWN ), 0 )
      ENDIF
      IF msg == WM_KEYDOWN
         IF wParam == VK_ESCAPE
            return 0
         ENDIF
         IF wParam == VK_TAB     // Tab
            GetSkip( oParent, ::handle, , ;
				         iif( IsCtrlShift(.f., .t.), -1, 1) )
            RETURN 0
         ENDIF
      ENDIF
   ENDIF

   //IF msg == WM_KEYDOWN
   IF msg == WM_KEYUP .OR. msg == WM_SYSKEYUP     /* BETTER FOR DESIGNER */

            IF ::bKeyUp != Nil
              IF !Eval( ::bKeyUp,Self,wParam )
                  RETURN -1
               ENDIF
            ENDIF

      IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
         DO WHILE oParent != Nil .AND. ! __ObjHasMsg( oParent, "GETLIST" )
            oParent := oParent:oParent
         ENDDO
         IF oParent != Nil .AND. ! Empty( oParent:KeyList )
            nctrl := IIf( IsCtrlShift(.t., .f.), FCONTROL, iif(IsCtrlShift(.f., .t.), FSHIFT, 0 ) )
            IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == wParam } ) ) > 0
               Eval( oParent:KeyList[ nPos, 3 ], Self )
            ENDIF
         ENDIF
      ENDIF
   ELSEIF msg == WM_GETDLGCODE
      IF ! ::lMultiLine
         RETURN DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, ;
                 bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, nMaxLenght, lMultiLine, bKeyDown, bChange )  CLASS HEdit


   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf( bcolor == Nil, GetSysColor( COLOR_BTNHIGHLIGHT ), bcolor ) )
   ::bKeyDown := bKeyDown
   IF ValType( lMultiLine ) == "L"
      ::lMultiLine := lMultiLine
   ENDIF

   IF vari != Nil
      ::cType   := ValType( vari )
   ENDIF
   ::bSetGet := bSetGet

   IF ! Empty( cPicture ) .or. cPicture == Nil .And. nMaxLenght != Nil .or. ! Empty( nMaxLenght )
      ::nMaxLenght := nMaxLenght
   ENDIF

   ParsePict( Self, cPicture, vari )

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( EN_SETFOCUS, self, { | o, id | __When( o:FindControl( id ) ) },,"onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS, self, { | o, id | __Valid( o:FindControl( id ) ) },,"onLostFocus" )
      ::bValid := { | o | __Valid( o ) }
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, self, bGfocus,,"onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, self, bLfocus,,"onLostFocus" )
      ENDIF
   ENDIF
   IF bChange != Nil
      ::oParent:AddEvent( EN_CHANGE, self, bChange,,"onChange"  )
   ENDIF
   ::bColorOld := ::bColor

   RETURN Self

METHOD Init()  CLASS HEdit

   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitEditProc( ::handle )
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Refresh()  CLASS HEdit
   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,, Self )
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         vari := Transform( vari, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         vari := IIf( ::cType == "D", DToC( vari ), IIf( ::cType == "N", Str( vari ), IIf( ::cType == "C" .and. ValType(vari) == "C", Trim(vari), "" ) ) )
      ENDIF
      ::title := vari
      SetDlgItemText( ::oParent:handle, ::id, vari )
   ELSE
      SetDlgItemText( ::oParent:handle, ::id, ::title )
   ENDIF

   RETURN Nil

METHOD SetText( c ) CLASS HEdit

   IF c != Nil
      IF ValType( c ) = "O"
         //in run time return object
         RETURN nil
      ENDIF
      IF ! Empty( ::cPicFunc ) .OR. ! Empty( ::cPicMask )
         ::title := Transform( c, ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
      ELSE
         ::title := c
      ENDIF
      Super:SetText( ::title )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, c, Self )
      ENDIF
   ENDIF

   RETURN NIL

STATIC FUNCTION IsCtrlShift( lCtrl, lShift )
   LOCAL cKeyb := GetKeyboardState()

   IF lCtrl == Nil ; lCtrl := .T. ; ENDIF
   IF lShift == Nil ; lShift := .T. ; ENDIF
   RETURN ( lCtrl .AND. ( Asc( SubStr( cKeyb, VK_CONTROL + 1, 1 ) ) >= 128 ) ) .OR. ;
   ( lShift .AND. ( Asc( SubStr( cKeyb, VK_SHIFT + 1, 1 ) ) >= 128 ) )

STATIC FUNCTION ParsePict( oEdit, cPicture, vari )
   LOCAL nAt, i, masklen, cChar

   IF oEdit:bSetGet == Nil
      RETURN Nil
   ENDIF
   oEdit:cPicFunc := oEdit:cPicMask := ""
   IF cPicture != Nil
      IF Left( cPicture, 1 ) == "@"
         nAt := At( " ", cPicture )
         IF nAt == 0
            oEdit:cPicFunc := Upper( cPicture )
            oEdit:cPicMask := ""
         ELSE
            oEdit:cPicFunc := Upper( SubStr( cPicture, 1, nAt - 1 ) )
            oEdit:cPicMask := SubStr( cPicture, nAt + 1 )
         ENDIF
         IF oEdit:cPicFunc == "@"
            oEdit:cPicFunc := ""
         ENDIF
      ELSE
         oEdit:cPicFunc   := ""
         oEdit:cPicMask   := cPicture
      ENDIF
   ENDIF

   IF Empty( oEdit:cPicMask )
      IF oEdit:cType == "D"
         oEdit:cPicMask := StrTran( DToC( CToD( Space( 8 ) ) ), ' ', '9' )
      ELSEIF oEdit:cType == "N"
         vari := Str( vari )
         IF ( nAt := At( ".", vari ) ) > 0
            oEdit:cPicMask := Replicate( '9', nAt - 1 ) + "." + ;
                              Replicate( '9', Len( vari ) - nAt )
         ELSE
            oEdit:cPicMask := Replicate( '9', Len( vari ) )
         ENDIF
      ENDIF
   ENDIF

   IF ! Empty( oEdit:cPicMask )
      masklen := Len( oEdit:cPicMask )
      FOR i := 1 TO masklen
         cChar := SubStr( oEdit:cPicMask, i, 1 )
         IF ! cChar $ "!ANX9#"
            oEdit:lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF
   RETURN Nil

STATIC FUNCTION IsEditable( oEdit, nPos )
   LOCAL cChar

   IF Empty( oEdit:cPicMask )
      RETURN .T.
   ENDIF
   IF nPos > Len( oEdit:cPicMask )
      RETURN .F.
   ENDIF

   cChar := SubStr( oEdit:cPicMask, nPos, 1 )

   IF oEdit:cType == "C"
      RETURN cChar $ "!ANX9#"
   ELSEIF oEdit:cType == "N"
      RETURN cChar $ "9#$*"
   ELSEIF oEdit:cType == "D"
      RETURN cChar == "9"
   ELSEIF oEdit:cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

   RETURN .F.

STATIC FUNCTION KeyRight( oEdit, nPos )
   LOCAL masklen, newpos

   IF oEdit == Nil
      RETURN - 1
   ENDIF
   IF nPos == Nil
      nPos := HIWORD( SendMessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF oEdit:cPicMask == Nil .OR. Empty( oEdit:cPicMask )
      SendMessage( oEdit:handle, EM_SETSEL, nPos, nPos )
   ELSE
      masklen := Len( oEdit:cPicMask )
      DO WHILE nPos <= masklen
         IF IsEditable( oEdit, ++ nPos )
            SendMessage( oEdit:handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF ! Empty( oEdit:cPicMask )
      newpos := Len( oEdit:cPicMask )
      //writelog( "KeyRight-2 "+str(nPos) + " " +str(newPos) )
      IF nPos > newpos .and. ! Empty( Trim( oEdit:Title ) )
         SendMessage( oEdit:handle, EM_SETSEL, newpos, newpos )
      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION KeyLeft( oEdit, nPos )

   IF oEdit == Nil
      RETURN - 1
   ENDIF
   IF nPos == Nil
      nPos := HIWORD( SendMessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + 1
   ENDIF
   IF oEdit:cPicMask == Nil .OR. Empty( oEdit:cPicMask )
      SendMessage( oEdit:handle, EM_SETSEL, nPos - 2, nPos - 2 )
   ELSE
      DO WHILE nPos >= 1
         IF IsEditable( oEdit, -- nPos )
            SendMessage( oEdit:handle, EM_SETSEL, nPos - 1, nPos - 1 )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   RETURN 0

STATIC FUNCTION DeleteChar( oEdit, lBack )
   LOCAL nSel := SendMessage( oEdit:handle, EM_GETSEL, 0, 0 )
   LOCAL nPosEnd   := HIWORD( nSel )
   LOCAL nPosStart := LOWORD( nSel )
   LOCAL nGetLen := Len( oEdit:cPicMask )
   LOCAL cBuf, nPosEdit

   IF Hwg_BitAnd( GetWindowLong( oEdit:handle, GWL_STYLE ), ES_READONLY ) != 0
      RETURN Nil
   ENDIF
   IF nGetLen == 0
      nGetLen := Len( oEdit:title )
   ENDIF
   IF nPosEnd == nPosStart
      nPosEnd += IIf( lBack, 1, 2 )
      nPosStart -= IIf( lBack, 1, 0 )
   ELSE
      nPosEnd += 1
   ENDIF
   IF Empty(SendMessage(oEdit:handle, EM_GETPASSWORDCHAR, 0, 0))
      cBuf := PadR( Left( oEdit:title, nPosStart ) + SubStr( oEdit:title, nPosEnd ), nGetLen )
   ELSE
      cBuf := Left( oEdit:title, nPosStart ) + SubStr( oEdit:title, nPosEnd )
   ENDIF
   IF oEdit:lPicComplex .AND. oEdit:cType <> "N" .and. ;
      ( nPosStart + nPosEnd > 0 )
      IF lBack .or. nPosStart <> ( nPosEnd - 2 )
         cBuf := Left( oEdit:title, nPosStart ) + Space( nPosEnd - nPosStart - 1 ) + SubStr( oEdit:title, nPosEnd )
      ELSE
         nPosEdit := FirstNotEditable( oEdit, nPosStart + 1 )
         IF nPosEdit > 0
            cBuf := Left( oEdit:title, nPosStart ) + if(IsEditable(oedit,nposStart+2),SubStr( oEdit:title, nPosStart + 2, 1 ) + "  " ,"  ")+ SubStr( oEdit:title, nPosEdit + 1 )
         ELSE
            cBuf := Left( oEdit:title, nPosStart ) + SubStr( oEdit:title, nPosStart + 2 ) + Space( nPosEnd - nPosStart - 1 )
         ENDIF
      ENDIF
      cBuf := Transform( cBuf, oEdit:cPicMask )
   ENDIF

   oEdit:title := cBuf
   SetDlgItemText( oEdit:oParent:handle, oEdit:id, oEdit:title )
   SendMessage( oEdit:handle, EM_SETSEL, nPosStart, nPosStart )
   RETURN Nil


STATIC FUNCTION Input( oEdit, cChar, nPos )
   LOCAL cPic

   IF ! Empty( oEdit:cPicMask ) .AND. nPos > Len( oEdit:cPicMask )
      RETURN Nil
   ENDIF
   IF oEdit:cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
      ELSEIF ! ( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF oEdit:cType == "D"

      IF ! ( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF oEdit:cType == "L"

      IF ! ( Upper( cChar ) $ "YNTF" )
         RETURN Nil
      ENDIF

   ENDIF

   IF ! Empty( oEdit:cPicFunc )
      cChar := Transform( cChar, oEdit:cPicFunc )
   ENDIF

   IF ! Empty( oEdit:cPicMask )
      cPic  := SubStr( oEdit:cPicMask, nPos, 1 )

      cChar := Transform( cChar, cPic )
      IF cPic == "A"
         IF ! IsAlpha( cChar )
            cChar := Nil
         ENDIF
      ELSEIF cPic == "N"
         IF ! IsAlpha( cChar ) .and. ! IsDigit( cChar )
            cChar := Nil
         ENDIF
      ELSEIF cPic == "9"
         IF ! IsDigit( cChar ) .and. cChar != "-"
            cChar := Nil
         ENDIF
      ELSEIF cPic == "#"
         IF ! IsDigit( cChar ) .and. ! ( cChar == " " ) .and. ! ( cChar $ "+-" )
            cChar := Nil
         ENDIF
      ELSE
         cChar:= Transform( cChar, cPic )
      ENDIF
   ENDIF

   RETURN cChar

STATIC FUNCTION GetApplyKey( oEdit, cKey )
   LOCAL nPos, nGetLen, nLen, vari, i, x, newPos
   LOCAL nDecimals

   /* AJ: 11-03-2007 */
   IF Hwg_BitAnd( GetWindowLong( oEdit:handle, GWL_STYLE ), ES_READONLY ) != 0
      RETURN 0
   ENDIF

   x := SendMessage( oEdit:handle, EM_GETSEL, 0, 0 )
   IF HIWORD( x ) != LOWORD( x )
      DeleteChar( oEdit, .f. )
   ENDIF

   oEdit:title := GetEditText( oEdit:oParent:handle, oEdit:id )
   IF oEdit:cType == "N" .and. cKey $ ".," .AND. ;
      ( nPos := At( ".", oEdit:cPicMask ) ) != 0
      IF oEdit:lFirst
         vari := 0
      ELSE
         vari := Trim( oEdit:title )
         FOR i := 2 TO Len( vari )
            IF ! IsDigit( SubStr( vari, i, 1 ) )
               vari := Left( vari, i - 1 ) + SubStr( vari, i + 1 )
            ENDIF
         NEXT
         vari := Val( vari )
      ENDIF
      IF ! Empty( oEdit:cPicFunc ) .OR. ! Empty( oEdit:cPicMask )
         oEdit:title := Transform( vari, oEdit:cPicFunc + IIf( Empty( oEdit:cPicFunc ), "", " " ) + oEdit:cPicMask )
      ENDIF
      SetDlgItemText( oEdit:oParent:handle, oEdit:id, oEdit:title )
      KeyRight( oEdit, nPos - 1 )
   ELSE

      IF oEdit:cType == "N" .AND. oEdit:lFirst
         nGetLen := Len( oEdit:cPicMask )
         IF ( nPos := At( ".", oEdit:cPicMask ) ) == 0
            oEdit:title := Space( nGetLen )
         ELSE
            oEdit:title := Space( nPos - 1 ) + "." + Space( nGetLen - nPos )
         ENDIF
         nPos := 1
      ELSE
         nPos := HIWORD( SendMessage( oEdit:handle, EM_GETSEL, 0, 0 ) ) + 1
      ENDIF
      cKey := Input( oEdit, cKey, nPos )
      IF cKey != Nil
         SetGetUpdated( oEdit )
         IF SET( _SET_INSERT ) .or. HIWORD( x ) != LOWORD( x )
            IF oEdit:lPicComplex
               nGetLen := Len( oEdit:cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF ! IsEditable( oEdit, nPos + nLen )
                     EXIT
                  ENDIF
               NEXT
               oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + ;
                              SubStr( oEdit:title, nPos, nLen - 1 ) + SubStr( oEdit:title, nPos + nLen )
            ELSE
               oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + ;
                              SubStr( oEdit:title, nPos )
            ENDIF

            IF ! Empty( oEdit:cPicMask ) .AND. Len( oEdit:cPicMask ) < Len( oEdit:title )
               oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + SubStr( oEdit:title, nPos + 1 )
            ENDIF
         ELSE
            oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + SubStr( oEdit:title, nPos + 1 )
         ENDIF
         IF !Empty(SendMessage(oEdit, EM_GETPASSWORDCHAR, 0, 0))
          oEdit:title := Left( oEdit:title, nPos - 1 ) + cKey + Trim( SubStr( oEdit:title, nPos + 1 ) )
         ELSEIF !Empty(oEdit:nMaxLenght)
            oEdit:title := PadR( oEdit:title, oEdit:nMaxLenght )
         ENDIF
         SetDlgItemText( oEdit:oParent:handle, oEdit:id, oEdit:title )
         KeyRight( oEdit, nPos )
         //Added By Sandro Freire
         IF oEdit:cType == "N"

            IF ! Empty( oEdit:cPicMask )

               nDecimals := Len( SubStr(  oEdit:cPicMask, At( ".", oEdit:cPicMask ), Len( oEdit:cPicMask ) ) )

               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len( oEdit:cPicMask ) - nDecimals

               IF "E" $ oEdit:cPicFunc .AND. nPos == newPos
                  GetApplyKey( oEdit, "," )
               ENDIF
            ENDIF

         ENDIF

      ENDIF
   ENDIF
   oEdit:lFirst := .F.

   RETURN 0

STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip, aMsgs

	IF !CheckFocus(oCtrl, .f.)
	   RETURN .t.
	ENDIF
   oCtrl:Refresh()
   oCtrl:lFirst := .T.
   nSkip := iif( GetKeyState( VK_UP ) < 0 .or. ;
	             (GetKeyState( VK_TAB ) < 0 .and. GetKeyState(VK_SHIFT) < 0 ),;
					  -1, 1 )
   IF oCtrl:bGetFocus != Nil
		aMsgs := SuspendMsgsHandling(oCtrl)
		octrl:lnoValid := .T.
		res := Eval( oCtrl:bGetFocus, oCtrl:title, oCtrl )
      RestoreMsgsHandling(oCtrl, aMsgs)
      octrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog(oCtrl)
         IF oCtrl == ATail(oParent:GetList)
            nSkip := -1
         ELSEIF oCtrl == oParent:getList[1]
            nSkip := 1
         ENDIF
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
RETURN res

STATIC FUNCTION __valid( oCtrl )
   LOCAL res, vari, oDlg, aMsgs

	IF !CheckFocus(oCtrl, .t.) .or. oCtrl:lNoValid
	   RETURN .t.
	ENDIF
   IF oCtrl:bSetGet != Nil
      IF ( oDlg := ParentGetDialog( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := UnTransform( oCtrl, GetEditText( oCtrl:oParent:handle, oCtrl:id ) )
         oCtrl:title := vari
         IF oCtrl:cType == "D"
            IF IsBadDate( vari )
               SetFocus( oCtrl:handle )
               RETURN .F.
            ENDIF
            vari := CToD( vari )
         ELSEIF oCtrl:cType == "N"
            vari := Val( LTrim( vari ) )
            oCtrl:title := Transform( vari, oCtrl:cPicFunc + IIf( Empty( oCtrl:cPicFunc ), "", " " ) + oCtrl:cPicMask )
            SetDlgItemText( oCtrl:oParent:handle, oCtrl:id, oCtrl:title )
         ENDIF
         Eval( oCtrl:bSetGet, vari, oCtrl )
         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF oCtrl:bLostFocus != Nil
            aMsgs := SuspendMsgsHandling(oCtrl)
			   res := Eval( oCtrl:bLostFocus, vari, oCtrl )
            RestoreMsgsHandling(oCtrl, aMsgs)
            if ! res
               SetFocus( oCtrl:handle )
               IF oDlg != Nil
                  oDlg:nLastKey := 0
               ENDIF
               RETURN .F.
            endif
         ENDIF
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION Untransform( oEdit, cBuffer )
   LOCAL xValue, cChar, nFor, minus

   IF oEdit:cType == "C"

      IF "R" $ oEdit:cPicFunc
         FOR nFor := 1 TO Len( oEdit:cPicMask )
            cChar := SubStr( oEdit:cPicMask, nFor, 1 )
            IF ! cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      ENDIF

      xValue := cBuffer

   ELSEIF oEdit:cType == "N"
      minus := ( Left( LTrim( cBuffer ), 1 ) == "-" )
      cBuffer := Space( FirstEditable( oEdit ) - 1 ) + SubStr( cBuffer, FirstEditable( oEdit ), LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 )

      IF "D" $ oEdit:cPicFunc
         FOR nFor := FirstEditable( oEdit ) TO LastEditable( oEdit )
            IF ! IsEditable( oEdit, nFor )
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ oEdit:cPicFunc
            cBuffer := Left( cBuffer, FirstEditable( oEdit ) - 1 ) +           ;
                       StrTran( SubStr( cBuffer, FirstEditable( oEdit ),      ;
                                        LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 ), ;
                                ".", " " ) + SubStr( cBuffer, LastEditable( oEdit ) + 1 )
            cBuffer := Left( cBuffer, FirstEditable( oEdit ) - 1 ) +           ;
                       StrTran( SubStr( cBuffer, FirstEditable( oEdit ),      ;
                                        LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 ), ;
                                ",", "." ) + SubStr( cBuffer, LastEditable( oEdit ) + 1 )
         ELSE
            cBuffer := Left( cBuffer, FirstEditable( oEdit ) - 1 ) +        ;
                       StrTran( SubStr( cBuffer, FirstEditable( oEdit ),   ;
                                        LastEditable( oEdit ) - FirstEditable( oEdit ) + 1 ), ;
                                ",", " " ) + SubStr( cBuffer, LastEditable( oEdit ) + 1 )
         ENDIF

         FOR nFor := FirstEditable( oEdit ) TO LastEditable( oEdit )
            IF ! IsEditable( oEdit, nFor ) .and. SubStr( cBuffer, nFor, 1 ) != "."
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ENDIF

      cBuffer := StrTran( cBuffer, Chr( 1 ), "" )

      cBuffer := StrTran( cBuffer, "$", " " )
      cBuffer := StrTran( cBuffer, "*", " " )
      cBuffer := StrTran( cBuffer, "-", " " )
      cBuffer := StrTran( cBuffer, "(", " " )
      cBuffer := StrTran( cBuffer, ")", " " )

      cBuffer := PadL( StrTran( cBuffer, " ", "" ), Len( cBuffer ) )

      IF minus
         FOR nFor := 1 TO Len( cBuffer )
            IF IsDigit( SubStr( cBuffer, nFor, 1 ) )
               EXIT
            ENDIF
         NEXT
         nFor --
         IF nFor > 0
            cBuffer := Left( cBuffer, nFor - 1 ) + "-" + SubStr( cBuffer, nFor + 1 )
         ELSE
            cBuffer := "-" + cBuffer
         ENDIF
      ENDIF

      xValue := cBuffer

   ELSEIF oEdit:cType == "L"

      cBuffer := Upper( cBuffer )
      xValue := "T" $ cBuffer .or. "Y" $ cBuffer .or. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF oEdit:cType == "D"

      IF "E" $ oEdit:cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

   RETURN xValue

STATIC FUNCTION FirstEditable( oEdit )
   LOCAL nFor, nMaxLen := Len( oEdit:cPicMask )

   IF IsEditable( oEdit, 1 )
      RETURN 1
   ENDIF

   FOR nFor := 2 TO nMaxLen
      IF IsEditable( oEdit, nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

STATIC FUNCTION FirstNotEditable( oEdit , nPos )
   LOCAL nFor, nMaxLen := Len( oEdit:cPicMask )

   FOR nFor := ++ nPos TO nMaxLen
      IF ! IsEditable( oEdit, nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

STATIC FUNCTION  LastEditable( oEdit )
   LOCAL nFor, nMaxLen := Len( oEdit:cPicMask )

   FOR nFor := nMaxLen TO 1 STEP - 1
      IF IsEditable( oEdit, nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

STATIC FUNCTION IsBadDate( cBuffer )
   LOCAL i, nLen

   IF ! Empty( CToD( cBuffer ) )
      RETURN .F.
   ENDIF
   nLen := Len( cBuffer )
   FOR i := 1 TO nLen
      IF IsDigit( SubStr( cBuffer, i, 1 ) )
         RETURN .T.
      ENDIF
   NEXT
   RETURN .F.

FUNCTION CreateGetList( oDlg )
   LOCAL i, j, aLen1 := Len( oDlg:aControls ), aLen2

   FOR i := 1 TO aLen1
      IF __ObjHasMsg( oDlg:aControls[ i ], "BSETGET" ) .AND. oDlg:aControls[ i ]:bSetGet != Nil
         AAdd( oDlg:GetList, oDlg:aControls[ i ] )
      ELSEIF ! Empty( oDlg:aControls[ i ]:aControls )
         aLen2 := Len( oDlg:aControls[ i ]:aControls )
         FOR j := 1 TO aLen2
            IF __ObjHasMsg( oDlg:aControls[ i ]:aControls[ j ], "BSETGET" ) .AND. oDlg:aControls[ i ]:aControls[ j ]:bSetGet != Nil
               AAdd( oDlg:GetList, oDlg:aControls[ i ]:aControls[ j ] )
            ENDIF
         NEXT
      ENDIF
   NEXT
   RETURN Nil

FUNCTION GetSkip( oParent, hCtrl, lClipper, nSkip )
   LOCAL nextHandle

   DEFAULT nSkip := 1

   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. ! oParent:lClipper )
      RETURN .F.
   ENDIF
   nextHandle := iif(oParent:className == "HTAB", NextFocusTab(oParent, hCtrl, nSkip), ;
	                                               NextFocus(oParent, hCtrl, nSkip))
   PostMessage( GetActiveWindow(), WM_NEXTDLGCTL, nextHandle , 1 )
RETURN .T.

STATIC FUNCTION NextFocusTab(oParent, hCtrl, nSkip)
   Local nextHandle := 0, i, nFirst , nLast

   if len(oParent:aPages) > 0
      oParent:GetActivePage(@nFirst, @nLast)
      i :=  AScan( oParent:oParent:acontrols, { | o | o:handle == hCtrl } )
      i += IIF( i == 0, nLast, nSkip)
      DO WHILE i >= nFirst .and. i <= nLast
        IF ! oParent:acontrols[ i ]:lHide .AND. IsWindowEnabled( oParent:acontrols[ i ]:Handle ) // ;
           nexthandle := GetNextDlgTabItem ( oParent:handle , hctrl, ( nSkip < 0 ) )
           exit
        ELSE
           setFocus(oParent:aControls[ i + nSkip ]:handle)
        ENDIF
        i += nSkip
      ENDDO
      IF i > nLast .OR. i <= nFirst  // ultimo objecto do tab
        nexthandle := GetNextDlgTabItem ( GetActiveWindow(), hctrl, (nSkip < 0) )
      ENDIF
   ENDIF
RETURN nextHandle

STATIC FUNCTION NextFocus(oParent,hCtrl,nSkip)

Local nextHandle :=0,  i

   i := AScan( oparent:acontrols, { | o | o:handle == hCtrl } )
   i += nSkip
   DO While i > 0 .AND. i <= Len(oParent:aControls)
      IF ! oParent:aControls[ i ]:lHide .AND. IsWindowEnabled( oParent:aControls[ i ]:handle ) // ;
         nextHandle := GetNextDlgTabItem ( GetActiveWindow() , hctrl, ( nSkip < 0 ) )
         EXIT
       ELSE
         setFocus(oParent:aControls[ i + nSkip ]:handle)
       ENDIF
       i += nSkip
   ENDDO
   IF nextHandle == 0
       nextHandle := GetNextDlgTabItem ( GetActiveWindow() , hctrl, ( nSkip < 0 ) )
   ENDIF
RETURN nextHandle

FUNCTION SetGetUpdated( o )

   o:lChanged := .T.
   IF ( o := ParentGetDialog( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

   RETURN Nil

FUNCTION ParentGetDialog( o )
   DO WHILE ( o := o:oParent ) != Nil .and. ! __ObjHasMsg( o, "GETLIST" )
   ENDDO
   RETURN o

FUNCTION SetColorinFocus( lDef )
   IF ValType( lDef ) <> "L"
      RETURN .F.
   ENDIF
   lColorinFocus := lDef
   RETURN .T.

/*
Luis Fernando Basso contribution
*/

FUNCTION SuspendMsgsHandling(oCtrl)
LOCAL aEvent:={}, i, nMsgNum

  IF oCtrl:Handle != getFocus()
    RETURN {}
  ENDIF
  nMsgNum := Len(oCtrl:oparent:aNotify)
  FOR i = 1 to nMsgNum
     IF oCtrl:oParent:aNotify[i,2] == oCtrl:id
        AAdd(aEvent, {.T.,i,oCtrl:oParent:aNotify[i]})
        oCtrl:oParent:aNotify[i] := {oCtrl:oParent:aNotify[i,1],oCtrl:oParent:aNotify[i,2],{|| .t.}}
     ENDIF
  NEXT
  nMsgNum := Len(oCtrl:oparent:aEvents)
  FOR i = 1 to nMsgNum
     IF oCtrl:oParent:aEvents[i,2] == oCtrl:id
        AAdd(aEvent, {.F.,i,oCtrl:oParent:aEvents[i]})
        oCtrl:oParent:aEvents[i] := {oCtrl:oParent:aEvents[i,1],oCtrl:oParent:aEvents[i,2],{|| .t.}}
     ENDIF
  NEXT
RETURN aEvent

FUNCTION RestoreMsgsHandling(oCtrl,aEvent)
Local i, nMsgNum := Len(aEvent)

  IF oCtrl:Handle != getFocus()
    RETURN Nil
  ENDIF
  FOR i = 1 to nMsgNum
    IF aEvent[i,3,2] == oCtrl:id //.AND. aEvent[i,2,3] != Nil
       IF aEvent[i,1]
          oCtrl:oParent:aNotify[aEvent[i,2]] := aEvent[i,3]
       ELSE
          oCtrl:oParent:aEvents[aEvent[i,2]] := aEvent[i,3]
       ENDIF
    ENDIF
  NEXT
RETURN Nil

FUNCTION CheckFocus(oCtrl, nInside)

  IF !IsWindowVisible(ParentGetDialog(oCtrl):handle) .OR. GetActiveWindow() == 0
     IF nInside
        ParentGetDialog(oCtrl):Show()
        SetFocus(ParentGetDialog(oCtrl):handle)
        SetFocus(GetFocus())
		  RETURN .f.
	  ENDIF
  ENDIF
RETURN .t.