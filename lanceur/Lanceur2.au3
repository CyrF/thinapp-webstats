#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=pdl.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <InetConstants.au3>
#include <Crypt.au3>
#include <AutoItConstants.au3>

Opt("TrayIconHide", 1) ;0=show, 1=hide tray icon
Opt("TrayMenuMode", 1) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return
Global $SCRIPT_VERSION = "Détection d'une erreur ThinApp - Version 3"
$msg = ""

;Recherche le Dossier Data
$dir = _CheminDossierData()
If $dir == "" Then
	_msg( "Le chemin vers les packages n'a pas été trouvé." )
	Exit
EndIf

; --------------- recherche le chemin de l'appli a lancer ---------------
If FileExists( @ScriptDir & "\Data\" & @ScriptName ) Then
	$app = @ScriptDir & "\Data\" & @ScriptName
ElseIf FileExists( @ScriptDir & "\Data\" & baseFile( @ScriptName, False ) & ".zst" ) Then
	$app = @ScriptDir & "\Data\" & baseFile( @ScriptName, False ) & ".zst"
ElseIf FileExists( $dir & "\Data\" & @ScriptName ) Then
	$app = $dir & "\Data\" & @ScriptName
ElseIf FileExists( $dir & "\Data\" & baseFile( @ScriptName, False ) & ".zst" ) Then
	$app = $dir & "\Data\" & baseFile( @ScriptName, False ) & ".zst"
Else
	_msg( "L'application packagée " & @ScriptName & " n'a pas été trouvée." )
	Exit
EndIf

$appType = StringRight( StringUpper( $app ), 4 )

If $appType == ".EXE" Then
	; --------------- Execution d'un thinapp -------------
	$hTimer = TimerInit()
	; Lance l'appli : situé dans un sous-dossier data
	FileChangeDir( baseDir( $app ) )
	$pid = Run( $app & " " & $CmdLineRaw, @WorkingDir);

	if @error Then
		_msg( "L'application packagée " & $app & " n'a pas pu être lancée." )
		$msg = "_FAIL"
		Exit
	EndIf

	; Attends le lancement, et les eventuelles erreurs
	While ProcessExists( $pid )
		; une erreur de violation d'acces memoire = dll manquante ou bloquees par antivirus
		If WinExists( "Erreur d'application", "Exception EAccessViolation" ) Then
			ControlClick( "Erreur d'application", "Exception EAccessViolation", "[CLASS:Button; INSTANCE:1]" )
			ProcessKill( $pid )
			_msg( "Une erreur mémoire bloque l'execution de l'application." )
			$msg = "_EXCEPTION"
			ExitLoop
		EndIf

		; une erreur inattendue? = ancien paquet pas convertit
		If WinExists( "Sortie d’application irrécupérable", "ThinApp has encountered an unexpected error." ) Then
			ControlClick( "Sortie d’application irrécupérable", "ThinApp has encountered an unexpected error.", "[CLASS:Button; INSTANCE:1]" )
			ProcessKill( $pid )
			_msg( "Cette application n'est pas encore compatible avec windows 10." )
			$msg = "_RELINK"
			ExitLoop
		EndIf
		Sleep( 250 )
		ProcessExists( $pid )
	WEnd

	$diff = TimerDiff( $hTimer )
	If $diff < 5000 And $msg == "" Then
		If IniRead( $app & ".ini", "Lanceur", "NePasAfficherQuestionAppPlantee", "False" ) <> "True" Then
			$nbApp = ProcessList( @ScriptName )
			If $nbApp[0][0] < 2 Then
				$rep = MsgBox( 32+4, $SCRIPT_VERSION, "L'application semble avoir plantée..." & @crlf & "Est-ce le cas ?" )
				If $rep == 6 Then
					$msg = "_CRASH"
					If IniRead( $app & ".ini", "Lanceur", "NePasSupprimerAppdataThinapp", "False" ) <> "True" Then
						FileDelete( @AppDataDir & "\ThinApp\*.*" )
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
ElseIf $appType == ".ZST" Then
	; --------------- Execution d'une appli portable -------------
	$localdir = IniRead( $app & ".ini", "Lanceur", "CheminDExtraction", "C:\ProgramData\AppsPortable" )
	$localsubdir = IniRead( $app & ".ini", "Lanceur", "SousDossier", baseFile( $app, False ) )
	$localapp = IniRead( $app & ".ini", "Lanceur", "ProgrammeAExecuter", "start.bat" )

	If Not FileExists($localdir & "\" & $localsubdir & "\" & $localapp) Then
		extract( $app, $localdir )
	EndIf

	ConsoleWrite( $localdir & "\" & $localsubdir & "\" & $localapp & " " & $CmdLineRaw & @CRLF)

	FileChangeDir( $localdir & "\" & $localsubdir )
	$pid = Run( $localdir & "\" & $localsubdir & "\" & $localapp & " " & $CmdLineRaw, @WorkingDir )

	if @error Then
		_msg( "L'application compressée " & $app & " n'a pas pu être lancée." & @CRLF & $localdir & "\" & $localsubdir & "\" & $localapp )
		$msg = "_FAIL"
		Exit
	EndIf
Else
	; --------------- Execution d'autre chose (batch) -------------
	FileChangeDir( baseDir( $app ) )
	$pid = Run( $app & " " & $CmdLineRaw, @WorkingDir);

	if @error Then
		_msg( "L'application scriptée " & $app & " n'a pas pu être lancée." )
		$msg = "_FAIL"
		Exit
	EndIf
EndIf

_EnvoiServeurStatistique( $app, $msg )

; --------------- definition des fonctions -------------
Func _CheminDossierData()						; Cherche dans l'arboresence un dossier Data
	$dir = @ScriptDir
	While not FileExists( $dir & "\Data" )
		$dir = baseDir( $dir )
		If $dir == "" Then ExitLoop
	WEnd
	Return $dir
EndFunc

Func baseDir( $path )							; Renvoie le dossier parent d'un fichier
	If StringRight( $path, 1 ) == "\" Then
		$path = StringTrimRight( $path, 1 )
	EndIf
	Return StringLeft($path, StringInStr( $path, '\', 0, -1 ))
EndFunc

Func baseFile( $path, $avecExtension = True )							; Renvoie le nom du fichier sans le chemin
	$nomfichier = StringTrimLeft( $path, StringInStr( $path, '\', 0, -1 ))
	If $avecExtension Then
		Return $nomfichier
	Else
		Return StringLeft( $nomfichier, StringInStr( $nomfichier, '.', 0, -1 )-1 )
	EndIf
EndFunc

Func ProcessKill( $app )						; Ferme une application
	$base = baseFile( $app )
	ProcessClose( $base )
	ProcessClose( $base )
EndFunc

Func _msg( $msg )								; Affiche un message a l'utilisateur
	MsgBox( 64, $SCRIPT_VERSION, $msg, 15 )
EndFunc

Func _EnvoiServeurStatistique( $sApp, $msg )	; pour statistique hebergé sur srv-qoqcot
	_Crypt_Startup() ; To optimize performance start the crypt library.
	$sHash = _Crypt_HashData( @UserName, $CALG_MD5 ) ; Create a hash of the text entered.
    _Crypt_Shutdown() ; Shutdown the crypt library.
	$iRand = Random( 1, 99999, 1 )
	$sVars = "?App=" &  _URIEncode($sApp)  & $msg & "&Id=" & _URIEncode($sHash & "@" & @ComputerName);
	$sUrl = "http://10.144.36.73/thinapp/survey.php" & $sVars & "&nocache=" & $iRand;
   ; telecharge le pixel espion
   $hDownload = InetGet ( $sURL & "?" & $sVars, @TempDir & "\filename_" & $iRand , 1, 1 )
   ; attends le telechargement...
   Do
	  Sleep(50)
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
   FileDelete( @TempDir & "\filename_" & $iRand )
EndFunc
Func _URIEncode($sData)							; Formate une chaine pour etre transmise dans une url
    ; src: Prog@ndy
    Local $aData = StringSplit(BinaryToString(StringToBinary($sData,4),1),"")
    Local $nChar
    $sData=""
    For $i = 1 To $aData[0]
        $nChar = Asc($aData[$i])
        Switch $nChar
            Case 45, 46, 48 To 57, 65 To 90, 95, 97 To 122, 126
                $sData &= $aData[$i]
            Case 32
                $sData &= "+"
            Case Else
                $sData &= "%" & Hex($nChar,2)
        EndSwitch
    Next
    Return $sData
EndFunc

Func RandomizeData($m)							; Melange un tableau de valeur
    Local $c, $rx
    Dim $irow= UBound($m)
        for $loop5 = 1 to 5
			For $x = 0 To $irow - 1
                $c = $m[$x]                   ; swap
                $rx = Random (0,($irow -1),1)     ; Random x index
                $m[$x] = $m[$rx]         ; swap
                $m[$rx] = $c                 ; final swap
			Next
        next
    return $m
EndFunc

Func extract( $archive, $destination = "C:\ProgramData\AppsPortable\" )
	Local $msgstr =	IniRead( $archive & ".ini", "Lanceur", "RemplacerMessages", False)
	local $titre = IniRead( $archive & ".ini", "Lanceur", "TitreProgression", "First time, huh? Please wait")
	If not $msgstr then
		$msgstr = "locating the required gigapixels to render#" & _
        "spinning up the hamster#" & _
        "shovelling coal into the server#" & _
		"640K ought to be enough for anybody#" & _
		"measuring the cable length to fetch your data#" & _
		"we're unpacking your files as fast as we can#" & _
		"it looks like you're waiting for a app to load#" & _
		"and enjoy the elevator music#" & _
		"while the little elves carve your app to the disk#" & _
		"a few bits tried to escape, but we caught them#" & _
		"and dream of faster computers#" & _
		"time is an illusion. Loading time doubly so#" & _
		"checking the gravitational constant in your locale#" & _
		"go ahead -- hold your breath#" & _
		"at least you're not on hold#" & _
		"the server is powered by a lemon and two electrodes#" & _
		"we're testing your patience#" & _
		"as if you had any other choice#" & _
		"reticulating splines#" & _
		"warming up Large Hadron Collider#" & _
		"while the satellite moves into position#" & _
		"the bits are flowing slowly today#" & _
        "programming the flux capacitor"
	EndIf

	$msg = StringSplit($msgstr, "#", 2)
	$msg = RandomizeData($msg)
	$nbmsg = Random(0, UBound($msg) - 1, 1)

	ProgressOn( $titre, "" )
	$cmd = $dir & '\Data\7za.exe x -aos -bsp1 -bso0 "' & $archive & '" -o' & $destination & ''
	ConsoleWrite( $cmd & @CRLF)
	local $pid = run( $cmd, baseDir( $archive ), @SW_HIDE, $STDERR_MERGED )
	If $pid == 0 Then
		ProgressOff()
		_msg( "Erreur execution de décompression de l'archive " & @CRLF & _
			"ARCH= " & $archive & @CRLF & _
			"ERR= " & @error & "__" & @extended & @CRLF & _
			"CMD= " & $cmd & @CRLF  )
		$msg = "_FAIL"
		Exit
	EndIf

	While 1
		$out = StdoutRead( $pid )
		if $out <> "" then ConsoleWrite($out & @CRLF)
		if @error Then
			ExitLoop
		EndIf

		if $out <> "" and StringInStr($out, "% ") Then
			$percent = StringStripWS( $out, 1 )
			$percent = StringLeft( $percent, StringInStr($percent, "%") - 1 )
			if IniRead( $archive & ".ini", "Lanceur", "PasDeMessageProgression", False) Then
				ProgressSet( $percent )
			Else
				ProgressSet( $percent, $msg[round( $percent * $nbmsg / 100 )] )
			EndIf
			Sleep(20)
		EndIf
	WEnd
ProgressOff()
EndFunc