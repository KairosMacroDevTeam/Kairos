class KeyAlignment {
	IsRunning := false
	IsActive := false
	IsRebinding := false
	IsActionRunning := false

	Width := 140
	Height := 30
	BrushBack := 0

	CurrentKey := "e"
	RebindHotkey := "^+k"

	__New() {
		this.CurrentKey := Config.Get("KeyAlignment", "AlignmentKey", "e")
		this.RebindHotkey := Config.Get("KeyAlignment", "RebindHotkey", "^+k")

		this.Gui := Gui("-Caption +E0x80000 +E0x20 +AlwaysOnTop +ToolWindow +OwnDialogs", "Key Alignment")
		win := WindowTracker.Get()
		if IsObject(win) && win.ok {
			xPos := win.x + win.w - this.Width
			yPos := win.y
		} else {
			xPos := A_ScreenWidth - this.Width
			yPos := 32
		}
		Config.Get("Main", "KeyAlignmentEnabled", 0) ? this.Gui.Show("NA x" xPos " y" yPos) : this.Gui.Hide()
		this.hbm := CreateDIBSection(this.Width, this.Height)
		this.hdc := CreateCompatibleDC()
		this.obm := SelectObject(this.hdc, this.hbm)
		this.G := Gdip_GraphicsFromHDC(this.hdc)
		Gdip_SetSmoothingMode(this.G, 4)
		this.InitBrushes()

		Scheduler.Add("KeyAlignment.FollowWindow", this.FollowWindow.Bind(this), 50)

		Hotkey(this.RebindHotkey, (*) => this.StartRebind(), "On")

		this.Draw()
	}

	FollowWindow(*) {
		try {
			win := WindowTracker.Get()
			if IsObject(win) && win.ok {
				targetX := win.x + win.w - this.Width
				targetY := win.y
				Config.Get("Main", "KeyAlignmentEnabled", 0) ? this.Gui.Show("NA x" targetX " y" targetY " w" this.Width " h" this.Height) : this.Gui.Hide()
			} else {
				this.Gui.Hide()
			}
		}
	}

	Toggle() {
		this.IsRunning ^= 1
		this.IsActive := this.IsRunning && Config.Get("Main", "KeyAlignmentEnabled", 0)
		if (this.IsActive) {
			this.Draw()
			this.RegisterActionHotkey(true)
		} else {
			this.Draw()
			this.RegisterActionHotkey(false)
		}
	}

	RegisterActionHotkey(ToggleState) {
		try {
			if (ToggleState)
				Hotkey("$" this.CurrentKey, (*) => this.PerformAction(), "On")
			else
				Hotkey("$" this.CurrentKey, "Off")
		}
	}

	PerformAction() {
		if (this.IsRebinding || this.IsActionRunning) {
			Hotkey("$" this.CurrentKey, "Off")
			return
		}

		IF (!this.IsRunning || State.IsPaused) {
			SetKeyDelay -1, 20
			SendEvent "{Blind}{" this.CurrentKey "}"
			Hotkey("$" this.CurrentKey, "On")
			return
		}

		this.IsActionRunning := true
		wasRightClick := GetKeyState("RButton", "P")

		if (wasRightClick)
			Click "Up Right"
		Send "{" RotRight "}"
		sleep 6
		Send "{" RotLeft "}"
		if (wasRightClick)
			Click "Down Right"
		this.IsActionRunning := false
	}

	StartRebind() {
		if this.IsRunning || this.IsRebinding
			return

		this.IsRebinding := true
		this.Draw("Rebinding...")
		this.RegisterActionHotkey(false)

		ih := InputHook("L1 T7", "{Escape}{Space}{Tab}{Enter}{Backspace}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{Up}{Down}{Left}{Right}")
		capturedKey := ""
		MouseCallback := (ThisHotkey) => (capturedKey := StrReplace(ThisHotkey, "$"), ih.Stop())
		mouseKeys := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
		for key in mouseKeys
			Hotkey("$" key, MouseCallback, "On")
		ih.Start()
		ih.Wait()

		for key in mouseKeys
			Hotkey("$" key, "Off")
		
		if (capturedKey != "")
			this.CurrentKey := capturedKey
		else if (ih.EndReason = "Max")
			this.CurrentKey := ih.Input
		else if (ih.EndReason = "EndKey")
			if (ih.EndKey != "Escape")
				this.CurrentKey := ih.EndKey

		Config.Set("KeyAlignment", "AlignmentKey", this.CurrentKey)
		Config.WriteIni()

		this.IsRebinding := false
		this.RegisterActionHotkey(true)
		this.Draw()
	}

	Draw(CustomText := "") {
		Gdip_GraphicsClear(this.G)

		cText := 0xFFFFFFFF
		cAccent := this.IsRebinding ? 0xFFFFA500 : this.IsRunning && !State.IsPaused ? 0xFF4CAF50 : 0xFFD32F2F

		Gdip_FillRoundedRectangle(this.G, this.BrushBack, 0, 0, this.Width, this.Height, 5)

		cInd := Gdip_BrushCreateSolid(cAccent)
		Gdip_FillRoundedRectangle(this.G, cInd, 5, 5, 5, 20, 2)
		Gdip_DeleteBrush(cInd)

		DisplayText := (CustomText != "" ? CustomText : "Align Key: " this.CurrentKey)
		Options := "x15 y6 w" (this.Width - 20) " h" this.Height " Left c" Format("{:08X}", cText) " s11 Bold"
		Gdip_TextToGraphics(this.G, DisplayText, Options, "Segoe UI")

		UpdateLayeredWindow(this.Gui.Hwnd, this.hdc, , , this.Width, this.Height)
	}

	RefreshConfig() {
		this.RegisterActionHotkey(false)
		try Hotkey(this.RebindHotkey, "Off")
		this.CurrentKey := Config.Get("KeyAlignment", "AlignmentKey", "e")
		this.RebindHotkey := Config.Get("KeyAlignment", "RebindHotkey", "^+k")
		try Hotkey(this.RebindHotkey, (*) => this.StartRebind(), "On")
		if (this.IsActive)
			this.RegisterActionHotkey(true)
		this.Draw()

	}

	Cleanup() {
		this.DisposeBrushes()
		Scheduler.Remove("KeyAlignment.FollowWindow")
		SelectObject(this.hdc, this.obm)
		DeleteObject(this.hbm)
		DeleteDC(this.hdc)
		Gdip_DeleteGraphics(this.G)
		this.Gui.Destroy()
	}

	InitBrushes() {
		if this.BrushBack
			return
		this.BrushBack := Gdip_BrushCreateSolid(0xb31E1E1E)
	}

	DisposeBrushes() {
		if this.BrushBack
			Gdip_DeleteBrush(this.BrushBack)
		this.BrushBack := 0
	}
}
