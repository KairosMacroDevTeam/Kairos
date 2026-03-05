Padding := 8

AlignWidth := (FieldWidth / 2) - Padding
AlignHeight := (FieldHeight / 2) - Padding

if (index = 1) {
	Switch AltNumber {
		Case 0: ; Center
			sleep 50
		Case 1: ; Top Left
			walk(AlignHeight, FwdKey)
			walk(AlignWidth, LeftKey)
		Case 2: ; Top Right
			walk(AlignHeight, FwdKey)
			walk(AlignWidth, RightKey)
		Case 3: ; Bottom Right
			walk(AlignHeight, BackKey)
			walk(AlignWidth, RightKey)
		Case 4: ; Bottom Left
			walk(AlignHeight, BackKey)
			walk(AlignWidth, LeftKey)
      ; default is just center
	}
	send "{" RotUp " 8}"
	loop 5
		send "{" ZoomIn "}"
	Sleep 100
}

sleep 10000
