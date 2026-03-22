class Warnings {
	IsRunning := false
	IsActive := false

	AudioCache := Map()
	LastPlayed := Map()
	HasPlayed := Map()

	WarnProfiles := Map(
		"Precision", { conf: "Precise", key: "precise", max: 60, mult: 0.6 }
		, "Super Smoothie", { conf: "Smoothie", key: "supersmoothie", max: 1200, mult: 12.0 }
		, "Gummy Star", { conf: "Gummy", key: "gummystar", max: 75 }
		, "Pop Star", { conf: "Pop", key: "popstar", max: 30 }
		, "Scorching Star", { conf: "Scorch", key: "scorch", max: 30 }
		, "Star Shower", { conf: "Shower", key: "shower", max: 25 }
		, "Gummy Morph", { conf: "Morph", key: "gummymorph", max: 30 }
		, "Gummyballer", { conf: "Baller", key: "gummyballer", max: 1000 }
		, "Coconut Combo", { conf: "Combo", key: "combo", max: 40 }
	)

	__New() {
		this.Fancy := GdipTooltip()
		Scheduler.Add("Warnings.CheckLoop", this.CheckLoop.Bind(this), 150, () => this.IsActive)
	}

	Cleanup(*) {
		this.IsRunning := false
	}

	Toggle() {
		this.IsRunning ^= 1
		this.IsActive := this.IsRunning && Config.Get("Main", "WarnsEnabled", 0)

		if Config.Get("Main", "WarnsEnabled", 0)
			this.Fancy.Show("Warns: " (this.IsActive ? "ON" : "OFF"))
		SetTimer () => this.Fancy.Hide(), -500
	}

	CheckLoop(*) {
		if (State.IsPaused || !this.IsRunning || !WinActive("Roblox"))
			return

		for warnName, profile in this.WarnProfiles {
			prefix := profile.conf
			if (!Config.Get("Warns", prefix "_Enabled", 0))
				continue

			if (!this.HasPlayed.Has(warnName))
				this.HasPlayed[warnName] := false
			if (!this.LastPlayed.Has(warnName))
				this.LastPlayed[warnName] := 0

			currentVal := Scanner.Data[profile.key]
			if (currentVal = -1) {
				this.HasPlayed[warnName] := false
				continue
			}

			threshold := Config.Get("Warns", prefix "_Threshold", 25)
			isTriggered := false
			ratio := 1.0

			if (profile.HasProp("mult")) {
				currentVal := Round(profile.mult * currentVal)
				if (currentVal <= threshold) {
					isTriggered := true
					ratio := currentVal / threshold
				}
			} else {
				if (currentVal >= threshold) {
					isTriggered := true
					denominator := Max(1, profile.max - threshold)
					ratio := Max(0, Min(1, (profile.max - currentVal) / denominator))
				}
			}
			if (isTriggered)
				this.HandleAlert(warnName, ratio)
			else
				this.HasPlayed[warnName] := false
		}
	}

	HandleAlert(warnName, ratio) {
		prefix := this.WarnProfiles[warnName].conf
		vol := Config.Get("Warns", prefix "_Volume", 25)
		playOnce := Config.Get("Warns", prefix "_PlayOnce", 0)
		soundPath := Config.Get("Warns", prefix "_SoundFile", "C:\Windows\Media\Windows Critical Stop.wav")

		if (playOnce) {
			if (!this.HasPlayed[warnName]) {
				this.PlaySound(soundPath, vol)
				this.HasPlayed[warnName] := true
			}
		} else {
			minDelay := 1000, maxDelay := 5000
			delay := minDelay + (ratio * (maxDelay - minDelay))

			if (A_TickCount - this.LastPlayed[warnName] > delay) {
				this.LastPlayed[warnName] := A_TickCount
				this.PlaySound(soundPath, vol)
			}
		}
	}

	PlaySound(path, vol) {
		if !FileExist(path)
			path := "C:\Windows\Media\Windows Critical Stop.wav"
		if !this.AudioCache.Has(path)
			this.AudioCache[path] := Audio(path)
		this.AudioCache[path].Play(vol)
	}

	RefreshConfig() {
		; this will have a refresh function at some point
	}
}
