#xcommand ? [<explist,...>]  => OutPut( [<explist>] )
#xcommand TRY  => BEGIN SEQUENCE WITH { | oErr | Break( oErr ) }
#xcommand CATCH [<!oErr!>] => RECOVER [USING <oErr>] <-oErr->
#xcommand FINALLY => ALWAYS
#define   CRLF hb_OsNewLine()

static cBody, cOutPut := "", cContentType := "Text/html"

function Main()

   ? ValToChar( GetBody() ) // GetPostPairs() )
   ? Time()

return nil

function GetBody()

   local nLen, cBuffer

   if cBody == nil
      nLen  := Val( hb_GetEnv( "CONTENT_LENGTH" ) )
      cBody := Space( nLen )
      fread( hb_GetStdIn(), @cBody, nLen )
   endif   

return cBody

function GetPostPairs( lUrlDecode )

   local cPair
   local uPair
   local nTable
   local aTable
   local cKey
   local cTag	
   local hPairs  := {=>}
   local aPairs  := hb_ATokens( GetBody(), "&" )

   hb_default( @lUrlDecode, .T. )
   cTag := if( lUrlDecode, '[]', '%5B%5D' )
   
   for each cPair in aPairs
      if lUrlDecode
         cPair := hb_urlDecode( cPair )
      endif				
      if ( uPair := At( "=", cPair ) ) > 0	  
         cKey := Left( cPair, uPair - 1 )	
         if ( nTable := At( cTag, cKey ) ) > 0 		
            cKey   := Left( cKey, nTable - 1 )			
            aTable := HB_HGetDef( hPairs, cKey, {} ) 				
            AAdd( aTable, SubStr( cPair, uPair + 1 ) )				
            hPairs[ cKey ] := aTable
         else						
            hb_HSet( hPairs, cKey, SubStr( cPair, uPair + 1 ) )
         endif
      endif
   next
    
return hPairs

function Output( cText )

   cOutput += cText

return nil 

exit procedure OutputFlush

   local n, cKey
   // local hHeadersOut  := AP_HEADERSOUT()
   // local cContentType := AP_CONTENTTYPE()

   // for n = 1 to Len( hHeadersOut )
   //    outstd( cKey := HB_HKeyAt( hHeadersOut, n ) )
   //    outstd( ": " + hHeadersOut[ cKey ] )
   //    outstd( hb_OsNewLine() )
   // next
   
   outstd( "Content-type: " + cContentType )
   outstd( hb_OsNewLine() + hb_OsNewLine() )

   outstd( cOutput )
   cOutput = ""

return

function ValToChar( u )

   local cType := ValType( u )
   local cResult

   do case
      case cType == "C" .or. cType == "M"
           cResult = u

      case cType == "D"
           cResult = DToC( u )

      case cType == "L"
           cResult = If( u, ".T.", ".F." )

      case cType == "N"
           cResult = AllTrim( Str( u ) )

      case cType == "A"
           cResult = hb_ValToExp( u )

      case cType == "O"
           cResult = ObjToChar( u )

      case cType == "P"
           cResult = "(P)" 

      case cType == "S"
           cResult = "(Symbol)" 
 
      case cType == "H"
           cResult = StrTran( StrTran( hb_JsonEncode( u, .T. ), CRLF, "<br>" ), " ", "&nbsp;" )
           if Left( cResult, 2 ) == "{}"
              cResult = StrTran( cResult, "{}", "{=>}" )
           endif   

      case cType == "U"
           cResult = "nil"

      otherwise
           cResult = "type not supported yet in function ValToChar()"
   endcase

return cResult   

function ObjToChar( o )

   local hObj := {=>}, aDatas := __objGetMsgList( o, .T. )
   local hPairs := {=>}, aParents := __ClsGetAncestors( o:ClassH )

   AEval( aParents, { | h, n | aParents[ n ] := __ClassName( h ) } ) 

   hObj[ "CLASS" ] = o:ClassName()
   hObj[ "FROM" ]  = aParents 

   AEval( aDatas, { | cData | ObjSetData( o, cData, hPairs ) } )
   hObj[ "DATAs" ]   = hPairs
   hObj[ "METHODs" ] = __objGetMsgList( o, .F. )

return ValToChar( hObj )

function ObjSetData( o, cData, hPairs )

   TRY
      hPairs[ cData ] := __ObjSendMsg( o, cData )
   CATCH      
      hPairs[ cData ] := "** protected **"
   END
   
return nil 

#pragma BEGINDUMP

#include <hbapi.h>
#include <hbapierr.h>

HB_FUNC( HB_URLDECODE ) // Giancarlo's TIP_URLDECODE
{
   const char * pszData = hb_parc( 1 );

   if( pszData )
   {
      HB_ISIZ nLen = hb_parclen( 1 );

      if( nLen )
      {
         HB_ISIZ nPos = 0, nPosRet = 0;

         // maximum possible length
         char * pszRet = ( char * ) hb_xgrab( nLen );

         while( nPos < nLen )
         {
            char cElem = pszData[ nPos ];

            if( cElem == '%' && HB_ISXDIGIT( pszData[ nPos + 1 ] ) &&
                                HB_ISXDIGIT( pszData[ nPos + 2 ] ) )
            {
               cElem = pszData[ ++nPos ];
               pszRet[ nPosRet ]  = cElem - ( cElem >= 'a' ? 'a' - 10 :
                                            ( cElem >= 'A' ? 'A' - 10 : '0' ) );
               pszRet[ nPosRet ] <<= 4;
               cElem = pszData[ ++nPos ];
               pszRet[ nPosRet ] |= cElem - ( cElem >= 'a' ? 'a' - 10 :
                                            ( cElem >= 'A' ? 'A' - 10 : '0' ) );
            }
            else
               pszRet[ nPosRet ] = cElem == '+' ? ' ' : cElem;

            nPos++;
            nPosRet++;
         }

         // this function also adds a zero
         // hopefully reduce the size of pszRet
         hb_retclen_buffer( ( char * ) hb_xrealloc( pszRet, nPosRet + 1 ), nPosRet );
      }
      else
         hb_retc_null();
   }
   else
      hb_errRT_BASE( EG_ARG, 3012, NULL,
                     HB_ERR_FUNCNAME, 1, hb_paramError( 1 ) );
}

#pragma ENDDUMP