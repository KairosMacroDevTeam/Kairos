RunPath(movement, name := "", vars := "") {
	DetectHiddenWindows true
	if WinExist("ahk_pid " State.currentWalk.pid " ahk_class AutoHotkey")
		EndPath()
	script :=
		(
			'
	#SingleInstance Off
	#NoTrayIcon
	ProcessSetPriority("AboveNormal")
	KeyHistory 0
	ListLines 0
	OnExit(ExitFunc)

	#Include "%A_ScriptDir%\Lib\"
	#Include "Gdip_All.ahk"
	#Include "Gdip_ImageSearch.ahk"
	#Include "Roblox.ahk"
	#Include "Scheduler.ahk"
	#Include "Utility.ahk"
	#Include "Move.ahk"
	#Include "JSON.ahk"

	movespeed := ' Alt.Movespeed '
	both			:= (Mod(movespeed*1000, 1265) = 0) || (Mod(Round((movespeed+0.005)*1000), 1265) = 0)
	HastyGuards	 := (both || Mod(movespeed*1000, 1100) < 0.00001)
	GiftedHasty	:= (both || Mod(movespeed*1000, 1150) < 0.00001)
	BaseMovespeed  := round(movespeed / (both ? 1.265 : (HastyGuards ? 1.1 : (GiftedHasty ? 1.15 : 1))), 0)

	(bitmaps := Map()).CaseSense := false
	pToken := Gdip_Startup()
	#Include "%A_ScriptDir%\Assets\Bitmaps\"
	#Include "Offset.ahk"
	#Include "Movement.ahk"
	#Include "General.ahk"
	#Include "Sprinkler.ahk"

	offsetY := ' State.offsetY '
	' KeyVars() '
	' vars '
	index := 0
	start()
	return

	F13::
		start(hk?) {
			global index
			index++
			Send "{F14 down}"
			' movement '
			Send "{F14 up}"
		}
	
	F16:: {
		static keyStates := Map(LeftKey, false, RightKey, false, FwdKey, false, BackKey, false, "LButton", false, "RButton", false, SC_E, false)
		if A_IsPaused
			for k, v in keyStates
				if (v = true) 
					send "{" k " down}"
		else {
			for k, v in keyStates {
				keyStates[k] := GetKeyState(k)
				send "{" k " up}"
			}
		}
		Pause -1
	}
	ExitFunc(*) {
		Send "{' LeftKey ' up}{' RightKey ' up}{' FwdKey ' up}{' BackKey ' up}{' SC_Space ' up}{F14 up}{' SC_E ' up}"
		try Gdip_Shutdown(pToken)
	}
	'
		)
	shell := ComObject("WScript.Shell")
	exec := shell.Exec('"' exe_path64 '" /script /force *')
	exec.StdIn.Write(script), exec.StdIn.Close()
	if WinWait("ahk_class AutoHotkey ahk_pid " exec.ProcessID, , 2) {
		DetectHiddenWindows false
		State.currentWalk := { pid: exec.ProcessID, name: name }
		return true
	} else {
		DetectHiddenWindows false
		return false
	}
}

walk(dist, dir1, dir2?) {
	return
	(
		'Send "{' dir1 ' down}' (IsSet(dir2) ? '{' dir2 ' down}"' : '"') '
		move(' dist ')
		Send "{' dir1 ' up}' (IsSet(dir2) ? '{' dir2 ' up}"' : '"')
	)
}

KeyVars() {
	return
	(
		'
	FwdKey:="' FwdKey '"
	LeftKey:="' LeftKey '"
	BackKey:="' BackKey '"
	RightKey:="' RightKey '"
	RotLeft:="' RotLeft '"
	RotRight:="' RotRight '"
	RotUp:="' RotUp '"
	RotDown:="' RotDown '"
	ZoomIn:="' ZoomIn '"
	ZoomOut:="' ZoomOut '"
	SC_E:="' SC_E '"
	SC_R:="' SC_R '"
	SC_L:="' SC_L '"
	SC_Esc:="' SC_Esc '"
	SC_Enter:="' SC_Enter '"
	SC_LShift:="' SC_LShift '"
	SC_Space:="' SC_Space '"
	SC_1:="' SC_1 '"
	TCFBKey:="' TCFBKey '"
	AFCFBKey:="' AFCFBKey '"
	TCLRKey:="' TCLRKey '"
	AFCLRKey:="' AFCLRKey '"
	'
	)
}

PathVars() {
	return
	(
		'
	HiveSlot := ' Alt.HiveSlot '
	AltNumber := ' Alt.AltNumber '
	IsClaimed := ' Alt.ClaimHiveEnabled '
	CoordMode "Mouse", "Screen"
	CoordMode "Pixel", "Screen"

	gotoRamp() {
		if (IsClaimed) {
			walk(5, FwdKey)
			walk(9.2*HiveSlot-4, RightKey)
		} else {
			walk(30, FwdKey, RightKey)
			walk(5, RightKey)
		}
	}

	gotoCannon() {
		static pBMCannon := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAABsAAAAMAQMAAACpyVQ1AAAABlBMVEUAAAD3//lCqWtQAAAAAXRSTlMAQObYZgAAAEdJREFUeAEBPADD/wDAAGBgAMAAYGAA/gBgYAD+AGBgAMAAYGAAwABgYADAAGBgAMAAYGAAwABgYADAAGBgAMAAYGAAwABgYDdgEn1l8cC/AAAAAElFTkSuQmCC")

		hwnd := GetRobloxHWND()
		GetRobloxClientPos(hwnd)
		SendEvent "{Click " windowX+350 " " windowY+offsetY+100 " 0}"

		success := 0
		Loop 10
		{
			Send "{" SC_Space " down}{" RightKey " down}"
			Sleep 100
			Send "{" SC_Space " up}"
			walk(2, RightKey)
			walk(1.5, FwdKey, RightKey)
			Send "{" RightKey " down}"

			DllCall("GetSystemTimeAsFileTime","int64p",&s:=0)
			n := s, f := s+100000000
			while (n < f)
			{
				pBMScreen := Gdip_BitmapFromScreen(windowX+windowWidth//2-200 "|" windowY+offsetY "|400|125")
				if (Gdip_ImageSearch(pBMScreen, pBMCannon, , , , , , 2, , 2) = 1)
				{
					success := 1, Gdip_DisposeImage(pBMScreen)
					break
				}
				Gdip_DisposeImage(pBMScreen)
				DllCall("GetSystemTimeAsFileTime","int64p",&n)
			}
			Send "{" RightKey " up}"

			if (success = 1) ; check that cannon was not overrun, at the expense of a small delay
			{
				Loop 10
				{
					if (A_Index = 10)
					{
						success := 0
						break
					}
					Sleep 500
					pBMScreen := Gdip_BitmapFromScreen(windowX+windowWidth//2-200 "|" windowY+offsetY "|400|125")
					if (Gdip_ImageSearch(pBMScreen, pBMCannon, , , , , , 2, , 2) = 1)
					{
						Gdip_DisposeImage(pBMScreen)
						break 2
					}
					else
						walk(1.5, LeftKey)
					Gdip_DisposeImage(pBMScreen)
				}
			}

			if (success = 0)
			{
				Reset()
				gotoRamp()
			}
		}
		if (success = 0)
			ExitApp
	}

	Reset()
	{
		static hivedown := 0
		static pBMR := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAACgAAAAGCAAAAACUM4P3AAAAAnRSTlMAAHaTzTgAAAAXdEVYdFNvZnR3YXJlAFBob3RvRGVtb24gOS4wzRzYMQAAAyZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0n77u/JyBpZD0nVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkJz8+Cjx4OnhtcG1ldGEgeG1sbnM6eD0nYWRvYmU6bnM6bWV0YS8nIHg6eG1wdGs9J0ltYWdlOjpFeGlmVG9vbCAxMi40NCc+CjxyZGY6UkRGIHhtbG5zOnJkZj0naHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyc+CgogPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9JycKICB4bWxuczpleGlmPSdodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyc+CiAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjQwPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICA8ZXhpZjpQaXhlbFlEaW1lbnNpb24+NjwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiA8L3JkZjpEZXNjcmlwdGlvbj4KCiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0nJwogIHhtbG5zOnRpZmY9J2h0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvJz4KICA8dGlmZjpJbWFnZUxlbmd0aD42PC90aWZmOkltYWdlTGVuZ3RoPgogIDx0aWZmOkltYWdlV2lkdGg+NDA8L3RpZmY6SW1hZ2VXaWR0aD4KICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgPHRpZmY6WFJlc29sdXRpb24+OTYvMTwvdGlmZjpYUmVzb2x1dGlvbj4KICA8dGlmZjpZUmVzb2x1dGlvbj45Ni8xPC90aWZmOllSZXNvbHV0aW9uPgogPC9yZGY6RGVzY3JpcHRpb24+CjwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9J3InPz77yGiWAAAAI0lEQVR42mNUYyAOMDJggOUMDAyRmAqXMxAHmBiobjWxngEAj7gC+wwAe1AAAAAASUVORK5CYII=")

		(bitmaps:=Map()).CaseSense := 0
		#include "%A_ScriptDir%\Assets\Bitmaps\Reset.ahk"

		success := 0
		hwnd := GetRobloxHWND()
		GetRobloxClientPos(hwnd)
		SendEvent "{Click " windowX+350 " " windowY+offsetY+100 " 0}"

		Loop 10
		{
			ActivateRoblox()
			GetRobloxClientPos(hwnd)
			PrevKeyDelay := A_KeyDelay
			SetKeyDelay 250
			SendEvent "{" SC_Esc "}{" SC_R "}{" SC_Enter "}"
			SetKeyDelay PrevKeyDelay

			n := 0
			while ((n < 2) && (A_Index <= 80))
			{
				Sleep 100
				pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY "|" windowWidth "|50")
				n += (Gdip_ImageSearch(pBMScreen, pBMR, , , , , , 10) = (n = 0))
				Gdip_DisposeImage(pBMScreen)
			}
			Sleep 1000

			if hivedown
				Send "{" RotDown "}"
			region := windowX "|" windowY+3*windowHeight//4 "|" windowWidth "|" windowHeight//4
			sconf := windowWidth**2//3200
			Loop 4 {
				sleep 250
				pBMScreen := Gdip_BitmapFromScreen(region), s := 0
				for i, k in bitmaps["hive"] {
					s := Max(s, Gdip_ImageSearch(pBMScreen, k, , , , , , 4, , , sconf))
					if (s >= sconf) {						
						Gdip_DisposeImage(pBMScreen)
						success := 1
						Send "{" RotRight " 4}"
						if hivedown
							Send "{" RotUp "}"
						SendEvent "{" ZoomOut " 5}"
						break 3
					}
				}
				Gdip_DisposeImage(pBMScreen)
				Send "{" RotRight " 4}"
				if (A_Index = 2)
				{
					if hivedown := !hivedown
						Send "{" RotDown "}"
					else
						Send "{" RotUp "}"
				}
			}
		}
		for k,v in bitmaps["hive"]
			Gdip_DisposeImage(v)
		if (success = 0)
			ExitApp
	}
	'
	)
}

PatternVars(field := "Stump") { ; stump default b/c it's smallest
	return
	(
		'
	nm_CameraRotation(Dir, count) {
		Static LR := 0, UD := 0, init := OnExit((*) => send("{" Rot%(LR > 0 ? "Left" : "Right")% " " Mod(Abs(LR), 8) "}{" Rot%(UD > 0 ? "Up" : "Down")% " " Abs(UD) "}"), -1)
		send "{" Rot%Dir% " " count "}"
		Switch Dir,0 {
			Case "Left": LR -= count
			Case "Right": LR += count
						Case "Up": UD -= count
						Case "Down": UD += count
		}
	}
	field := "' field '"
	fieldWidth := ' State.fieldSize[field].width '
	fieldHeight := ' State.fieldSize[field].height '
	altNumber := ' Alt.AltNumber '
	size := ' Alt.PatternSize '
	reps := ' Alt.PatternWidth '
	'
	)
}

EndPath() {
	DetectHiddenWindows true
	try WinClose "ahk_class AutoHotkey ahk_pid " State.currentWalk.pid
	State.currentWalk := { pid: "", name: "" }
	DetectHiddenWindows false
}

fieldDriftCompensation() {
	GetRobloxClientPos()
	centerX := windowWidth // 2
	centerY := windowHeight // 2

	deadX := windowWidth * 0.035
	deadY := windowHeight * 0.035

	pwm := 50
	heldKeys := Map(FwdKey, 0, BackKey, 0, LeftKey, 0, RightKey, 0)
	miss := 0
	start := A_TickCount

	while (A_TickCount - start < 5000) {
		if (LocateSprinkler(&x, &y) = 0) {
			if (miss++ > 3)
				break
			continue
		}
		miss := 0

		vecX := x - centerX
		vecY := y - centerY
		if (Abs(vecX) < deadX && Abs(vecY) < deadY)
			break

		maxDist := Max(Abs(vecX), Abs(vecY))
		if (maxDist = 0)
			maxDist := 1
		dutyX := Abs(vecX) / maxDist
		dutyY := Abs(vecY) / maxDist

		targetX := (vecX > 0) ? RightKey : LeftKey
		targetY := (vecY > 0) ? BackKey : FwdKey

		cycle := Mod(A_TickCount, pwm)
		shouldHoldX := (cycle < (pwm * dutyX)) && (Abs(vecX) > deadX)
		shouldHoldY := (cycle < (pwm * dutyY)) && (Abs(vecY) > deadY)

		for index, state in [[targetX, shouldHoldX], [targetY, shouldHoldY]] {
			if (state[2] && !heldKeys[state[1]]) {
				send "{" state[1] " down}"
				heldKeys[state[1]] := true
			} else if (!state[2] && heldKeys[state[1]]) {
				send "{" state[1] " up}"
				heldKeys[state[1]] := false
			}
		}

		for k, v in heldKeys {
			if (v && k != targetX && k != targetY) {
				send "{" k " up}"
				heldKeys[k] := false
			}
		}
	}
	for k, v in heldKeys {
		if (v) {
			send "{" k " up}"
			heldKeys[k] := false
		}
	}
}

LocateSprinkler(&X:="", &Y:="") {
	static init := false
	static SprinklerData := []
	static lastPos := ""

	hwnd := GetRobloxHWND()
	GetRobloxClientPos(hwnd)

	if (!init) {
		for i, k in State.SprinklerImages {
			Gdip_GetImageDimensions(bitmaps[k], &nWidth, &nHeight)
			Gdip_LockBits(bitmaps[k], 0, 0, nWidth, nHeight, &nStride, &nScan, &nBitmapData)
			nWidth := NumGet(nBitmapData, 0, "UInt")
			nHeight := NumGet(nBitmapData, 4, "UInt")
			SprinklerData.Push({width: nWidth, height: nHeight, stride: nStride, scan: nScan, name: k})
		}
		init := true
	}
	found := false
	name := ""
	finalX := 0
	finalY := 0
	v := 50

	if (lastPos) {
		scanW := Round(windowWidth * 0.2)
		scanH := Round(windowHeight * 0.2)
		screenX := (windowX + lastPos.x) - (scanW // 2)
		screenY := (windowY + lastPos.y) - (scanH // 2)

		scanX := (screenX < windowX) ? windowX : screenX
		scanY := (screenY < windowY) ? windowY : screenY

		pBM := Gdip_BitmapFromScreen(scanX "|" scanY "|" scanW "|" scanH)
		Gdip_GetImageDimensions(pBM, &lWidth, &lHeight)
		Gdip_LockBits(pBM, 0, 0, lWidth, lHeight, &lStride, &lScan, &lBitmapData)

		for img in SprinklerData {
			sx2 := lWidth - img.width
			sy2 := lHeight - img.height
			if (sx2 > 0 && sy2 > 0 && Gdip_MultiLockedBitsSearch(lStride, lScan, lWidth, lHeight, img.Stride, img.Scan, img.Width, img.Height, &pos, 0, 0, sx2, sy2, v, 1, 1) > 0) {
				finalX := (screenX - windowX) + SubStr(pos, 1, InStr(pos, ",") - 1)
				finalY := (screenY - (windowY + State.offsetY + 75)) + SubStr(pos, InStr(pos, ",") + 1)
				found := true
				name := img.name
				break
			}
		}
		Gdip_UnlockBits(pBM, &lBitmapData)
		Gdip_DisposeImage(pBM)
	}

	if (!found) {
		hWidth := windowWidth
		hHeight := windowHeight - State.offsetY - 75
		pBMScreen := Gdip_BitmapFromScreen(windowX "|" (windowY + State.offsetY + 75) "|" hWidth "|" hHeight)
		
		Gdip_LockBits(pBMScreen, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmapData)
		for img in SprinklerData {
			sx2 := hWidth - img.width
			sy2 := hHeight - img.height
			if (sx2 > 0 && sy2 > 0 && Gdip_MultiLockedBitsSearch(hStride, hScan, hWidth, hHeight, img.Stride, img.Scan, img.Width, img.Height, &pos, 0, 0, sx2, sy2, v, 1, 1) > 0) {
				finalX := SubStr(pos, 1, InStr(pos, ",") - 1)
				finalY := SubStr(pos, InStr(pos, ",") + 1)
				found := true
				name := img.name
				break
			}
		}
		Gdip_UnlockBits(pBMScreen, &hBitmapData)
		Gdip_DisposeImage(pBMScreen)
	}
	if (found) {
		X := finalX, Y := finalY + 75
		lastPos := {x: X, y: Y}
		return 1
	}
	else {
		X := "", Y := ""
		return 0
	}
}
