#Warn All, Off

locateCoco() {
	KeyWait "LButton"
	MouseGetPos &mouseX, &mouseY
	ToolTip mouseX "," mouseY, mouseX, mouseY
	gotoCoords(mouseX, mouseY)
}

gotoCoords(x, y) {
	GetRobloxClientPos()
	sleep 2000
	; EVERYTHING IS RELATIVE TO ROBLOX WINDOW
	centerX := windowWidth // 2
	centerY := windowHeight // 2
	vecX := x - centerX
	vecY := y - centerY

	deadX := windowWidth * 0.035
	deadY := windowHeight * 0.035
	if (Abs(vecX) < deadX && Abs(vecY) < deadY) {
		return
	}

	baseHeight := 1440
	basePPS := 16
	
	tiltFactor := 0.19
	maxStretchX := 0.31
	yOffsetPercent := vecY / (windowHeight / 2)

	localPPS := basePPS * (1 + (yOffsetPercent * tiltFactor))

	edgePercentX := Abs(vecX) / (windowWidth / 2)
	stretchedMultiplierX := 1 + (edgePercentX * maxStretchX)

	studsX := Abs(vecX) / (localPPS * stretchedMultiplierX)
	studsY := Abs(vecY) / localPPS


	targetX := (vecX > 0) ? RightKey : LeftKey
	targetY := (vecY > 0) ? BackKey : FwdKey

	if (Abs(vecY) > deadY) {
		send "{" targetY " down}"
		move(studsY / 4)
		send "{" targetY " up}"
	}
	if (Abs(vecX) > deadX) {
		send "{" targetX " down}"
		move(studsX / 4)
		send "{" targetX " up}"
	}
	sleep 5000
}

spam() {
	send "{" ZoomOut "}{" RotUp "}"
}
SetTimer(spam, 1)

loop
	locateCoco()
