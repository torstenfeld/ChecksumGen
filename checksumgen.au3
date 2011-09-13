

#Include <Crypt.au3>


Global $gDirTemp = @TempDir & "\checksumgen"
Global $gDbgFile = $gDirTemp & "\checksumgendbg.log"


MsgBox(0, "ChecksumGen", _GenerateChecksums(_GetFileForChecksum()))

Func _GetFileForChecksum()
	Local $lFile

	$lFile = FileOpenDialog("ChecksumGen - Open File", @ScriptDir, "File (*.*)")
	Return $lFile

EndFunc

Func _GenerateChecksums($lFile)

	Local $lMd2Sum, $lMd4Sum, $lMd5Sum, $lSha1Sum, $lReturnValue

	_Crypt_Startup()
	_WriteDebug("INFO;_GenerateChecksums;_Crypt_Startup initialized")

	$lMd2Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_MD2), 2)
	$lMd4Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_MD4), 2)
	$lMd5Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_MD5), 2)
	$lSha1Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_SHA1), 2)

	_Crypt_Shutdown()
	_WriteDebug("INFO;_EnumerateMd5Sums;_Crypt_Shutdown initialized")

	$lReturnValue = "MD2: " & @TAB & $lMd2Sum & @CRLF & _
		"MD4: " & @TAB & $lMd4Sum & @CRLF & _
		"MD5: " & @TAB & $lMd5Sum & @CRLF & _
		"SHA1: " & @TAB & $lSha1Sum

	Return $lReturnValue

EndFunc



Func _Array2DAdd(ByRef $avArray, $sValue = '')
;~ 	Return 			Succes -1
;~ 	Failure			0 and set @error
;~ 	@error = 1		given array is not array
;~ 	@error = 2		given parts of Element too less/much

	If (Not IsArray($avArray)) Then
		SetError(1)
		Return 0
	EndIf
	Local $UBound2nd = UBound($avArray, 2)
	If @error = 2 Then
		ReDim $avArray[UBound($avArray) + 1]
		$avArray[UBound($avArray) - 1] = $sValue
	Else
		Local $arValue
		ReDim $avArray[UBound($avArray) + 1][$UBound2nd]
		If $sValue = '' Then
			For $i = 0 To $UBound2nd - 2
				$sValue &= '|'
			Next
		EndIf
		$arValue = StringSplit($sValue, '|')
		If $arValue[0] <> $UBound2nd Then
			SetError(2)
			Return 0
		EndIf
		For $i = 0 To $UBound2nd - 1
			$avArray[UBound($avArray) - 1][$i] = $arValue[$i + 1]
		Next
	EndIf
	Return -1
EndFunc   ;==>_Array2DAdd


Func _WriteDebug($lParam) ; $lType, $lFunc, $lString) ; creates debuglog for analyzing problems
	Local $lArray[4]
	Local $lResult

;~ 	$lArray[0] bleibt leer
;~ 	$lArray[1] = "Type: "
;~ 	$lArray[2] = "Func: "
;~ 	$lArray[3] = "Desc: "

	Local $lArrayTemp = StringSplit($lParam, ";")
	If @error Then
		Dim $lArrayTemp[4]
;~ 		$lArrayTemp[0] bleibt leer
		$lArrayTemp[1] = "ERR "
		$lArrayTemp[2] = "_WriteDebug"
		$lArrayTemp[3] = "StringSplit failed"
	EndIf

;~ 	if (Not $gAdvDebug) and ($lArrayTemp[1] = "INFO") Then
;~ 		SetError(1)
;~ 		Return -1
;~ 	EndIf

	For $i = 1 To $lArrayTemp[0]
		If $i > 1 Then $lResult = $lResult & @CRLF
		$lResult = $lResult & $lArray[$i] & $lArrayTemp[$i]
	Next

	FileWriteLine($gDbgFile, @MDAY & @MON & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lArrayTemp[1] & " - " & $lArrayTemp[2] & " - " & $lArrayTemp[3])
;~ 	FileWriteLine($gDbgFile, @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lType & " - " & $lFunc & " - " & $lString)
EndFunc   ;==>_WriteDebug