class Config {
	static currentPreset := "config"
	static path := A_WorkingDir "\settings\config.ini"
	static Data := Map()

	static Default := Map(
		"Main", Map(
			"StartHotkey", "F1"
			, "PauseHotkey", "F2"
			, "StopHotkey", "F3"
			, "WarnsEnabled", 0
			, "BoostBarEnabled", 0
			, "AltMacroEnabled", 0
			, "TrackerEnabled", 0
			, "KeyAlignmentEnabled", 0
			, "MagnifierEnabled", 0
			, "StatMonitorEnabled", 0
			, "AlwaysOnTop", 0
			, "HideOnRun", 0
			, "GuiX", A_ScreenWidth // 2 - 200
			, "GuiY", A_ScreenHeight // 2 - 100
			, "DarkMode", 1
			, "AccountType", "Main"
		)
		, "Alt", Map(
			"Movespeed", 29
			, "HiveSlot", 1
			, "FieldDriftComp", 1
			, "AltNumber", 1
			, "DefaultField", "pepper"
			, "Pattern", "GeneralBooster"
			, "PatternSize", 1
			, "PatternWidth", 1
			, "RotationAmount", 0
			, "RotationDirection", "Right"
			, "ShiftLock", 0
			, "SprinklerLocation", "Center"
			, "SprinklerDistance", 1
			, "PrivServer", ""
			, "ClaimHive", 1
			, "IgnoreInactiveHoney", 0
			, "UseTool", 1
		)
		, "BoostBar", Map(
			"SlotActive1", 0, "SlotTimer1", 100, "SlotMode1", "Timer"
			, "SlotActive2", 0, "SlotTimer2", 100, "SlotMode2", "Timer"
			, "SlotActive3", 0, "SlotTimer3", 100, "SlotMode3", "Timer"
			, "SlotActive4", 0, "SlotTimer4", 100, "SlotMode4", "Timer"
			, "SlotActive5", 0, "SlotTimer5", 100, "SlotMode5", "Timer"
			, "SlotActive6", 0, "SlotTimer6", 100, "SlotMode6", "Timer"
			, "SlotActive7", 0, "SlotTimer7", 100, "SlotMode7", "Timer"
			, "ShowWhenActive", 1
		)
		, "Warns", Map(
			"Precise_Enabled", 0
			, "Precise_Threshold", 25
			, "Precise_Volume", 25
			, "Precise_PlayOnce", 0
			, "Precise_SoundFile", A_WorkingDir "\Assets\Audio\Precision.mp3"

			, "Smoothie_Enabled", 0
			, "Smoothie_Threshold", 180
			, "Smoothie_Volume", 25
			, "Smoothie_PlayOnce", 1
			, "Smoothie_SoundFile", A_WorkingDir "\Assets\Audio\Smoothie.mp3"

			, "Pop_Enabled", 0
			, "Pop_Threshold", 25
			, "Pop_Volume", 25
			, "Pop_PlayOnce", 0
			, "Pop_SoundFile", A_WorkingDir "\Assets\Audio\PopStar.mp3"

			, "Scorch_Enabled", 0
			, "Scorch_Threshold", 25
			, "Scorch_Volume", 25
			, "Scorch_PlayOnce", 0
			, "Scorch_SoundFile", A_WorkingDir "\Assets\Audio\ScorchStar.mp3"

			, "Shower_Enabled", 0
			, "Shower_Threshold", 20
			, "Shower_Volume", 25
			, "Shower_PlayOnce", 0
			, "Shower_SoundFile", A_WorkingDir "\Assets\Audio\Shower.mp3"

			, "Morph_Enabled", 0
			, "Morph_Threshold", 25
			, "Morph_Volume", 25
			, "Morph_PlayOnce", 0
			, "Morph_SoundFile", A_WorkingDir "\Assets\Audio\GummyMorph.mp3"

			, "Gummy_Enabled", 0
			, "Gummy_Threshold", 70
			, "Gummy_Volume", 27
			, "Gummy_PlayOnce", 0
			, "Gummy_SoundFile", A_WorkingDir "\Assets\Audio\GummyStar.mp3"

			, "Baller_Enabled", 0
			, "Baller_Threshold", 901
			, "Baller_Volume", 25
			, "Baller_PlayOnce", 0
			, "Baller_SoundFile", A_WorkingDir "\Assets\Audio\Baller.mp3"

			, "Combo_Enabled", 0
			, "Combo_Threshold", 35
			, "Combo_Volume", 25
			, "Combo_PlayOnce", 0
			, "Combo_SoundFile", A_WorkingDir "\Assets\Audio\CocoCombo.mp3"
		)
		, "Tracker", Map(
			"Passives", "scorch"
			, "OffsetX", 0
			, "OffsetY", 0
			, "Zoom", 1
		)
		, "KeyAlignment", Map(
			"AlignmentKey", "e"
			, "RebindHotkey", "^+k"
		)
		, "Communicator", Map(
			"CommunicationEnabled", 0
			, "DweetName", "K" Random(10000000, 99999999) "X" Random(10000000, 99999999)
		)
		, "StatMonitor", Map(
			"Enabled", 0
		)
		, "Guide", Map(
			"Enabled", 0
			, "Field", "pepper"
			, "PrivLink", ""
		)
	)

	static __New() {
		if !DirExist("settings")
			DirCreate "settings"
		globalPath := A_WorkingDir "\settings\global.ini"
		try
			this.currentPreset := IniRead(globalPath, "Global", "LastPreset", "config")
		catch
			this.currentPreset := "config"
		this.path := A_WorkingDir "\settings\" this.currentPreset ".ini"
	}

	static SetPreset(presetName) {
		this.currentPreset := presetName
		this.path := A_WorkingDir "\settings\" presetName ".ini"

		globalPath := A_WorkingDir "\settings\global.ini"
		IniWrite(presetName, globalPath, "Global", "LastPreset")

		this.Data.Clear()
		this.Load()
	}

	static GetPresets() {
		if !DirExist("settings")
			DirCreate "settings"
		list := []
		Loop Files A_WorkingDir "\settings\*.ini" {
			name := SubStr(A_LoopFileName, 1, -4)
			if (name != "global")
				list.Push(name)
		}
		if (list.Length = 0)
			list.Push("config")
		return list
	}

	static Load() {
		for section, keys in this.Default {
			if !this.Data.Has(section)
				this.Data[section] := Map()
			for key, val in keys {
				this.Data[section][key] := val
			}
		}
		if FileExist(this.path)
			this.ReadIni()
		this.WriteIni()
	}

	static ReadIni() {
		try {
			iniFile := FileOpen(this.path, "r")
			str := iniFile.Read()
			iniFile.Close()
		} catch
			return

		currentSection := ""

		Loop Parse, str, "`n", "`r" {
			line := Trim(A_LoopField)
			if (line = "" || SubStr(line, 1, 1) = ";")
				continue

			if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
				currentSection := SubStr(line, 2, -1)
				if !this.Data.Has(currentSection)
					this.Data[currentSection] := Map()
				continue
			}

			if (p := InStr(line, "=")) && (currentSection != "") {
				key := Trim(SubStr(line, 1, p - 1))
				val := Trim(SubStr(line, p + 1))
				if IsInteger(val)
					val := Integer(val)
				if IsFloat(val)
					val := Round(Float(val), 2)
				this.Data[currentSection][key] := val
			}
		}
	}

	static WriteIni() {
		if !DirExist("settings")
			DirCreate "settings"

		iniStr := ""
		for section, keys in this.Default {
			iniStr .= "[" section "]`r`n"
			for key, val in keys {
				currentVal := (this.Data.Has(section) && this.Data[section].Has(key)) ? this.Data[section][key] : val
				if IsFloat(currentVal)
					currentVal := Round(currentVal, 2)
				iniStr .= key "=" currentVal "`r`n"
			}
			iniStr .= "`r`n"
		}
		f := FileOpen(this.path, "w", "UTF-8")
		f.Write(iniStr)
		f.Close()
	}

	static Set(section, key, val) => (this.Data.Has(section) ? this.Data[section][key] := val : this.Data[section] := Map(key, val))
	static Get(section, key, defaultVal := "") => (this.Data.Has(section) && this.Data[section].Has(key)) ? this.Data[section][key] : defaultVal
}
