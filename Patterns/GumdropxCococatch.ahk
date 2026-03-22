#Warn All, Off
; ============================================================
; GumdropxCococatch Pattern
; Warning-free version for Natro / nm loader
; ============================================================

; ============================================================
; BITMAP PLACEHOLDERS
; ============================================================
; Assign your converted bitmap pointers here
global Trigger1Bmp := 0
global Trigger2Bmp := 0

; ============================================================
; SETTINGS
; ============================================================
Padding := 8
AlignWidth := (FieldWidth / 2) - Padding
AlignHeight := (FieldHeight / 2) - Padding

MicroStep := 2
MicroHold := 10
CheckEvery := 50

; ============================================================
; GATHER PATTERN
; ============================================================
MoveBalanced(step, hold, f, b, l, r) {
	walk(step, l)
	Sleep hold

	walk(step, f)
	Sleep hold

	walk(step, r)
	Sleep hold

	walk(step, b)
	Sleep hold

	walk(step, r)
	Sleep hold

	walk(step, f)
	Sleep hold

	walk(step, l)
	Sleep hold

	walk(step, b)
	Sleep hold
}

ReleaseMoveKeys() {
	Send "{" FwdKey " up}{" BackKey " up}{" LeftKey " up}{" RightKey " up}"
}

ApplyCameraSetup() {
	Send "{" RotUp " 8}"
	Loop 5
		Send "{" ZoomIn "}"
	Sleep 100
}

; ============================================================
; CASE MOVEMENT
; ============================================================

GoToCase(alt) {
	Switch alt {
		Case 0:
			Sleep 50
		Case 1:
			walk(AlignHeight, FwdKey)
			walk(AlignWidth, LeftKey)
			Send "{" RotRight " 3}"
		Case 2:
			walk(AlignHeight, FwdKey)
			walk(AlignWidth, RightKey)
			Send "{" RotLeft " 3}"
		Case 3:
			walk(AlignHeight, BackKey)
			walk(AlignWidth, RightKey)
			Send "{" RotLeft " 1}"
		Case 4:
			walk(AlignHeight, BackKey)
			walk(AlignWidth, LeftKey)
			Send "{" RotRight " 1}"
	}
}

ReturnToCenterFromCase(alt) {
	Switch alt {
		Case 0:
			Sleep 50
		Case 1:
			Send "{" RotLeft " 3}"
			walk(AlignWidth, RightKey)
			walk(AlignHeight, BackKey)
		Case 2:
			Send "{" RotRight " 3}"
			walk(AlignWidth, LeftKey)
			walk(AlignHeight, BackKey)
		Case 3:
			Send "{" RotRight " 1}"
			walk(AlignWidth, LeftKey)
			walk(AlignHeight, FwdKey)
		Case 4:
			Send "{" RotLeft " 1}"
			walk(AlignWidth, RightKey)
			walk(AlignHeight, FwdKey)
	}
}

; ============================================================
; BITMAP TEMPLATE SYSTEM
; ============================================================

InitTemplate(bmp) {
	local w, h, stride, scan, bitmap
	Gdip_GetImageDimensions(bmp, &w, &h)
	Gdip_LockBits(bmp, 0, 0, w, h, &stride, &scan, &bitmap)
	return { w: w, h: h, stride: stride, scan: scan }
}

FindTemplate(tpl) {
	local pBM, sw, sh, sStride, sScan, sBitmap
	local sx2, sy2, fx, fy, found
	pBM := Gdip_BitmapFromScreen(windowX "|" windowY "|" windowWidth "|" windowHeight)
	Gdip_GetImageDimensions(pBM, &sw, &sh)
	Gdip_LockBits(pBM, 0, 0, sw, sh, &sStride, &sScan, &sBitmap)
	sx2 := sw - tpl.w
	sy2 := sh - tpl.h
	found := false
	if (sx2 >= 0 && sy2 >= 0)
		found := (0 = Gdip_LockedBitsSearch(
			sStride, sScan, sw, sh,
			tpl.stride, tpl.scan,
			tpl.w, tpl.h,
			&fx, &fy,
			0, 0, sx2, sy2))
	Gdip_UnlockBits(pBM, &sBitmap)
	Gdip_DisposeImage(pBM)
	return found
}

locateTrigger1() {
	static tpl := 0
	if !tpl
		tpl := InitTemplate(Trigger1Bmp)
	return FindTemplate(tpl)
}

locateTrigger2() {
	static tpl := 0
	if !tpl
		tpl := InitTemplate(Trigger2Bmp)
	return FindTemplate(tpl)
}

; ============================================================
; COCO ROUTINE
; ============================================================

gotoCoco() {
	local start, centerX, centerY
	local deadX, deadY
	local heldX, heldY
	local vecX, vecY
	local targetX, targetY
	local miss, pos
	start := A_TickCount
	GetRobloxClientPos()
	if !(pos := locateCoco()) {
		rotate()
		return false
	}
	rotate(true)
	centerX := windowWidth // 2
	
	deadX := windowWidth * 0.035
	deadY := windowHeight * 0.035
	heldX := ""
	heldY := ""
	miss := 0
	while (A_TickCount - start < 10000) {
		if !(pos := locateCoco()) {
			if (++miss > 3)
				break
			continue
		}
		miss := 0
		vecX := pos.x - centerX
		vecY := pos.y - centerY
		targetX := ""
		targetY := ""
		if (Abs(vecX) > deadX)
			targetX := (vecX > 0) ? RightKey : LeftKey
		if (Abs(vecY) > deadY)
			targetY := (vecY > 0) ? BackKey : FwdKey
		if (heldX != targetX) {
			if heldX
				Send "{" heldX " up}"
			if targetX
				Send "{" targetX " down}"
			heldX := targetX
		}
		if (heldY != targetY) {
			if heldY
				Send "{" heldY " up}"
			if targetY
				Send "{" targetY " down}"
			heldY := targetY
		}
		if (!heldX && !heldY)
			break
	}
	ReleaseMoveKeys()
	return true
}

rotate(reset := false) {
	static step := 0
	static count := 0
	static last := 0
	local limit := 160
	if reset {
		last := A_TickCount + 275
		step := 0
		return
	}
	if step >= limit
		return
	if (A_TickCount - last < 40)
		return
	last := A_TickCount
	step++
	if (Mod(count, 4) < 2)
		Send "{" RotLeft "}"
	else
		Send "{" RotRight "}"
	count++
}

; ============================================================
; CAMERA STABILIZER
; ============================================================
spam() {
	Send "{" ZoomOut "}{" RotUp "}"
}
SetTimer(spam, 1)

; ============================================================
; MAIN LOOP
; ============================================================
if (index = 1) {
	GoToCase(AltNumber)
	ApplyCameraSetup()
}

lastCheck := 0
inCoco := false

while true {
	MoveBalanced(MicroStep, MicroHold, FwdKey, BackKey, LeftKey, RightKey)
	if (A_TickCount - lastCheck < CheckEvery)
		continue
	lastCheck := A_TickCount
	GetRobloxClientPos()
	if (!inCoco && locateTrigger1()) {
		inCoco := true
		ReleaseMoveKeys()
		ReturnToCenterFromCase(AltNumber)
		lastSeenCoco := A_TickCount
		loop {
			GetRobloxClientPos()
			if locateTrigger2()
				break
			if gotoCoco()
				lastSeenCoco := A_TickCount
			if (A_TickCount - lastSeenCoco > 10000)
				break
			Sleep 10
		}
		ReleaseMoveKeys()
		GoToCase(AltNumber)
		ApplyCameraSetup()
		inCoco := false
	}
}
