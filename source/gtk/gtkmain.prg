/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Main prg level functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"

FUNCTION hwg_EndWindow()

   IF HWindow():GetMain() != Nil
      HWindow():aWindows[1]:Close()
   ENDIF

   RETURN Nil

FUNCTION hwg_VColor( cColor )

   LOCAL i, res := 0, n := 1, iValue

   cColor := Trim( cColor )
   for i := 1 TO Len( cColor )
      iValue := Asc( SubStr( cColor,Len(cColor ) - i + 1,1 ) )
      IF iValue < 58 .AND. iValue > 47
         iValue -= 48
      ELSEIF iValue >= 65 .AND. iValue <= 70
         iValue -= 55
      ELSEIF iValue >= 97 .AND. iValue <= 102
         iValue -= 87
      ELSE
         RETURN 0
      ENDIF
      res += iValue * n
      n *= 16
   next

   RETURN res

FUNCTION hwg_MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle )

   LOCAL oModDlg, oFont := HFont():Add( "Sans", 0, 12 )
   LOCAL cRes := ""

   nStyle := iif( nStyle == Nil, 0, nStyle )
   x := iif( x == Nil, 210, x )
   y := iif( y == Nil, 10, y )
   nDlgStyle := iif( nDlgStyle == Nil, 0, nDlgStyle )

   INIT DIALOG oModDlg TITLE cTitle AT x, y SIZE 300, 140 ;
      FONT oFont CLIPPER STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   @ 20, 10 SAY cText SIZE 260, 22
   @ 20, 35 GET cres  SIZE 260, 26 STYLE WS_DLGFRAME + WS_TABSTOP + nStyle
   Atail( oModDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 95 BUTTON "Ok" ID IDOK SIZE 100, 32 ON CLICK { ||oModDlg:lResult := .T. , hwg_EndDialog() } ON SIZE ANCHOR_BOTTOMABS
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON CLICK { ||hwg_EndDialog() } ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oModDlg

   oFont:Release()
   IF oModDlg:lResult
      RETURN Trim( cRes )
   ELSE
      cRes := ""
   ENDIF

   RETURN cRes

FUNCTION hwg_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel )

   LOCAL oDlg, oBrw, lNewFont := .F.
   LOCAL nChoice := 0, i, aLen := Len( arr ), nLen := 0, addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height, screenh

   IF cTitle == Nil; cTitle := ""; ENDIF
   IF nLeft == Nil; nLeft := 10; ENDIF
   IF nTop == Nil; nTop := 10; ENDIF
   IF oFont == Nil
      oFont := HFont():Add( "Times", 0, 14 )
      lNewFont := .T.
   ENDIF
   IF cOk != Nil
      minWidth += 120
      IF cCancel != Nil
         minWidth += 100
      ENDIF
      addY += 30
   ENDIF

   IF ValType( arr[1] ) == "A"
      FOR i := 1 TO aLen
         nLen := Max( nLen, Len( arr[i,1] ) )
      NEXT
   ELSE
      FOR i := 1 TO aLen
         nLen := Max( nLen, Len( arr[i] ) )
      NEXT
   ENDIF

   hDC := hwg_Getdc( HWindow():GetMain():handle )
   hwg_Selectobject( hDC, ofont:handle )
   aMetr := hwg_Gettextmetric( hDC )
   hwg_Releasedc( hwg_Getactivewindow(), hDC )
   height := ( aMetr[1] + 1 ) * aLen + 4 + addY
   screenh := hwg_Getdesktopheight()
   IF height > screenh * 2/3
      height := Int( screenh * 2/3 )
      addX := addY := 0
   ENDIF
   width := Max( minWidth, aMetr[2] * 2 * nLen + addX )

   INIT DIALOG oDlg TITLE cTitle ;
      AT nLeft, nTop           ;
      SIZE width, height       ;
      FONT oFont

   @ 0, 0 BROWSE oBrw ARRAY        ;
      SIZE  width, height - addY   ;
      FONT oFont                   ;
      STYLE WS_BORDER              ;
      ON SIZE {|o,x,y|o:Move( addX/2, 10, x - addX, y - addY )} ;
      ON CLICK { |o|nChoice := o:nCurrent, hwg_EndDialog( o:oParent:handle ) }

   IF ValType( arr[1] ) == "A"
      oBrw:AddColumn( HColumn():New( ,{ |value,o|o:aArray[o:nCurrent,1] },"C",nLen ) )
   ELSE
      oBrw:AddColumn( HColumn():New( ,{ |value,o|o:aArray[o:nCurrent] },"C",nLen ) )
   ENDIF
   hwg_CREATEARLIST( oBrw, arr )
   oBrw:lDispHead := .F.
   IF clrT != Nil
      oBrw:tcolor := clrT
   ENDIF
   IF clrB != Nil
      oBrw:bcolor := clrB
   ENDIF
   IF clrTSel != Nil
      oBrw:tcolorSel := clrTSel
   ENDIF
   IF clrBSel != Nil
      oBrw:bcolorSel := clrBSel
   ENDIF

   IF cOk != Nil
      x1 := Int( width/2 ) - iif( cCancel != Nil, 90, 40 )
      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ;
            ON CLICK { ||nChoice := oBrw:nCurrent, hwg_EndDialog( oDlg:handle ) } ;
            ON SIZE ANCHOR_BOTTOMABS
      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ;
            ON CLICK { ||hwg_EndDialog( oDlg:handle ) } ;
            ON SIZE ANCHOR_BOTTOMABS
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF

   RETURN nChoice

FUNCTION hwg_RefreshAllGets( oDlg )

   AEval( oDlg:GetList, { |o|o:Refresh() } )

   RETURN Nil

FUNCTION HWG_Version( n )

   IF !Empty( n )
      IF n == 1
         RETURN HWG_VERSION
      ELSEIF n == 2
         RETURN HWG_BUILD
      ENDIF
   ENDIF

   RETURN "HWGUI " + HWG_VERSION + " Build " + LTrim( Str( HWG_BUILD ) )

FUNCTION hwg_WriteStatus( oWnd, nPart, cText, lRedraw )

   LOCAL aControls, i

   aControls := oWnd:aControls
   IF ( i := Ascan( aControls, { |o|o:ClassName() == "HSTATUS" } ) ) > 0
      hwg_Writestatuswindow( aControls[i]:handle, nPart - 1, cText )

   ENDIF

   RETURN Nil

FUNCTION hwg_FindParent( hCtrl, nLevel )

   LOCAL i, oParent, hParent := hwg_Getparent( hCtrl )

   IF hParent > 0
      IF ( i := Ascan( HDialog():aModalDialogs,{ |o|o:handle == hParent } ) ) != 0
         RETURN HDialog():aModalDialogs[i]
      ELSEIF ( oParent := HDialog():FindDialog( hParent ) ) != Nil
         RETURN oParent
      ELSEIF ( oParent := HWindow():FindWindow( hParent ) ) != Nil
         RETURN oParent
      ENDIF
   ENDIF
   IF nLevel == Nil; nLevel := 0; ENDIF
   IF nLevel < 2
      IF ( oParent := hwg_FindParent( hParent,nLevel + 1 ) ) != Nil
         RETURN oParent:FindControl( , hParent )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_FindSelf( hCtrl )

   LOCAL oParent

   oParent := hwg_FindParent( hCtrl )
   IF oParent != Nil
      RETURN oParent:FindControl( , hCtrl )
   ENDIF

   RETURN Nil

