class ScannerEngine {
	IsRunning := false
	Detector := unset

	Data := Map()

	PercentBuffers := Map()
	GummyStar := {slot: -1, pity: 0, lastUse: 0}

	Profiles := Map(
		"scorch", { type: "passive", x1: 0, x2: 0, y1: 11, y2: 16, var: 30 }
		, "x-flame", { type: "passive", x1: 0, x2: 0, y1: 9, y2: 18, var: 30 }
		, "popstar", { type: "passive", x1: 0, x2: 0, y1: 7, y2: 19, var: 30 }
		, "gummymorph", { type: "passive", x1: 0, x2: 0, y1: 7, y2: 14, var: 30 }
		, "shower", { type: "passive", x1: 0, x2: 0, y1: 0, y2: 0, var: 30 }
		, "combo", { type: "passive", x1: 0, x2: 0, y1: 0, y2: 0, var: 30 }
		
		, "gummyballer", { type: "buff", x1: 0, x2: 0, y1: 0, y2: 0, var: 30 }
		, "supersmoothie", { type: "percent_buff", img: "smoothie", xOff: -5, colors: [0xffFEC650] }
		, "precise", { type: "percent_buff", img: "Precise", xOff: 9, colors: [0xff8F4EB4, 0xff774296, 0xff3E274C, 0xff211A24, 0xff201A24, 0xff221A26, 0xff55316A, 0xff8448A6] }

		, "gummystar", { type: "custom", method: "DetectGumdrops", x1: 0, x2: 0, y1: 7, y2: 14, var: 30 }

		, "bloom_red",        { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFFC9191}
		, "bloom_blue",       { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF90A1FC}
		, "bloom_white",      { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFFCFCFC}
		, "bloom_scarlet",    { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFD58989}
		, "bloom_cyan",       { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF8EE2EF}
		, "bloom_grey",       { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFBFBFBF}
		, "bloom_black",      { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF858585}
		, "bloom_yellow",     { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFF7E6A7}
		, "bloom_green",      { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF91F482}
		, "bloom_pink",       { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFFFC1E4}
		, "bloom_violet",     { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFAF93D8}
		, "bloom_merigold",   { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFECD48E}
		, "bloom_periwinkle", { type: "bloom", x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFCBCEF6}
	)

	__New() {
		this.Detector := Detection()

		for name in this.Profiles
			this.Data[name] := (this.Profiles[name].type = "percent_buff") ? 0.0 : 0
		Scheduler.Add("Scanner.MainLoop", this.MainLoop.Bind(this), 100, () => this.IsRunning)
	}

	Toggle(forceState := -1) {
		if (forceState != -1)
			this.IsRunning := forceState
		else
			this.IsRunning ^= 1
	}

	MainLoop(*) {
		if (State.IsPaused)
			return
		win := WindowTracker.Get()
		if (!IsObject(win) || !win.ok)
			return
		
		pBMTop := FrameCache.Get(win.x "|" win.y + State.offsetY + 48 "|" win.w "|32")
		pBMTopPercent := FrameCache.Get(win.x "|" win.y + State.offsetY + 32 "|" win.w "|42")
		pBMBottom := FrameCache.Get(win.x + (win.w // 2) - 257 "|" win.y + win.h - 142 "|517|36")
		pBMHotbar := FrameCache.Get(win.x + (win.w // 2) - 261 "|" win.y + win.h - 102 "|517|68")

		if (!pBMTop || !pBMTopPercent ||!pBMBottom || !pBMHotbar)
			return
		for name, profile in this.Profiles {
			if (profile.type = "passive")
				this.Data[name] := this.ScanPassive(pBMBottom, name, profile)
			else if (profile.type = "buff")
				this.Data[name] := this.ScanBuff(pBMTop, name, profile)
			else if (profile.type = "percent_buff")
				this.Data[name] := this.ScanPercentBuff(pBMTopPercent, name, profile)
			else if (profile.type = "custom") {
				method := profile.method
				this.Data[name] := this.%method%(pBMBottom, pBMHotbar)
			}
		}
	}

	ScanPassive(pBitmap, name, profile) {
		icon := this.Detector.SearchIcon(pBitmap, bitmaps["buff"][name], profile.x1, profile.y1, profile.x2, profile.y2, profile.var)
		if (!icon.found)
			return -1
		
		slotX := Floor(icon.x // 40)
		return this.Detector.ReadDigits(pBitmap, slotX * 40, 22, (slotX * 40) + 34, 33, "passive")
	}

	ScanBuff(pBitmap, name, profile) {
		icon := this.Detector.SearchIcon(pBitmap, bitmaps["buff"][name], profile.x1, profile.y1, profile.x2, profile.y2, profile.var)
		if (!icon.found)
			return -1
		val := this.Detector.ReadDigits(pBitmap, icon.x - 13, 0, icon.x + 25, 32, "auto")
		return (val > 0) ? val : -1
	}

	ScanPercentBuff(pBitmap, name, profile) {
		imgName := profile.HasProp("img") ? profile.img : name
		if !this.PercentBuffers.Has(name)
			this.PercentBuffers[name] := []
		buff := this.PercentBuffers[name]

		icon := this.Detector.SearchIcon(pBitmap, bitmaps["buff"][imgName], 0, 0, 0, 0, 4)
		if (!icon.found) {
			this.PercentBuffers[name] := []
			return -1
		}
		lowY := this.Detector.ReadPercentageFill(pBitmap, icon.x + profile.xOff, 0, icon.y, profile.colors, 0)
		raw := Round((icon.y - lowY) / 38 * 100, 2) + 2
		buff.Push(raw)
		if (buff.Length > 6)
			buff.RemoveAt(1)
		best := []
		for val1 in buff {
			current := []
			for val2 in buff
				if (Abs(val1 - val2) <= 5)
					current.Push(val2)
			if (current.Length > best.Length)
				best := current
		}
		if (best.Length = 0)
			return raw
		sum := 0
		for val in best
			sum += val
		return Round(sum / best.Length, 2)
	}

	DetectGumdrops(pBMBottom, pBMHotbar) {
		if (this.ScanPassive(pBMBottom, "gummystar", this.Profiles["gummystar"]) = -1) {
			this.GummyStar.pity := 0
			return -1
		}

		if (this.GummyStar.slot = -1) {
			if (Gdip_ImageSearch(pBMHotbar, bitmaps["buff"]["gumdrop"], &loc, , , , , 5) = 1) {
				foundX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				this.GummyStar.slot := Floor(foundX / 75) ; 0 is slot 1
			} else
				return this.GummyStar.pity
		}

		xOff := this.GummyStar.slot * 75
		xSize := xOff + 5
		yOff := 15
		ySize := yOff + 38
		if (Gdip_ImageSearch(pBMHotbar, bitmaps["buff"]["unused_slot"], &loc, xOff, yOff, xSize, ySize, 5) = 0) {
			if A_TickCount - this.GummyStar.lastUse >= 2010 {
				this.GummyStar.pity++
				this.GummyStar.lastUse := A_TickCount
			}
			if (this.GummyStar.pity >= 75)
				this.GummyStar.pity := 0
		}
		return this.GummyStar.pity
	}

	ScanBloom(pBitmap, name, profile) {
		icon := this.Detector.SearchIcon(pBitmap, bitmaps["buff"][name], profile.x1, profile.y1, profile.x2, profile.y2, profile.var)
		if (!icon.found)
			return -1
		slotX := Floor(icon.x / 38) * 38
		scanX := slotX + 6
		
		if !this.PercentBuffers.Has(name)
			this.PercentBuffers[name] := {val: 0, fail: 0}
		state := this.PercentBuffers[name]

		if !this.Detector._IsColorMatch(Gdip_GetPixel(pBitmap, scanX, 37), profile.col, 100) {
			if (++state.fail < 15)
				return state.val
			return 0
		}
		state.fail := 0
		lowY := this.Detector.ReadPercentageFill(pBitmap, scanX, 0, 35, profile.col, 100)
		state.val := Round((36 - lowY) / 36, 2)
		return state.val
	}
}