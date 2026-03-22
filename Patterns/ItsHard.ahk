#Warn All, Off

global GatherPath := [
	{key: FwdKey, dist: 3},
	{key: RightKey, dist: 1.5},
	{key: BackKey, dist: 6},
	{key: RightKey, dist: 1.5},
	{key: FwdKey, dist: 6},
	{key: RightKey, dist: 1.5},
	{key: BackKey, dist: 6},

	{key: LeftKey, dist: 1.5},
	{key: FwdKey, dist: 6},
	{key: LeftKey, dist: 1.5},
	{key: BackKey, dist: 6},
	{key: LeftKey, dist: 1.5},
	{key: FwdKey, dist: 6},

	{key: LeftKey, dist: 1.5},
	{key: BackKey, dist: 6},
	{key: LeftKey, dist: 1.5},
	{key: FwdKey, dist: 6},
	{key: LeftKey, dist: 1.5},
	{key: BackKey, dist: 6},

	{key: RightKey, dist: 1.5},
	{key: FwdKey, dist: 6},
	{key: RightKey, dist: 1.5},
	{key: BackKey, dist: 6},
	{key: RightKey, dist: 1.5},
	{key: FwdKey, dist: 3}
]

global comboEnded := false
global CameraRot := 0

dy_Walk(tiles, dir) {
	static comboDetect := 0
	send "{" dir " down}"
	current := DetectMovespeed() + 0.45
	lastCheck := A_TickCount
	while ((current += DetectMovespeed()) < tiles * 4) {
		if (A_TickCount - lastCheck > 75) {
			state := GetComboState(10)
			if ((state = 1) && ++comboDetect >= 2) {
				send "{" dir " up}"
				comboDetect := 0
				return true
			} else
				comboDetect := 0
			lastCheck := A_TickCount
		}
	}
	send "{" dir " up}"
	return false
}


interrupt := false
send "{" RotUp " 8}"
for path in GatherPath {
	if (interrupt := dy_Walk(path.dist, path.key)) {
		ComboEnded := false
		CameraRot := 0
		rotate(true)
		SetTimer(spam, 1)
		loop {
			gotoCoco()
			if (GetComboState(30) = 0)
				break
			if comboEnded
				break
		}
		SetTimer(spam, 0)

		Send "{" FwdKey " up}{" BackKey " up}{" LeftKey " up}{" RightKey " up}"
		if (CameraRot > 0)
			send "{" RotRight " " CameraRot "}"
		else if (CameraRot < 0)
			send "{" RotLeft " " Abs(CameraRot) "}"
		break
	}
}

BitmapVisible(bmName, var:=0) {
	Gdip_GetImageDimensions(bitmaps[bmName], &nWidth, &nHeight)
	Gdip_LockBits(bitmaps[bmName], 0, 0, nWidth, nHeight, &nStride, &nScan, &nBitmap)

	pBM := Gdip_BitmapFromScreen(windowX+windowWidth-400 "|" windowY+windowHeight-400 "|400|400")
	Gdip_GetImageDimensions(pBM, &hWidth, &hHeight)
	Gdip_LockBits(pBM, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmap)

	sx2 := hWidth  - nWidth
	sy2 := hHeight - nHeight
	found := (0 = Gdip_LockedBitsSearch(hStride, hScan, hWidth, hHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2, var))

	Gdip_UnlockBits(pBM, &hBitmap)
	Gdip_DisposeImage(pBM)
	Gdip_UnlockBits(bitmaps[bmName], &nBitmap)

	return found
}

/**
0 = missed
1 = dropped
2 = finished or in progress
-1 = nothing
 */
GetComboState(var := 30) {
	if BitmapVisible("combo-miss", 30)
		return 0

	Gdip_GetImageDimensions(bitmaps["combo"], &nWidth, &nHeight)
	Gdip_LockBits(bitmaps["combo"], 0, 0, nWidth, nHeight, &nStride, &nScan, &nBitmap)

	pBM := Gdip_BitmapFromScreen(windowX+windowWidth-400 "|" windowY+windowHeight-400 "|400|400")
	Gdip_GetImageDimensions(pBM, &hWidth, &hHeight)
	Gdip_LockBits(pBM, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmap)

	sx2 := hWidth - nWidth
	sy2 := hHeight - nHeight
	found1 := found2 := 0
	found1 := (0 = Gdip_LockedBitsSearch(hStride, hScan, hWidth, hHeight, nStride, nScan, nWidth, nHeight, &foundX1, &foundY1, 0, 0, sx2, sy2, var, 1))

	if (found1)
		found2 := (0 = Gdip_LockedBitsSearch(hStride, hScan, hWidth, hHeight, nStride, nScan, nWidth, nHeight, &foundX2, &foundY2, 0, 0, sx2, sy2, var, 4))

	Gdip_UnlockBits(pBM, &hBitmap)
	Gdip_DisposeImage(pBM)
	Gdip_UnlockBits(bitmaps["combo"], &nBitmap)

	if (found1)
		if (found2 && (foundX2 - foundX1 > 30) && Abs(foundY2 - foundY1) < 15)
			return 1
		else
			return 2
	return -1
}

locateCoco() {
	static init := false
	static coco := ""
	static lastPos := ""
	static nWidth, nHeight, nStride, nScan, nBitmap
	if (!init) {
		coco := Gdip_CreateBitmap(5, 5)
		G := Gdip_GraphicsFromImage(coco)
		Gdip_GraphicsClear(G, 0xFF99AAB5) ; health 0xFF1FE744, coco 0xFF99AAB5, balloon 0xFFBB1A34
		Gdip_DeleteGraphics(G)

		Gdip_GetImageDimensions(coco, &nWidth, &nHeight)
		Gdip_LockBits(coco, 0, 0, nWidth, nHeight, &nStride, &nScan, &nBitmap)
		init := true
	}
	if (lastPos) {
		scanW := Round(windowWidth * 0.2)
		scanH := Round(windowHeight * 0.2)
		screenX := (windowX + lastPos.x) - (scanW // 2)
		screenY := (windowY + lastPos.y) - (scanH // 2)

		scanX := (screenX < windowX) ? windowX : screenX
		scanY := (screenY < windowY) ? windowY : screenY

		pBM := Gdip_BitmapFromScreen(scanX "|" scanY "|" scanW "|" scanH)
		Gdip_GetImageDimensions(pBM, &hWidth, &hHeight)
		Gdip_LockBits(pBM, 0, 0, hWidth, hHeight, &hStride, &hScan, &hBitmap)
		sx2 := hWidth - nWidth
		sy2 := hHeight - nHeight
		if (0 = Gdip_LockedBitsSearch(hStride, hScan, hWidth, hHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2)) {
			Gdip_UnlockBits(pBM, &hBitmap)
			Gdip_DisposeImage(pBM)

			finalX := (scanX - windowX) + foundX
			finalY := (scanY - windowY) + foundY

			lastPos := {x: finalX, y: finalY}
			return {x: finalX, y: finalY}
		}
		Gdip_UnlockBits(pBM, &hBitmap)
		Gdip_DisposeImage(pBM)
	}

	pBMAll := Gdip_BitmapFromScreen(windowX "|" windowY "|" windowWidth "|" windowHeight)
	Gdip_GetImageDimensions(pBMAll, &aWidth, &aHeight)
	Gdip_LockBits(pBMAll, 0, 0, aWidth, aHeight, &aStride, &aScan, &aBitmap)
	sx2 := aWidth - nWidth
	sy2 := aHeight - nHeight
	if (0 = Gdip_LockedBitsSearch(aStride, aScan, aWidth, aHeight, nStride, nScan, nWidth, nHeight, &foundX, &foundY, 0, 0, sx2, sy2)) {
		Gdip_UnlockBits(pBMAll, &aBitmap)
		Gdip_DisposeImage(pBMAll)

		lastPos := {x: foundX + windowX, y: foundY + windowY}
		return {x: foundX + windowX, y: foundY + windowY}
	}
	lastPos := ""
	Gdip_UnlockBits(pBMAll, &aBitmap)
	Gdip_DisposeImage(pBMAll)
	return 0
}

gotoCoco() {
	start := A_TickCount
	pwm := 50
	GetRobloxClientPos()
	if !(pos := locateCoco()) {
		rotate()
		return
	}
	rotate(true)

	centerX := windowWidth // 2, centerY := windowHeight // 2
	deadX := windowWidth * 0.035, deadY := windowHeight * 0.035

	heldKeys := Map(FwdKey, 0, BackKey, 0, LeftKey, 0, RightKey, 0)
	miss := 0

	while (A_TickCount - start < 10000) {
		if !(pos := locateCoco()) {
			if (miss++ > 3)
				break
			continue
		}
		miss := 0

		vecX := pos.x - centerX
		vecY := pos.y - centerY

		if (Abs(vecX) < deadX && Abs(vecY) < deadY)
		break

		maxDist := Max(Abs(vecX), Abs(vecY))
		dutyX := Abs(vecX) / maxDist
		dutyY := Abs(vecY) / maxDist

		targetX := (vecX > 0) ? RightKey : LeftKey
		targetY := (vecY > 0) ? BackKey : FwdKey

		cycle := Mod(A_TickCount, pwm)

		shouldHoldX := (cycle < (pwm * dutyX)) && (Abs(vecX) > deadX)
		shouldHoldY := (cycle < (pwm * dutyY)) && (Abs(vecY) > deadY)

		for key, state in [[targetX, shouldHoldX], [targetY, shouldHoldY]] {
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
	Send "{" FwdKey " up}{" BackKey " up}{" LeftKey " up}{" RightKey " up}"
}

rotate(reset := false) {
	global comboEnded, CameraRot
	static startTime := 0
	static count := 0
	static last := 0
	timeLimit := 15000

	tick := A_TickCount

	if (reset) {
		last := tick + 275
		startTime := last 
		return
	}
	if (tick - startTime >= timeLimit) {
		comboEnded := true
		return
	}
	if (tick - last < 40)
		return
	last := tick
	if (Mod(count, 4) < 2) {
		send "{" RotLeft "}"
		CameraRot++
		compensate(1)
	} else {
		send "{" RotRight "}"
		CameraRot--
		compensate(-1)
	}
	count++
}

compensate(dir) {
	static cycle := []
	if (cycle.Length = 0) {
		cycle := [
			[FwdKey],
			[FwdKey, RightKey],
			[RightKey],
			[RightKey, BackKey],
			[BackKey],
			[BackKey, LeftKey],
			[LeftKey],
			[LeftKey, FwdKey]
		]
	}

	f := GetKeyState(FwdKey)
	b := GetKeyState(BackKey)
	l := GetKeyState(LeftKey)
	r := GetKeyState(RightKey)
	idx := (f && l ? 8 : f && r ? 2 : b && l ? 6 : b && r ? 4 : f ? 1 : b ? 5 : l ? 7 : r ? 3 : 0)
	
	if idx = 0
		return
		
	newIdx := idx + dir
	if newIdx > 8
		newIdx := 1
	else if newIdx < 1
		newIdx := 8
	old := cycle[idx]
	new := cycle[newIdx]
	for k in old {
		inNew := false
		for nk in new {
			if (k = nk) {
				inNew := true
				break
			}
		}
		if (!inNew) {
			send "{"  k " up}"
		}
	}
	for k in new {
		inOld := false
		for ok in old {
			if (k = ok) {
				inOld := true
				break
			}
		}
		if (!inOld)
			send "{"  k " down}"
	}
}

spam() {
	send "{" ZoomOut "}{" RotUp "}"
}
