class Tracker {
	IsRunning := false
	IsActive := false
	bloomStates := Map()
	buffStates := Map()
	numOffset := Map(0, 7, 1, 2, 2, 6, 3, 6, 4, 7, 5, 6, 6, 7, 7, 7, 8, 7, 9, 7)
	GummyStar := {slot: -1, pity: 0, lastUse: 0}


	modes := Map(
		"scorch", { x1: 0, x2: 0, y1: 11, y2: 16, var: 30 }
		, "x-flame", { x1: 0, x2: 0, y1: 9, y2: 18, var: 30 }
		, "popstar", { x1: 0, x2: 0, y1: 7, y2: 19, var: 30 }
		, "gummystar", { x1: 0, x2: 0, y1: 10, y2:17, var: 30 }
		, "gummymorph", { x1: 0, x2: 0, y1: 7, y2:14, var: 30 }
		, "gummyballer", { x1: 0, x2: 0, y1: 0, y2:0, var: 30 }

		, "bloom_red",        { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFFC9191}
      , "bloom_blue",       { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF90A1FC}
      , "bloom_white",      { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFFCFCFC}
      , "bloom_scarlet",    { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFD58989}
      , "bloom_cyan",       { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF8EE2EF}
      , "bloom_grey",       { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFBFBFBF}
      , "bloom_black",      { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF858585}
      , "bloom_yellow",     { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFF7E6A7}
      , "bloom_green",      { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFF91F482}
      , "bloom_pink",       { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFFFC1E4}
      , "bloom_violet",     { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFAF93D8}
      , "bloom_merigold",   { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFECD48E}
      , "bloom_periwinkle", { x1: 0, x2: 0, y1: 10, y2: 14, var: 21, col: 0xFFCBCEF6}
	)

	__New() {
		this.Fancy := GdipTooltip()
		this.RefreshConfig()
		Scheduler.Add("Tracker.CheckLoop", this.CheckLoop.Bind(this), 100, () => this.IsActive)
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
		if (State.IsPaused)
			return
		win := WindowTracker.Get()
		if !this.IsRunning || !IsObject(win) || !win.ok
			return

		passiveNames := this.PassiveList
		msg := []
		for i in passiveNames {
			if i = "gummyballer"
				val := this.DetectBuffs(i)
			else if i = "gummystar"
				val := this.DetectGumdrops() ; keeps count I guess
			else
				val := this.DetectPassive(i)
			msg.Push([bitmaps["icon"][i], (val = -1 ? ": " (i = "gummyballer" ? "N/A" : "CD") : ": " val)])
		}



		; "red", "blue", "white", "scarlet", "cyan", "grey", "black", "yellow", "green", "pink", "violet", "merigold", "periwinkle"
		;for i in ["red", "pink"] {
		;	bloomVal := this.DetectBlooms("bloom_" i)
		;	msg.Push([bitmaps["icon"]["bloom_" i], (bloomVal = -1 ? ": N/A" : ": " (8*bloomVal))])
		;}


		this.Fancy.Show(msg, win.x + win.w // 2, win.y + win.h // 2)
		return
	}

	DetectPassive(name) {
		mode := this.modes[name]
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok
			return -1
		region := win.x + (win.w // 2) - 257 "|" win.y + win.h - 142 "|517|36"
		pBMScreen := FrameCache.Get(region)
		if !pBMScreen
			return -1
		if (Gdip_ImageSearch(pBMScreen, bitmaps["buff"][name], &loc, mode.x1, mode.y1, mode.x2, mode.y2, mode.var) != 1)
			return -1
		foundX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
		return this.DetectNumber(pBMScreen, Floor(foundX / 40))
	}

	DetectBuffs(name) {
		mode := this.modes[name]
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok
			return -1
		
		if !this.buffStates.Has(name)
			this.buffStates[name] := {val: 0, fail: 0}
		buff := this.buffStates[name]

		region := win.x "|" win.y + State.offsetY + 48 "|" win.w "|" 32
		pBMScreen := FrameCache.Get(region)
		if !pBMScreen
			return -1

		if (Gdip_ImageSearch(pBMScreen, bitmaps["buff"][name], &loc, mode.x1, mode.y1, mode.x2, mode.y2, mode.var, , 8) != 1)
			return -1
		foundX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
		foundY := Integer(SubStr(loc, InStr(loc, ",") + 1))

		current := this.DetectBuffNum(foundX, foundY, pBMScreen, "tiny")
		if (current < 100)
			current := this.DetectBuffNum(foundX, foundY, pBMScreen, "big")

		if (current > 0) {
			buff.val := current
			buff.fail := 0
		} else {
			if (++buff.fail < 10)
				current := buff.val
			else
				buff.val := 0
		}
		return current
	}

	DetectBlooms(name) {
		mode := this.modes[name]
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok
			return -1
		region := win.x "|" win.y + State.offsetY + 36 "|" win.w "|" 38
		pBMScreen := FrameCache.Get(region)
		if !pBMScreen
			return -1
		if (Gdip_ImageSearch(pBMScreen, bitmaps["buff"][name], &loc, mode.x1, mode.y1, mode.x2, mode.y2, mode.var) != 1)
			return -1
		foundX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
		slotX := Floor(foundX / 38) * 38
		; verify that it's an actual bloom by doing the "percentage" stuff,
		return this.MeasureBuff(pBMScreen, slotX, mode.col, name)
	}

	MeasureBuff(pBitmap, slotX, color, name) {
		if !this.bloomStates.Has(name)
			this.bloomStates[name] := {val: 0, fail: 0}
		state := this.bloomStates[name]
		scanX := slotX + 6

		if !this.inRange(Gdip_GetPixel(pBitmap, scanX, 37), color) {
			if (++state.fail < 15)
				return state.val
			return 0
		}

		state.fail := 0
		low := 0, high := 35
		while (low < high) {
			mid := Floor((low + high) / 2)
			if this.inRange(Gdip_GetPixel(pBitmap, scanX, mid), color)
				high := mid
			else
				low := mid + 1
		}
		return Round((36 - low) / 36, 2)
	}

	inRange(pixel, color, tolerance := 100) {
		r := (pixel >> 16) & 0xFF
		g := (pixel >> 8) & 0xFF
		b := pixel & 0xFF

		cr := (color >> 16) & 0xFF
		cg := (color >> 8) & 0xFF
		cb := color & 0xFF

		return (Abs(r - cr) <= tolerance) && (Abs(g - cg) <= tolerance) && (Abs(b - cb) <= tolerance)
	}

	DetectNumber(pBitmap, slot) {
		searchX := slot * 40
		searchY := 22
		searchW := 34
		searchH := 11

		found := []

		loop 10 {
			idx := 10 - A_Index

			if (Gdip_ImageSearch(pBitmap, bitmaps["buff"][idx], &loc1, searchX, searchY, searchX + searchW, searchY + searchH, 6) = 1) {
				mX := SubStr(loc1, 1, InStr(loc1, ",") - 1)
				currentWidth := this.numOffset[idx]

				isOverlap := false
				for item in found {
					if (mX >= item.x && mX < item.x + item.w - 1) {
						isOverlap := true
						break
					}
					if (item.x >= mX && item.x < (mX + currentWidth - 1)) {
						isOverlap := true
						break
					}
				}
				if (!isOverlap) {
					found.Push({ num: idx, x: Integer(mX), w: currentWidth })
					if (Gdip_ImageSearch(pBitmap, bitmaps["buff"][idx], &loc2, mX + currentWidth - 1, searchY, searchX + searchW, searchY + searchH, 6) = 1) {
						mX2 := SubStr(loc2, 1, InStr(loc2, ",") - 1)
						found.Push({ num: idx, x: Integer(mX2), w: currentWidth })
					}
				}
			}
		}

		if (found.Length = 0) {
			return 0
		} else if (found.Length = 1) {
			return found[1].num
		} else {
			if (found[1].x < found[2].x) {
				return found[1].num . found[2].num
			} else {
				return found[2].num . found[1].num
			}
		}
	}

	DetectBuffNum(x, y, pBitmap, numType := "big") {
		offsets := (numType = "big") ? bigOffset : tinyOffset
		found := []
		priorityOrder := [8, 0, 6, 9, 4, 7, 2, 3, 5, 1]
		sX := x - 13
		sY := 0
		sW := sX + 38
		sH := 32
		for idx in priorityOrder {
			currentX := sX
			while (Gdip_ImageSearch(pBitmap, bitmaps["buff"][numType][idx], &loc, currentX, sY, sW, sH, , , 6)) {
				
				mX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				isOverlap := false
				for item in found {
					if (mX >= item.x && mX < item.x + item.w) || (item.x >= mX && item.x < mX + offsets[idx]) {
						isOverlap := true
						break
					}
				}
				if !isOverlap {
					found.Push({num: idx, x: mX, w: offsets[idx]})
				}
				currentX := mX + offsets[idx]
				if (currentX >= sW)
					break
			}
		}
		if (found.Length = 0)
			return 0
		Loop found.Length {
			i := A_Index
			Loop found.Length - i {
				j := i + A_Index
				if (found[i].x > found[j].x) {
					temp := found[i]
					found[i] := found[j]
					found[j] := temp
				}
			}
		}
		result := ""
		for item in found
			result .= item.num
		return Integer(result)
	}

	DetectGumdrops() {
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok
			return this.GummyStar.pity

		if this.DetectPassive("gummystar") = -1 {
			this.GummyStar.pity := 0
			return -1
		}

		region := win.x + (win.w // 2) - 261 "|" win.y + win.h - 102 "|517|68"
		pBMScreen := FrameCache.Get(region)
		if !pBMScreen
			return this.GummyStar.pity
		
		if (this.GummyStar.slot = -1) {
			if (Gdip_ImageSearch(pBMScreen, bitmaps["buff"]["gumdrop"], &loc, , , , , 5) = 1) {
				foundX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				this.GummyStar.slot := Floor(foundX / 75) ; 0 is slot 1
			} else {
				return this.GummyStar.pity
			}
		}

		xOff := this.GummyStar.slot * 75
		xSize := xOff + 5
		yOff := 15
		ySize := yOff + 38

		if (Gdip_ImageSearch(pBMScreen, bitmaps["buff"]["unused_slot"], &loc, xOff, yOff, xSize, ySize, 5) = 0) {
			if A_TickCount - this.GummyStar.lastUse >= 2010 {
				this.GummyStar.pity++
				this.GummyStar.lastUse := A_TickCount
			}

			if (this.GummyStar.pity >= 75) {
				this.GummyStar.pity := 0
			}
		}		
		return this.GummyStar.pity
	}

	RefreshConfig() {
		this.PassiveList := StrSplit(Config.Get("Tracker", "Passives", "scorch"), "|")
	}
}
