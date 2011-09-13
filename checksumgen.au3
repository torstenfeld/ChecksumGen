#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Comment=https://github.com/torstenfeld/ChecksumGen
#AutoIt3Wrapper_Res_Description=Tool provides md5 and sha1 hashes for a single file via explorer context menu
#AutoIt3Wrapper_Res_Fileversion=0.0.0.4
#AutoIt3Wrapper_Res_LegalCopyright=Copyright - Torsten Feld (feldstudie.net)
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Include <WinAPI.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <Crypt.au3>


Global $gDirTemp = @TempDir & "\checksumgen"
Global $gDbgFile = $gDirTemp & "\checksumgendbg.log"
Global $gFile = ""
Global $gResultText

If FileExists($gDbgFile) Then
	FileDelete($gDbgFile) ; cleaning old logfile
Else
	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)
EndIf

_CreateShellExHandler()

$gFile = _GetCommandLineParameters()
$gResultText = _GenerateChecksums($gFile)
_GuiOutput($gResultText)

Func _CreateShellExHandler()
	Local $lRegReturn
	Local $lRegKey = "HKEY_CLASSES_ROOT\*\shell\Show checksums\command"

	$lRegReturn = RegRead($lRegKey, "")
	If @error Then
		_WriteDebug("WARN;_CreateShellExHandler;ShellExtension not set - creating")
		RegWrite($lRegKey, "", "REG_SZ", @ScriptFullPath & ' "%1"')
		If @error Then _WriteDebug("ERR ;_CreateShellExHandler;Error setting ShellEx: " & @error)
	Else
		_WriteDebug("INFO;_CreateShellExHandler;ShellExtension set")
		If Not ($lRegReturn = @ScriptFullPath & " %1") Then
			_WriteDebug("WARN;_CreateShellExHandler;ShellExtension not set correctly - changing")
			RegWrite($lRegKey, "", "REG_SZ", @ScriptFullPath & ' "%1"')
			If @error Then _WriteDebug("ERR ;_CreateShellExHandler;Error setting ShellEx: " & @error)
		EndIf
	EndIf

EndFunc

Func _GenerateChecksums($lFile)

	Local $lMd2Sum, $lMd4Sum, $lMd5Sum, $lSha1Sum, $lReturnValue, $lSize, $lhFile, $lTimeStart, $lTimeDuration
	Local $lSizeRef = 10240000

	$lhFile = _WinAPI_CreateFile($lFile, 2, 2)
	$lSize = _WinAPI_GetFileSizeEx($lhFile)
	_WinAPI_CloseHandle($lhFile)

	If $lSize > $lSizeRef Then
		$lmessage = "Generating checksums" & @LF & "please wait..."
		SplashTextOn("ChecksumGen", $lmessage, 250, 100, -1, -1, 50)
	EndIf
	$lTimeStart = TimerInit()
	_Crypt_Startup()
	_WriteDebug("INFO;_GenerateChecksums;_Crypt_Startup initialized")

	$lMd2Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_MD2), 2)
	$lMd4Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_MD4), 2)
	$lMd5Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_MD5), 2)
	$lSha1Sum = StringTrimLeft(_Crypt_HashFile($lFile, $CALG_SHA1), 2)

	_Crypt_Shutdown()
	_WriteDebug("INFO;_EnumerateMd5Sums;_Crypt_Shutdown initialized")
	$lTimeDuration = TimerDiff($lTimeStart)
	If $lSize > $lSizeRef Then SplashOff()

	$lReturnValue = "File: " & @TAB & @TAB & $lFile & @CRLF & @CRLF & _
		"MD5: " & @TAB & @TAB & $lMd5Sum & @CRLF & _
		"SHA1: " & @TAB & @TAB & $lSha1Sum & @CRLF & @CRLF & _
		"Time needed: " & @TAB & StringFormat("%.2f", $lTimeDuration / 1000) & " seconds"

;~ 		"MD2: " & @TAB & @TAB & $lMd2Sum & @CRLF & _ ; commented as not often needed and takes too long
;~ 		"MD4: " & @TAB & @TAB & $lMd4Sum & @CRLF & _

	Return $lReturnValue

EndFunc

Func _GetCommandLineParameters() ; reading parameters

	If $CmdLine[0] <> "" Then

		_WriteDebug('INFO;_GetCommandLineParameters;Parameter "' & $CmdLine[1] & '" found')
		Return $CmdLine[1]
	Else
		_WriteDebug('INFO;_GetCommandLineParameters;No Parameter found')
		MsgBox(16,"ChecksumGen - Error","No parameter was given",10)
		Exit 1
	EndIf
EndFunc   ;==>_GetCommandLineParameters

Func _GetFileForChecksum()
	Local $lFile

	$lFile = FileOpenDialog("ChecksumGen - Open File", @ScriptDir, "File (*.*)")
	Return $lFile

EndFunc

Func _GuiOutput($lText)

	#Region ### START Koda GUI section ### Form=
	$Form_Output = GUICreate("ChecksumGen", 470, 241, 192, 124)
	$Edit_Output = GUICtrlCreateEdit("", 8, 8, 449, 193, $ES_READONLY)
	GUICtrlSetData(-1, $lText)
	$Button_Close = GUICtrlCreateButton("Close", 165, 208, 139, 25, BitOR($BS_DEFPUSHBUTTON,$WS_GROUP))
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $Button_Close
				Exit
		EndSwitch
	WEnd

EndFunc

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

	For $i = 1 To $lArrayTemp[0]
		If $i > 1 Then $lResult = $lResult & @CRLF
		$lResult = $lResult & $lArray[$i] & $lArrayTemp[$i]
	Next

	FileWriteLine($gDbgFile, @MDAY & @MON & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lArrayTemp[1] & " - " & $lArrayTemp[2] & " - " & $lArrayTemp[3])
	If @error Then MsgBox(16, "ChecksumGen - Error", "Error in FileWriteLine: " & @error)
EndFunc   ;==>_WriteDebug