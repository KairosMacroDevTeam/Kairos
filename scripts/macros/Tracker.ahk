class Tracker {
	IsRunning := false
	IsActive := false

	OffsetX := 0
	OffsetY := 0
	EditMode := false
	cooldowns := Map(
		"scorch", { last_not_found: 0, cooldown: 60000, duration: 45000 }
		, "x-flame", { last_not_found: 0, cooldown: 20000, duration: 0 }
		, "popstar", { last_not_found: 0, cooldown: 60000, duration: 45000 }
		, "gummystar", { last_not_found: 0, cooldown: 60000, duration: 45000 }
	)

	__New() {
		this.Fancy := GdipTooltip(true)
		this.RefreshConfig()
		Scheduler.Add("Tracker.CheckLoop", this.CheckLoop.Bind(this), 100, () => this.IsActive)

		OnMessage(0x0232, this.OnDragEnd.Bind(this))
	}

	Toggle(*) {
		this.IsRunning ^= 1
		this.IsActive := this.IsRunning && Config.Get("Main", "TrackerEnabled", 0)
		SetTimer(() => this.Fancy.Hide(), this.IsActive ? 0 : -100)
	}

	Cleanup(*) {
		this.IsRunning := false
	}

	CheckLoop(*) {
		if (State.IsPaused || this.EditMode)
			return

		if (this.Fancy.Zoom != Config.Get("Tracker", "Zoom", 1.0)) {
			Config.Set("Tracker", "Zoom", this.Fancy.Zoom)
			Config.WriteIni()
		}
		
		win := WindowTracker.Get()
		if !this.IsRunning || !IsObject(win) || !win.ok
			return
		msg := []

		for i in this.PassiveList {
			if !Scanner.Profiles.Has(i)
				continue
			val := Scanner.Data[i]
			if (i = "precise")
				val := (val = -1) ? -1 : this.FormatTime(Round((val / 100) * 60))
			else if (i = "supersmoothie")
				val := (val = -1) ? -1 : this.FormatTime(Round((val / 100) * 1200))
			
			msgSuffix := ""
			if (val = -1) {
				if this.cooldowns.Has(i) {
					cooldown := this.cooldowns[i]
					if (cooldown.last_not_found = 0)
						msgSuffix := ": N/A"
					else {
						elapse := QPC() - cooldown.last_not_found
						if (elapse <= cooldown.duration)
							msgSuffix := ": Active: " Round((cooldown.duration - (QPC() - cooldown.last_not_found)) / 1000) "s"
						else
							msgSuffix := ": CD: " Round((cooldown.cooldown - (QPC() - cooldown.last_not_found)) / 1000) "s"
					}
				} else
					msgSuffix := ": N/A"
			} else {
				if this.cooldowns.Has(i)
					this.cooldowns[i].last_not_found := QPC()
				msgSuffix := ": " val
			}
			msg.Push([bitmaps["icon"][i], msgSuffix])
		}
		this.Fancy.Show(msg, (win.x + win.w // 2) + this.OffsetX, win.y + win.h // 2 + this.OffsetY)
	}

	FormatTime(totalSecs) {
		if (totalSecs > 60) {
			mins := Floor(totalSecs / 60)
			secs := Mod(totalSecs, 60)
			return (secs > 0) ? mins "m " secs "s" : mins "m"
		}
		return totalSecs "s"
	}

	OnDragEnd(wParam, lParam, msg, hwnd) {
		if (hwnd = this.Fancy.hwnd) {
			win := WindowTracker.Get()
			if (IsObject(win) && win.ok) {
				WinGetPos(&guiX, &guiY, , , "ahk_id " this.Fancy.hwnd)
				this.OffsetX := guiX - (win.x + win.w // 2)
				this.OffsetY := guiY - (win.y + win.h // 2)
				Config.Set("Tracker", "OffsetX", this.OffsetX)
				Config.Set("Tracker", "OffsetY", this.OffsetY)
				Config.WriteIni()
				this.Fancy._manualPos := false
			}
		}
	}

	RefreshConfig() {
		this.PassiveList := StrSplit(Config.Get("Tracker", "Passives", "scorch"), "|")
		this.OffsetX := Config.Get("Tracker", "OffsetX", 0)
		this.OffsetY := Config.Get("Tracker", "OffsetY", 0)
		this.Fancy.Zoom := Config.Get("Tracker", "Zoom", 1)
	}
}
