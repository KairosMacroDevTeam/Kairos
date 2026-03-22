class MainGui {
	Selectors := Map()
	Gui := unset
	FeatureList := ["Alt Macro", "Tracker", "Warns", "Boost Bar", "Stat Monitor", "Key Alignment", "Magnifier"]
	FwdDown := false
	BackDown := false
	LeftDown := false
	RightDown := false
	ran := 0
	ListeningKeybind := ""

	__New() {
		width := 500
		height := 300

		tabWidth := width
		tabHeight := height

		footerY := height - 23
		footerButtonHeight := 22

		tabInnerWidth := tabWidth - 20
		
		panelX := tabWidth + 5
		panelWidth := width - panelX - 5

		this.Gui := Gui((Config.Get("Main", "AlwaysOnTop", 0) ? "+AlwaysOnTop " : "") " +Border +OwnDialogs", "Kairos")
		this.Gui.Show("x" Config.Get("Main", "GuiX", A_ScreenWidth // 2 - 200) " y" Config.Get("Main", "GuiY", A_ScreenHeight // 2 - 100) " w" width " h" height)
		this.FeatureRefreshers := Map(
			"BoostBarEnabled", () => (IsSet(Boost) && Boost) ? Boost.RefreshConfig() : 0,
			"WarnsEnabled", () => (IsSet(Warns) && Warns) ? Warns.RefreshConfig() : 0,
			"TrackerEnabled", () => (IsSet(Track) && Track) ? Track.RefreshConfig() : 0
		)

		; General UI
		this.Gui.OnEvent("Close", (*) => ExitApp())
		this.Gui.SetFont("s9 cDefault Norm")
		
		ver := "v" version
		(GuiCtrl := this.Gui.Add("Text", "x" width - 5 " y" footerY + 3 " w90 -Wrap +BackgroundTrans", ver))
		GuiCtrl.Move(width - 5 - this.TextExtend(ver, GuiCtrl))

		this.Gui.Add("Button", "x5 y" footerY " w67 h" footerButtonHeight " -Wrap vStartButton", "Start (" Config.Get("Main", "StartHotkey", "F1") ")").OnEvent("Click", this.start.Bind(this))
		this.Gui.Add("Button", "x75 y" footerY " w67 h" footerButtonHeight " -Wrap vPauseButton", "Pause (" Config.Get("Main", "PauseHotkey", "F2") ")").OnEvent("Click", this.pause.Bind(this))
		this.Gui.Add("Button", "x145 y" footerY " w67 h" footerButtonHeight " -Wrap vStopButton", "Stop (" Config.Get("Main", "StopHotkey", "F3") ")").OnEvent("Click", this.stop.Bind(this))


		accountType := Config.Get("Main", "AccountType", "Main")
		accountList := ["Main", "Alt"]
		this.Gui.Add("Text", "x215 y" footerY+5 " -Wrap", "Account Type:")
		this.Gui.Add("DropDownList", "x290 y" footerY+1 " w67 -Wrap vMain_AccountType Choose" ObjIndexOf(accountList, accountType), ["Main", "Alt"]).OnEvent("Change", this.SaveConfig.Bind(this))

		; presets/profiles for settings
		if (accountType = "Main")
			TabArr := ["Home", "Tracker", "Warnings", "Boost Bar", "Communicator", "Settings"]
		else
			TabArr := ["Home", "Alt", "Boost Bar", "Communicator", "Settings"]
		; TODO - Finish "Guide" for Alts
		(TabCtrl := this.Gui.Add("Tab", "x-1 y-1 w" tabWidth+2 " h" footerY " -Wrap " (Config.Get("Main", "DarkMode", 1) ? "cFFFFFF" : "C000000"), TabArr)).OnEvent("Change", (*) => TabCtrl.Focus())
		SendMessage 0x1331, 0, 20, , TabCtrl

		; --- Main Tab ---
		TabCtrl.UseTab("Home")
		this.Gui.SetFont("w700")

		this.Gui.Add("GroupBox", "x10 y25 w190 h115 -Wrap", "")
		this.Gui.Add("Text", "x20 y24 h20 -Wrap", "Profile Manager")
		this.Gui.SetFont("s10 cDefault Norm")

		this.Gui.Add("Text", "x20 y45 w50", "Presets:")
		presets := Config.GetPresets()
		this.Gui.Add("DropDownList", "x70 y42 w120 vPresetDDL Choose" ObjIndexOf(presets, Config.currentPreset), presets)

		this.Gui.Add("Button", "x20 y75 w50 h22", "Load").OnEvent("Click", this.LoadPreset.Bind(this))
		this.Gui.Add("Button", "x75 y75 w50 h22", "Save").OnEvent("Click", this.SavePreset.Bind(this))
		this.Gui.Add("Button", "x130 y75 w50 h22", "New").OnEvent("Click", this.NewPreset.Bind(this))
		this.Gui.Add("Button", "x20 y105 w160 h22", "Delete").OnEvent("Click", this.DeletePreset.Bind(this))

		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x210 y25 w130 h" 20 + ((Config.Get("Main", "AccountType", "Main") = "Main" ? 6 : 2) * 20) " -Wrap vFeaturesGroup", "")
		this.Gui.Add("Text", "x220 y24 h20 -Wrap", "Enable Features")
		this.Gui.SetFont("s10 cDefault Norm")

		this.FeatureControls := Map()
		for i in this.FeatureList {
			name := StrReplace(i, " ", "") "Enabled"
			isEnabled := Config.Get("Main", name, 0)

			chk := this.Gui.Add("CheckBox", "x215 y" 40 + (20 * (A_Index - 1)) " w20 h20 -Wrap vMain_" name " Checked" isEnabled, "")
			chk.Section := "Main"
			chk.OnEvent("Click", this.ToggleFeature.Bind(this))
			txt := this.Gui.Add("Text", "x235 y" 43 + (20 * (A_Index - 1)) " w90 h20 -Wrap", i)
			this.FeatureControls[i] := {chk: chk, txt: txt, name: name}
		}
		; --- Warnings Tab ---
		if (accountType = "Main") {
			; actual name (in settings) - display name
			WarnItems := [
				["Precise", "Precision"]
				, ["Smoothie", "Super Smoothie"]
				, ["Gummy", "Gummy Star"]
				, ["Pop", "Pop Star"]
				, ["Scorch", "Scorching Star"]
				, ["Shower", "Star Shower"]
				, ["Morph", "Gummy Morph"]
				, ["Baller", "Gummyballer"]
				, ["Combo", "Coconut Combo"]
			]

			TabCtrl.UseTab("Warnings")
			this.Gui.SetFont("w700")
			this.Gui.Add("GroupBox", "x10 y25 w" (tabInnerWidth - 120) " h" 35 + (WarnItems.Length * 21) " -Wrap", "")
			this.Gui.Add("Text", "x20 y27 -Wrap", "Warning Settings")
			this.Gui.SetFont("s10 cDefault Norm")

			this.Gui.Add("Text", "x45 y40 w80", "Active")
			this.Gui.Add("Text", "x135 y40 w60", "Threshold")
			this.Gui.Add("Text", "x225 y40 w70", "Audio/Misc")

			yPos := 57
			for item in WarnItems {
				key := item[1]
				name := item[2]

				unit := (name ~= "Precision|Smoothie" ? "s" : "x")
				maxVal := Warns.WarnProfiles.Has(name) ? Warns.WarnProfiles[name].max . unit : "??"

				this.Gui.Add("CheckBox", "x20 y" yPos " w20 h20 vWarns_" key "_Enabled Checked" Config.Get("Warns", key "_Enabled", 0)).OnEvent("Click", this.SaveConfig.Bind(this))
				this.Gui.Add("Text", "x40 y" yPos + 3, name)

				this.Gui.Add("Edit", "x140 y" yPos " w50 h20 Number vWarns_" key "_Threshold", Config.Get("Warns", key "_Threshold", 25)).OnEvent("Change", this.SaveConfig.Bind(this))

				this.Gui.SetFont("cGray s7")
				this.Gui.Add("Text", "x192 y" yPos + 3 " w35", "/" maxVal)
				this.Gui.SetFont("s10 cDefault Norm")

				btn := this.Gui.Add("Button", "x230 y" yPos " w60 h22", "Settings")
				btn.OnEvent("Click", this.OpenWarnSettings.Bind(this, key, name))
				yPos += 21
			}
		}
		; --- Boost Bar Tab ---
		TabCtrl.UseTab("Boost Bar")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x5 y25 w70 h165 -Wrap", "")
		this.Gui.Add("GroupBox", "x75 y25 w70 h165 -Wrap", "")
		this.Gui.Add("GroupBox", "x145 y25 w85 h165 -Wrap", "")
		this.Gui.Add("Text", "x20 y25", "Active")
		this.Gui.Add("Text", "x87 y25", "Timers")
		this.Gui.Add("Text", "x165 y25", "Modes")
		this.Gui.SetFont("s10 cDefault Norm")

		loop 7 {
			yPos := 45 + ((A_Index - 1) * 20)
			i := A_Index

			this.Gui.Add("Text", "x10 y" yPos " w36 h20 -Wrap", "Slot " i ":")
			this.Gui.Add("CheckBox", "x50 y" yPos - 2 " w20 h20 vBoostBar_SlotActive" i " Checked" Config.Get("BoostBar", "SlotActive" i, 0)).OnEvent("Click", this.SaveConfig.Bind(this))
			this.Gui.Add("Edit", "x85 y" yPos - 3 " w50 h20 Number vBoostBar_SlotTimer" i, Config.Get("BoostBar", "SlotTimer" i, 100)).OnEvent("Change", this.SaveConfig.Bind(this))

			currentModes := Config.Get("BoostBar", "SlotMode" i, "Timer")
			display := currentModes = "" ? "None" : (StrSplit(currentModes, "|").Length > 1 ? "Multiple" : currentModes)

			btn := this.Gui.Add("Button", "x150 y" yPos - 3 " w70 h21 vBoostBar_Config" i, display)
			btn.OnEvent("Click", this.OpenModeSelector.Bind(this, i, btn))
		}

		this.Gui.Add("Text", "x" tabWidth - 110 " y30", "Show when active")
		this.Gui.Add("CheckBox", "x" tabWidth - 130 " y28 w20 h20 vBoostBar_ShowWhenActive Checked" Config.Get("BoostBar", "ShowWhenActive", 1)).OnEvent("Click", this.SaveConfig.Bind(this))

		; --- Alt Tab ---
		if (accountType = "Alt") {
			TabCtrl.UseTab("Alt")
			this.Gui.SetFont("w700")
			GroupWidth := (tabInnerWidth // 2) - 5
			this.Gui.Add("GroupBox", "x10 y25 w" GroupWidth " h190")
			this.Gui.Add("Text", "x20 y27", "Alt Settings")
			this.Gui.SetFont("s10 cDefault Norm")
			this.Gui.SetFont("s10 w400")

			this.Gui.Add("Text", "x20 y48", "MoveSpeed:")
			this.Gui.Add("Edit", "x105 y42 w60 h20 vAlt_Movespeed", Config.Get("Alt", "Movespeed", 29)).OnEvent("Change", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x20 y70", "Hive Slot:")
			this.Gui.Add("Edit", "x105 y68 w60 h20 vAlt_HiveSlot", Config.Get("Alt", "HiveSlot", 1)).OnEvent("Change", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x20 y95", "Alt Number:")
			this.Gui.Add("Edit", "x105 y92 w40 h20 Number vAlt_AltNumber", Config.Get("Alt", "AltNumber", 1)).OnEvent("Change", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x40 y120", "Shift Lock")
			this.Gui.Add("CheckBox", "x20 y117 w20 h20 vAlt_ShiftLock Checked" Config.Get("Alt", "ShiftLock", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x130 y120", "Drift Comp")
			this.Gui.Add("CheckBox", "x110 y117 w20 h20 vAlt_FieldDriftComp Checked" Config.Get("Alt", "FieldDriftComp", 1)).OnEvent("Click", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x40 y143", "Claim Hive")
			this.Gui.Add("CheckBox", "x20 y140 w20 h20 vAlt_ClaimHive Checked" Config.Get("Alt", "ClaimHive", 1)).OnEvent("Click", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x130 y143", "Ignore Inactive")
			this.Gui.Add("CheckBox", "x110 y140 w20 h20 vAlt_IgnoreInactiveHoney Checked" Config.Get("Alt", "IgnoreInactiveHoney", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x40 y165", "Use Tool")
			this.Gui.Add("CheckBox", "x20 y162 w20 h20 vAlt_UseTool Checked" Config.Get("Alt", "UseTool", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x20 y185", "Priv Server:")
			this.Gui.Add("Edit", "x95 y183 w110 h20 vAlt_PrivServer", Config.Get("Alt", "PrivServer", "")).OnEvent("Change", this.SaveConfig.Bind(this))


			Group2 := GroupWidth + 15
			this.Gui.SetFont("w700")
			this.Gui.Add("GroupBox", "x" Group2 " y25 w" GroupWidth " h190")
			this.Gui.Add("Text", "x" Group2 + 10 " y27", "Field Settings")

			this.Gui.SetFont("s10 w400")
			this.Gui.Add("Button", "x" Group2 + 110 " y27 w50 h18", "Copy").OnEvent("Click", this.CopyFieldSettings.Bind(this))
			this.Gui.Add("Button", "x" Group2 + 160 " y27 w50 h18", "Paste").OnEvent("Click", this.PasteFieldSettings.Bind(this))

			this.Gui.SetFont("s10 cDefault Norm")

			this.Gui.Add("Text", "x" Group2 + 5 " y50", "Field:")
			fieldArr := ["sunflower", "dandelion", "mushroom", "blueflower", "clover", "strawberry", "spider", "bamboo", "pineapple", "stump", "cactus", "pumpkin", "pinetree", "rose", "mountaintop", "pepper", "coconut"]
			(GuiCtrl := this.Gui.Add("DropDownList", "x" Group2 + 45 " y48 w100 vAlt_DefaultField Choose" ObjIndexOf(fieldArr, Config.Get("Alt", "DefaultField", "pepper")), fieldArr)).OnEvent("Change", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x" Group2 + 5 " y75", "Pattern:")
			this.Gui.Add("DropDownList", "x" Group2 + 60 " y75 w110 vAlt_Pattern Choose" ObjIndexOf(patternList, Config.Get("Alt", "Pattern", "GeneralBooster")), patternList).OnEvent("Change", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x" Group2 + 5 " y105", "Size:")
			this.Gui.Add("Edit", "x" Group2 + 40 " y103 w40 h20 Number vAlt_PatternSize", Config.Get("Alt", "PatternSize"))
			this.Gui.Add("UpDown", "Range1-10", Config.Get("Alt", "PatternSize"))

			this.Gui.Add("Text", "x" Group2 + 90 " y105", "Width:")
			this.Gui.Add("Edit", "x" Group2 + 130 " y103 w40 h20 Number vAlt_PatternWidth", Config.Get("Alt", "PatternWidth"))
			this.Gui.Add("UpDown", "Range1-10", Config.Get("Alt", "PatternWidth"))

			this.Gui.Add("Text", "x" Group2 + 5 " y130", "Sprinkler:")
			sprinklerArr := ["Center", "Upper Left", "Left", "Lower Left", "Lower", "Lower Right", "Right", "Upper Right", "Upper"]
			this.Gui.Add("DropDownList", "x" Group2 + 65 " y125 w80 vAlt_SprinklerLocation Choose" ObjIndexOf(sprinklerArr, Config.Get("Alt", "SprinklerLocation", "Center")), sprinklerArr).OnEvent("Change", this.SaveConfig.Bind(this))
			this.Gui.Add("Edit", "x" Group2 + 147 " y125 w40 h24 Number vAlt_SprinklerDistance", Config.Get("Alt", "SprinklerDistance", 1)).OnEvent("Change", this.SaveConfig.Bind(this))
			this.Gui.Add("UpDown", "Range0-10", Config.Get("Alt", "SprinklerDistance", 1))

			this.Gui.Add("Text", "x" Group2 + 5 " y155", "Rotation:")
			this.Gui.Add("Edit", "x" Group2 + 60 " y153 w40 Number vAlt_RotationAmount", Config.Get("Alt", "RotationAmount", 0)).OnEvent("Change", this.SaveConfig.Bind(this))
			this.Gui.Add("UpDown", "Range0-8", Config.Get("Alt", "RotationAmount", 0))
			this.Gui.Add("DropDownList", "x" Group2 + 102 " y153 w60 vAlt_RotationDirection Choose" ObjIndexOf(["Right", "Left"], Config.Get("Alt", "RotationDirection", "Right")), ["Right", "Left"]).OnEvent("Change", this.SaveConfig.Bind(this))

			; --- Guide Tab ---
			TabCtrl.UseTab("Guide")
			this.Gui.SetFont("w700")
			this.Gui.Add("GroupBox", "x10 y20 w380 h170")
			this.Gui.Add("Text", "x20 y27", "Guiding Star Cycle")
			this.Gui.SetFont("s10 cDefault Norm")

			this.Gui.Add("Text", "x20 y48", "Enable:")
			this.Gui.Add("CheckBox", "x70 y47 w20 h20 vGuide_Enabled Checked" Config.Get("Guide", "Enabled", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x20 y75", "Target Field:")
			fieldMap := Map("pepper", 1, "spider", 2, "rose", 3, "pinetree", 4, "bff", 5, "bamboo", 6)
			cur := StrLower(StrReplace(Config.Get("Guide", "Field", "pepper"), " ", ""))
			a := ObjIndexOf(fieldArr, cur)
			idx := a ? a : 1
			ddl := this.Gui.Add("DropDownList", "x100 y72 w120 vGuide_Field Choose" idx, fieldArr)
			ddl.OnEvent("Change", this.SaveConfig.Bind(this))

			this.Gui.Add("Text", "x20 y105", "Private Server Link:")
			this.Gui.Add("Edit", "x20 y125 w350 h20 vGuide_PrivLink", Config.Get("Guide", "PrivLink", "")).OnEvent("Change", this.SaveConfig.Bind(this))
		}

		; --- Communicator Tab ---
		TabCtrl.UseTab("Communicator")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y25 w" TabInnerWidth " h110")
		role := Config.Get("Main", "AltMacroEnabled", 0) ? "Client" : "Server"
		this.Gui.Add("Text", "x20 y27 vCommsStatus", "Connection Settings - Status: " role " ")
		this.Gui.SetFont("s10 cDefault Norm")

		this.Gui.Add("Text", "x45 y45", "Enable Communication")
		this.Gui.Add("CheckBox", "x25 y42 w20 h20 vCommunicator_CommunicationEnabled Checked" Config.Get("Communicator", "CommunicationEnabled", 0)).OnEvent("Click", this.SaveConfig.Bind(this))

		this.Gui.Add("Text", "x25 y67", "Channel Name:")
		(GuiCtrl := this.Gui.Add("Edit", "x120 y65 w180 h20 vCommunicator_DweetName", Config.Get("Communicator", "DweetName", "you might wanna change this..."))).OnEvent("Change", this.SaveConfig.Bind(this))
		this.Gui.Add("Button", "x120 y90 w60 h20", "Copy").OnEvent("Click", (*) => A_Clipboard := this.Gui["Communicator_DweetName"].Value)
		this.Gui.Add("Button", "x180 y90 w60 h20", "Paste").OnEvent("Click", this.PasteUser.Bind(this))
		this.Gui.Add("Button", "x240 y90 w65 h20", "Generate").OnEvent("Click", this.GenerateUser.Bind(this))

		this.Gui.Add("Text", "x22 y110 w460", "For communication, both macros must have the EXACT same 'Channel' name.")

		; --- Tracker Tab ---
		if (accountType = "Main") {
			TabCtrl.UseTab("Tracker")
			TrackerItems := [
				["precise", "Precision"]
				, ["supersmoothie", "Super Smoothie"]
				, ["combo", "Coconut Combo"]
				, ["scorch", "Scorch"]
				, ["x-flame", "X-Flame"]
				, ["gummystar", "Gummy Star"]
				, ["gummymorph", "Gummy Morph"]
				, ["gummyballer", "Gummy Baller"]
				, ["popstar", "Pop Star"]
			]
			this.Gui.SetFont("w700")
			this.Gui.Add("GroupBox", "x10 y25 w140 h" 25 + (TrackerItems.Length * 20))
			this.Gui.Add("Text", "x20 y27", "Tracker Settings")
			this.Gui.SetFont("s10 cDefault Norm")

			passives := Config.Get("Tracker", "Passives", "Scorch")
			has := (str) => InStr("|" passives "|", "|" str "|")

			yPos := 45
			for item in TrackerItems {
				key := item[1]
				name := item[2]

				varName := StrReplace(key, "-", "")
				this.Gui.Add("CheckBox", "x25 y" yPos " w20 h20 vTracker_" varName " Checked" has(key)).OnEvent("Click", this.UpdatePassives.Bind(this))
				this.Gui.Add("Text", "x45 y" yPos + 3, name)
				yPos := yPos + 20
			}
		}

		; --- Settings Tab ---
		TabCtrl.UseTab("Settings")
		this.Gui.SetFont("w700")
		this.Gui.Add("GroupBox", "x10 y25 w230 h165")
		this.Gui.Add("Text", "x20 y27", "Keybind Settings")
		this.Gui.SetFont("s10 cDefault Norm")
		col := Config.Get("Main", "DarkMode", 1) ? "cFFB347" : "c0055A4"

		this.Gui.Add("Text", "x20 y53 w90", "Start Macro :")
		dispStart := this.Gui.Add("Text", "x110 y53 w60 " col, Config.Get("Main", "StartHotkey", "F1"))
		btnStart := this.Gui.Add("Button", "x170 y49 w60", "Rebind")
		btnStart.OnEvent("Click", this.CaptureHotkey.Bind(this, "Main", "StartHotkey", dispStart))

		this.Gui.Add("Text", "x20 y80 w90", "Pause Macro :")
		dispPause := this.Gui.Add("Text", "x110 y80 w60 " col, Config.Get("Main", "PauseHotkey", "F2"))
		btnPause := this.Gui.Add("Button", "x170 y76 w60", "Rebind")
		btnPause.OnEvent("Click", this.CaptureHotkey.Bind(this, "Main", "PauseHotkey", dispPause))

		this.Gui.Add("Text", "x20 y107 w90", "Stop Macro :")
		dispStop := this.Gui.Add("Text", "x110 y107 w60 " col, Config.Get("Main", "StopHotkey", "F3"))
		btnStop := this.Gui.Add("Button", "x170 y103 w60", "Rebind")
		btnStop.OnEvent("Click", this.CaptureHotkey.Bind(this, "Main", "StopHotkey", dispStop))

		this.Gui.Add("Text", "x20 y134 w90", "Align Key :")
		dispAlign := this.Gui.Add("Text", "x110 y134 w60 " col, Config.Get("KeyAlignment", "AlignmentKey", "e"))
		btnAlign := this.Gui.Add("Button", "x170 y130 w60", "Rebind")
		btnAlign.OnEvent("Click", this.CaptureHotkey.Bind(this, "KeyAlignment", "AlignmentKey", dispAlign))

		this.Gui.Add("Text", "x20 y161 w90", "Rebind Align :")
		dispRebind := this.Gui.Add("Text", "x110 y161 w60 " col, Config.Get("KeyAlignment", "RebindHotkey", "^+k"))
		btnRebind := this.Gui.Add("Button", "x170 y157 w60", "Rebind")
		btnRebind.OnEvent("Click", this.CaptureHotkey.Bind(this, "KeyAlignment", "RebindHotkey", dispRebind))

		; --- Dark Mode & Other Stuff ---
		this.UpdateUI()
		SetWindowTheme(this.Gui, Config.Get("Main", "DarkMode", 1))
		SetWindowAttribute(this.Gui, Config.Get("Main", "DarkMode", 1))
		this.RegisterHotkeys()

		; --- OnExit ---
		;OnExit((*) => (IsSet(Stats) && Stats) ? Stats.Export() : 0)
	}

	; --- Functions ---
	GenerateUser(GuiCtrl, *) {
		name := "K" Random(10000000, 99999999) "X" Random(10000000, 99999999)
		this.Gui["Communicator_DweetName"].Value := name
		Config.Set("Communicator", "DweetName", name)
		Config.WriteIni()
		if IsSet(Comms)
			Comms.UpdateSettings()
	}

	PasteUser(GuiCtrl, *) {
		try {
			data := Trim(A_Clipboard)
			if (data = "") {
				ToolTip("Clipboard is empty.")
				SetTimer(ToolTip, -500)
				return
			}
			this.Gui["Communicator_DweetName"].Value := data
			Config.Set("Communicator", "DweetName", data)
			Config.WriteIni()

			if IsSet(Comms)
				Comms.UpdateSettings()
		} catch {
			ToolTip("Error Pasting.")
			SetTimer(ToolTip, -500)
		}
	}
	
	CaptureHotkey(Section, KeyName, DisplayCtrl, GuiCtrl, *) {
		originalText := DisplayCtrl.Value
		DisplayCtrl.Value := "Listening..."
		GuiCtrl.Enabled := false

		ih := InputHook("L1 T7", "{Escape}{Space}{Tab}{Enter}{Backspace}{Delete}{Insert}{Home}{End}{PgUp}{PgDn}{Up}{Down}{Left}{Right}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}")

		capturedKey := ""
		MouseCallback := (ThisHotkey) => (capturedKey := StrReplace(ThisHotkey, "$"), ih.Stop())
		mouseKeys := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
		for key in mouseKeys
			Hotkey("$" key, MouseCallback, "On")

		ih.Start()
		ih.Wait()

		for key in mouseKeys
			Hotkey("$" key, "Off")
		GuiCtrl.Enabled := true
		
		finalKey := ""
		if (capturedKey != "")
			finalKey := capturedKey
		else if (ih.EndReason = "Max")
			finalKey := ih.Input
		else if (ih.EndReason = "EndKey")
			if (ih.EndKey != "Escape")
				finalKey := ih.EndKey

		if (finalKey != "") {
			if (KeyName ~= "StartHotkey|PauseHotkey|StopHotkey") {
				blacklist := "|LButton|RButton|Enter|Space|Tab|Backspace|Escape|"
				if InStr(blacklist, "|" finalKey "|") {
					MsgBox("You cannot bind '" finalKey "' to this option.", "Invalid Keybind", 48 " T10")
					finalKey := ""
				}
			}
		}
		if (finalKey = "") {
			DisplayCtrl.Value := originalText
		} else {
			DisplayCtrl.Value := finalKey
			Config.Set(Section, KeyName, finalKey)
			Config.WriteIni()
			if (Section = "KeyAlignment" && IsSet(Aligner) && Aligner)
				Aligner.RefreshConfig()

			if (KeyName ~= "StartHotkey|PauseHotkey|StopHotkey") {
				try Hotkey(originalText, "Off")
				this.RegisterHotkeys()
				if (KeyName = "StartHotkey")
					this.Gui["StartButton"].Text := "Start (" finalKey ")"
				else if (KeyName = "PauseButton")
					this.Gui["PauseButton"].Text := "PauseButton (" finalKey ")"
				else if (KeyName = "StopHotkey")
					this.Gui["StopHotkey"].Text := "Stop (" finalKey ")"
			}
		}
	}

	OpenModeSelector(index, GuiCtrl*) {
		static ModeGui := ""
		GuiClose(*) {
			if (IsSet(ModeGui) && IsObject(ModeGui))
				try ModeGui.Destroy(), ModeGui := ""
		}
		GuiClose()
		currentConfig := Config.Get("BoostBar", "SlotMode" index, "Timer")

		ModeGui := Gui("+Owner" this.Gui.Hwnd " +AlwaysOnTop +Border +ToolWindow", "Slot " index)
		ModeGui.SetFont("s10 cDefault Norm", "Bahnschrift")
		ModeGui.OnEvent("Close", (*) => GuiClose)

		UpdateConfig(*) {
			savedList := []
			for mode, ctrl in CheckBoxes {
				if (ctrl.Value)
					savedList.Push(mode)
			}

			saveString := ""
			for item in savedList
				saveString .= (A_Index > 1 ? "|" : "") item
			Config.Set("BoostBar", "SlotMode" index, saveString)
			Config.WriteIni()

			count := savedList.Length
			this.Gui["BoostBar_Config" index].Text := (count = 0) ? "None" : (count > 1 ? "Multiple" : saveString)

			if IsSet(Boost) && Boost
				Boost.RefreshConfig()
				Boost.Draw()
		}

		CheckBoxes := Map()
		ModeList := []
		for i in ["Timer", "ReGlitter", "On Scorch", "ReSmoothie", "On Pop Star", "On Baller", "On Shower", "On Gummy"]
			ModeList.Push(i)

		Columns := 2
		Margin := 10

		for index, modeName in ModeList {
			i := A_Index - 1
			col := Mod(i, Columns)
			row := Floor(i / Columns)
			isChecked := InStr("|" currentConfig "|", "|" modeName "|")
			x := Margin + (col * 100)
			y := Margin + (row * 25)
			cb := ModeGui.Add("CheckBox", "x" x " y" y " w20 h20 Checked" isChecked)
			cb.OnEvent("Click", UpdateConfig.Bind(this))
			ModeGui.Add("Text", "x" x + 20 " y" y + 3 " w100 h20 c" (Config.Get("Main", "DarkMode", 1) ? "White" : "Black"), modeName)
			CheckBoxes[modeName] := cb
		}
		TotalRows := Ceil(ModeList.Length / Columns)
		MinWidth := (Margin * 2) + (Columns * 100)
		MinHeight := (Margin * 2) + (TotalRows * 25)
		ModeGui.Show("w" MinWidth " h" MinHeight)
		SetWindowTheme(ModeGui, Config.Get("Main", "DarkMode", 1))
		SetWindowAttribute(ModeGui, Config.Get("Main", "DarkMode", 1))
	}

	UpdatePassives(GuiCtrl, *) {
		current := Config.Get("Tracker", "Passives", "scorch")
		list := StrSplit(current, "|")

		name := StrLower(StrReplace(GuiCtrl.Name, "Tracker_", ""))
		if (name = "xflame")
			name := "x-flame"
		
		newList := []
		found := false
		for item in list {
			if (item = name)
				found := true
			else if (item != "")
				newList.Push(item)
		}

		if (GuiCtrl.Value)
			newList.Push(name)
		saveStr := ""
		for item in newList
			saveStr .= (A_Index > 1 ? "|" : "") item
		Config.Set("Tracker", "Passives", saveStr)
		Config.WriteIni()
		this.RefreshFeature("TrackerEnabled")
	}

	OpenWarnSettings(warnKey, name, *) {
		static WarnGui := ""
		GuiClose(*) {
			if (IsSet(WarnGui) && IsObject(WarnGui))
				try WarnGui.Destroy(), WarnGui := ""
		}
		GuiClose()

		WarnGui := Gui("+Owner" this.Gui.Hwnd " +AlwaysOnTop +Border +ToolWindow", name " Settings")
		WarnGui.SetFont("s9 cDefault Norm", "MS Sans Serif")
		WarnGui.OnEvent("Close", (*) => GuiClose())

		SaveLocal(*) {
			Config.Set("Warns", warnKey "_Volume", WarnGui["Volume"].Value)
			Config.Set("Warns", warnKey "_PlayOnce", WarnGui["PlayOnce"].Value)
			Config.WriteIni()
			this.RefreshFeature("WarnsEnabled")
		}

		BrowseSound(*) {
			SelectedFile := FileSelect(1, , "Select Sound File", "Audio (*.wav; *.mp3)")
			if SelectedFile {
				WarnGui["SoundFile"].Value := SelectedFile
				Config.Set("Warns", warnKey "_SoundFile", SelectedFile)
				Config.WriteIni()
			}
		}

		TestLocalAudio(*) {
			soundPath := WarnGui["SoundFile"].Value
			if !FileExist(soundPath)
				soundPath := "C:\Windows\Media\Windows Critical Stop.wav"
			this.AudioPlayer := unset
			this.AudioPlayer := Audio(soundPath)
			vol := WarnGui["Volume"].Value
			try this.AudioPlayer.Play(vol)
		}

		col := (Config.Get("Main", "DarkMode", 1) ? "White" : "Black")
		WarnGui.Add("Text", "x15 y15 w50 c" col, "Volume:")
		WarnGui.Add("Edit", "x65 y12 w50 Number vVolume", Config.Get("Warns", warnKey "_Volume", 25)).OnEvent("Change", SaveLocal)
		WarnGui.Add("UpDown", "Range0-100", Config.Get("Warns", warnKey "_Volume", 25))
		WarnGui.Add("Text", "x120 y15 c" col, "%")

		WarnGui.Add("CheckBox", "x15 y40 w20 h20 vPlayOnce Checked" Config.Get("Warns", warnKey "_PlayOnce", 0)).OnEvent("Click", SaveLocal)
		WarnGui.Add("Text", "x35 y43 w60 c" col, "Play Once")

		WarnGui.Add("Text", "x15 y70 w50 c" col, "Sound:")
		WarnGui.Add("Button", "x60 y67 w60 h22", "Browse").OnEvent("Click", BrowseSound)
		WarnGui.Add("Button", "x125 y67 w60 h22", "Test").OnEvent("Click", TestLocalAudio)
		WarnGui.Add("Edit", "x15 y95 w220 h20 ReadOnly vSoundFile", Config.Get("Warns", warnKey "_SoundFile", "C:\Windows\Media\Windows Critical Stop.wav"))

		WarnGui.Show("w250 h130")
		SetWindowTheme(WarnGui, Config.Get("Main", "DarkMode", 1))
		SetWindowAttribute(WarnGui, Config.Get("Main", "DarkMode", 1))
	}

	CopyFieldSettings(*) {
		settings := Config.Get("Alt", "DefaultField") "|" Config.Get("Alt", "Pattern") "|" Config.Get("Alt", "PatternSize") "|" Config.Get("Alt", "PatternWidth") "|" Config.Get("Alt", "SprinklerLocation") "|" Config.Get("Alt", "SprinklerDistance") "|" Config.Get("Alt", "RotationAmount") "|" Config.Get("Alt", "RotationDirection")
		A_Clipboard := settings
		ToolTip("Settings copied to clipboard")
		SetTimer(ToolTip, -500)
	}

	PasteFieldSettings(*) {
		try {
			data := StrSplit(A_Clipboard, "|")
			if (data.Length != 8) {
				ToolTip("Invalid settings.")
				SetTimer(ToolTip, -500)
				return
			}

			Config.Set("Alt", "DefaultField", data[1])
			Config.Set("Alt", "Pattern", data[2])
			Config.Set("Alt", "PatternSize", data[3])
			Config.Set("Alt", "PatternWidth", data[4])
			Config.Set("Alt", "SprinklerLocation", data[5])
			Config.Set("Alt", "SprinklerDistance", data[6])
			Config.Set("Alt", "RotationAmount", data[7])
			Config.Set("Alt", "RotationDirection", data[8])
			Config.WriteIni()

			this.Gui["Alt_DefaultField"].Text := data[1]
			this.Gui["Alt_Pattern"].Text := data[2]
			this.Gui["Alt_PatternSize"].Value := data[3]
			this.Gui["Alt_PatternWidth"].Value := data[4]
			this.Gui["Alt_SprinklerLocation"].Text := data[5]
			this.Gui["Alt_SprinklerDistance"].Value := data[6]
			this.Gui["Alt_RotationAmount"].Value := data[7]
			this.Gui["Alt_RotationDirection"].Text := data[8]
			ToolTip("Settings pasted from clipboard")
			SetTimer(ToolTip, -500)
		} catch {
			ToolTip("Error pasting settings.")
			SetTimer(ToolTip, -500)
		}
	}

	ToggleFeature(GuiCtrl, *) {
		isChecked := GuiCtrl.Value
		FeatureName := StrReplace(GuiCtrl.Name, "Main_", "")
		Config.Set("Main", FeatureName, isChecked)
		Config.WriteIni()

		if (FeatureName = "AltMacroEnabled") {
			role := isChecked ? "Client" : "Server"
			try this.Gui["CommsStatus"].Text := role
			if IsSet(Comms)
				Comms.UpdateSettings()
		}
		this.RefreshFeature(FeatureName)
	}

	SaveConfig(GuiCtrl, *) {
		p := InStr(GuiCtrl.Name, "_")
		if !p
			return
		Section := SubStr(GuiCtrl.Name, 1, p - 1)
		Key := SubStr(GuiCtrl.Name, p + 1)
		val := (GuiCtrl.Type = "DDL") ? GuiCtrl.Text : GuiCtrl.Value
		Config.Set(Section, Key, val)
		Config.WriteIni()
		if (Section = "BoostBar")
			this.RefreshFeature("BoostBarEnabled")
		else if (Section = "Warns")
			this.RefreshFeature("WarnsEnabled")
		else if (Section = "Tracker")
			this.RefreshFeature("TrackerEnabled")
		else if (Section = "Main" && (Key = "BoostBarEnabled" || Key = "WarnsEnabled" || Key = "TrackerEnabled"))
			this.RefreshFeature(Key)
		else if (Section = "Communicator")
			if IsSet(Comms)
				Comms.UpdateSettings()
		if (Key = "AccountType")
			Reload

		if (Key = "DarkMode") {
			SetWindowTheme(this.Gui, GuiCtrl.Value)
			SetWindowAttribute(this.Gui, GuiCtrl.Value)
		}

		if (Key ~= "SlotTimer") {
			if IsSet(Boost) && Boost
				Boost.Draw()
		}

		if (Section = "BoostBar")
			if IsSet(Boost) && Boost
				Boost.Draw()
	}

	LoadPreset(*) {
		selected := this.Gui["PresetDDL"].Text
		if !selected
			return
		Config.SetPreset(selected)
		Reload
	}

	SavePreset(*) {
		Config.WriteIni()
		Tooltip "Preset saved."
		SetTimer Tooltip, -750
	}

	NewPreset(*) {
		presetName := InputBox("Enter a new preset name:", "New Preset", "w200 h100").Value
		if (presetName = "")
			return
		presetName := RegExReplace(presetName, "[\\/:\*\?`"<>\|]", "")

		if (StrLower(presetName) = "global") {
			MsgBox("Cannot use 'global' as a preset name.", "Kairos", 48)
			return
		}

		newPath := A_WorkingDir "\settings\" presetName ".ini"
		try FileCopy(Config.path, newPath, 1)
		Config.SetPreset(presetName)
		Reload
	}

	DeletePreset(*) {
		selected := this.Gui["PresetDDL"].Text
		if (selected = "config" || selected = "") {
			MsgBox("Cannot delete the default config profile.", "Kairos", 48)
			return
		}
		result := MsgBox("Are you sure you want to delete the profile '" selected "'?", "Delete Profile", "YesNo Icon?")
		if (result = "Yes") {
			filePath := A_WorkingDir "\settings\" selected ".ini"
			if FileExist(filePath)
				FileDelete(filePath)
				Config.SetPreset("config")
				Reload
		}
	}

	RefreshFeature(FeatureName) {
		if (this.FeatureRefreshers.Has(FeatureName))
			this.FeatureRefreshers[FeatureName]()
	}

	UpdateUI() {
		accountType := Config.Get("Main", "AccountType", "Main")
		activeFeatures := (accountType = "Main") ? "|Warns|Boost Bar|Key Alignment|Tracker|Magnifier|Stat Monitor|" : "|Alt Macro|Boost Bar|"

		yBase := 40
		visibleIdx := 0

		for featureName in this.FeatureList {
			ctrls := this.FeatureControls[featureName]
			if InStr(activeFeatures, "|" featureName "|") {
				ctrls.chk.Visible := true
				ctrls.txt.Visible := true
				ctrls.chk.Move(, yBase + (20 * visibleIdx))
				ctrls.txt.move(, yBase + 3 + (20 * visibleIdx))
				visibleIdx++
			} else {
				ctrls.chk.Visible := false
				ctrls.txt.Visible := false
			}
		}
		this.Gui["FeaturesGroup"].Move(, , , (20 * (visibleIdx + 1)))
	}

	SelectSound(GuiCtrl, *) {
		SelectedFile := FileSelect(1, , "Select Sound File", "Audio (*.wav; *.mp3)")
		if SelectedFile {
			this.Gui["Warns_SoundFile"].Value := SelectedFile
			Config.Set("Warns", "SoundFile", SelectedFile)
			Config.WriteIni()
		}
	}

	TextExtend(text, textCtrl) {
		hDC := DllCall("GetDC", "Ptr", textCtrl.Hwnd, "Ptr")
		hFold := DllCall("SelectObject", "Ptr", hDC, "Ptr", SendMessage(0x31, , , textCtrl), "Ptr")
		nSize := Buffer(8)
		DllCall("GetTextExtentPoint32", "Ptr", hDC, "Str", text, "Int", StrLen(text), "Ptr", nSize)
		DllCall("SelectObject", "Ptr", hDC, "Ptr", hFold)
		DllCall("ReleaseDC", "Ptr", textCtrl.Hwnd, "Ptr", hDC)
		return NumGet(nSize, 0, "UInt")
	}

	start(*) {
		if this.ran
			return

		this.ran++
		State.offsetY := GetYOffset(, &fail)
		try {
		if fail
			msgbox "Failed to get y-Offset, this either means`n1. Your font is NOT the default size (e.g. font scale or broken roblox updates)`n2. Your font is wrong (e.g. custom font w/bloxstrap)`n3. the 'Pollen' text at the top is being covered`n4. Graphical issues`n5. I made a mistake...`n6. You don't have roblox open.", "Kairos", 16
		}
		if (IsSet(Comms) && Comms.isEnabled && Comms.isServer)
			Comms.BroadcastStart()
		
		accountType := Config.Get("Main", "AccountType", "Main")

		Boost.Toggle()
		
		if (accountType = "Main") {
			if (Config.Get("Main", "TrackerEnabled", 0) || Config.Get("Main", "WarnsEnabled", 0))
				Scanner.Toggle(1)
			Track.Toggle()
			Warns.Toggle()
			Aligner.Toggle()
			Mag.Toggle()
			Stats.Toggle()
		} else if (accountType = "Alt") {
			Alt.Toggle()
		}
		this.Gui.Show("Hide")
	}

	pause(*) {
		if this.ran != 1
			return
		State.IsPaused ^= 1

		if (State.IsPaused) {
			this.Gui.Show("")
			this.Gui.Title := "Kairos (Paused)"
			this.Gui["PauseButton"].Text := "Resume (" Config.Get("Main", "PauseHotkey", "F2") ")"

			if IsSet(Track) && Track.Fancy
				Track.Fancy.Hide()
			if IsSet(Warns) && Warns.Fancy
				Warns.Fancy.Hide()
			if IsSet(Boost) && Boost {
				Boost.Draw()
				Boost.FollowWindow()
			}
			if IsSet(Aligner) && Aligner
				Aligner.Draw()
			if IsSet(Mag) && Mag.Gui
				Mag.Gui.Hide()
			if IsSet(Stats) && Stats
				Stats.Pause()

			DetectHiddenWindows true
			if WinExist("ahk_class AutoHotkey ahk_pid " State.CurrentWalk.pid)
				send "{F16}"
			DetectHiddenWindows false
		} else {
			this.Gui.Hide()
			this.Gui.Title := "Kairos"
			this.Gui["PauseButton"].Text := "Pause (" Config.Get("Main", "PauseHotkey", "F2") ")"

			if IsSet(Boost) && Boost
				Boost.Draw()
			if IsSet(Aligner) && Aligner
				Aligner.Draw()

			DetectHiddenWindows true
			if WinExist("ahk_class AutoHotkey ahk_pid " State.CurrentWalk.pid)
				send "{F14}"
			DetectHiddenWindows false

		}
		Pause -1
	}

	stop(*) {
		if (this.ran && IsSet(Stats) && Stats)
			Stats.Export()
		Reload
	}

	RegisterHotkeys() {
		try {
			Hotkey(Config.Get("Main", "StartHotkey", "F1"), (*) => this.start())
			Hotkey(Config.Get("Main", "PauseHotkey", "F2"), (*) => this.pause())
			Hotkey(Config.Get("Main", "StopHotkey", "F3"), (*) => this.stop())
		}
	}
}
