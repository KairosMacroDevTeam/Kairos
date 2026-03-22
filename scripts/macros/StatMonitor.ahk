class StatMonitor {
	__New() {
		this.logs := [] ; {time (unix or A_TickCount):, data: (what was detected basically)}
		this.previousBuffs := Map() ; basically for "safety" since detection isn't perfect.
		this.currentBuffs := Map()
		this.isRunning := false

		this.scanStartTime := 0
		this.sessionStartHoney := 0
		this.learningPeriod := 50000 ; guaranteed out of cooldown for passives
		this.confirmedPassives := []
		this.possiblePassives := ["scorching_star", "pop_star", "gummy_star"]

		this.buff_groups := Map(
			"boost_red", "boost"
			, "boost_blue", "boost"
			, "boost_white", "boost"

			, "focus", "crit"
			, "precision", "crit"

			, "honey_mark", "mark"
			, "pollen_mark", "mark"
		)

		this.wall_buffs := Map(
			"sticker_stack", 1
			, "balloon_blessing", 1
			, "clock", 1
			, "mondo", 1
			, "puffshroom_blessing", 1
			, "robo_party", 1
			, "cool_breeze", 1
			, "comforting", 1
			, "motivating", 1
			, "satisfying", 1
			, "refreshing", 1
			, "invigorating", 1
			, "festive_nymph", 1
			, "bubble_bloat", 1
			, "tide_blessing", 1
		)

		this.buff_limits := Map(
			"comforting", 100
			, "motivating", 100
			, "satisfying", 100
			, "refreshing", 100
			, "invigorating", 100
			, "sticker_stack", 300
			, "balloon_blessing", 100
			, "puffshroom_blessing", 100
			, "robo_party", 100
			, "cool_breeze", 100
			, "festive_nymph", 250
			, "map_corruption", 100
			, "reindeer_guidance", 10
			, "dark_heat", 999
			, "clock", 5 
			, "mondo", 10 
			, "boost_red", 10
			, "boost_blue", 10
			, "boost_white", 10
			, "focus", 10
			, "haste", 10
			, "precision", 10
			, "bomb", 10
			, "inspire", 100
			, "rage", 4
			, "balloon_aura", 10
			, "coconut_combo", 100
			, "honey_mark", 3
			, "pollen_mark", 3
			, "precise_mark", 3
			, "bubble_bloat", 6
			, "tide_blessing", 1.2
			, "flame_heat", 2
		)

		this.active_render_order := [ ; possibly make the generic ones ordered here
			"boost"
			, "haste"
			, "crit"
			, "bomb"
			, "inspire"
			, "coconut_combo"
			, "map_corruption"
			, "reindeer_guidance"
			, "rage"
			, "flame_heat"
			, "dark_heat"
			, "balloon_aura"
			, "mark"
			, "precise_mark"
		]

		this.onoff_render_order := [
			"pop_star"
			, "scorching_star"
			, "gummy_star"

			, "guiding_star"
			, "bear_morph"
			, "melody"
			, "baby_love"

			, "tabby_blessing"
			, "festive_blessing"
			, "beesmas_cheer"
			, "festive_mark"
			, "bomb_sync_blue"
			, "bomb_sync_red"
			, "clouds"
			, "jellybean_sharing"
			, "flame_fuel"
			
			, "super_smoothie"
			, "purple_potion"
			, "marshmallow_bee"
			, "extract_blue"
			, "extract_red"
			, "oil"
			, "enzyme"
			, "glue"
			, "tropical_drink"
			, "stingers"
		]

		this.wall_render_order := [
			"balloon_blessing"
			, "puffshroom_blessing"
			, "sticker_stack"
			, "robo_party"
			, "mondo"
			, "clock"
			, "festive_nymph"
			, "cool_breeze"
			, "bubble_bloat"
			, "tide_blessing"
		]

		this.buff_colors := Map(
			"boost_red", 0xFFE46156
			, "boost_blue", 0xFF56A4E4
			, "boost_white", 0xFFFFFFFF
			, "focus", 0xFF22FF06
			, "haste", 0xFFF0F0F0
			, "bomb", 0xFFA0A0A0
			, "balloon_aura", 0xFF3350C3
			, "inspire", 0xFFF5F616
			, "precision", 0xFF8F4EB4
			, "reindeer_guidance", 0xFFCC2C2C
			, "honey_mark", 0xFFFFD119
			, "pollen_mark", 0xFFFFE994
			, "precise_mark", 0xFF8F4EB4
			, "festive_mark", 0xFF3D713B
			, "pop_star", 0xFF0096FF
			, "melody", 0xFFF0F0F0
			, "bear_morph", 0xFFB26F3E
			, "baby_love", 0xFF8CE3F4
			, "jellybean_sharing", 0xFFF8CCFD
			, "guiding_star", 0xFFF3ECEC
			, "bag", 0xFF56A4E4
			, "oil", 0xFFFEC650
			, "super_smoothie", 0xFFFEC650
			, "bomb_sync_red", 0xFFE74C3C
			, "bomb_sync_blue", 0xFF3498DB
			, "festive_blessing", 0xFF17B62E
			, "beesmas_cheer", 0xFF17B62E
			, "tabby_blessing", 0xFFF99D28
			, "clouds", 0xFFECF0F1
			, "flame_fuel", 0xFFCF2013
			, "flame_heat", 0xFFCF1F14
			, "stinger", 0xFFFF0100
			, "enzyme", 0xFFFEC650
			, "extract_red", 0xFFFEC650
			, "extract_blue", 0xFFFEC650
			, "glue", 0xFFFEC650
			, "tropical_drink", 0xFFFEC650
			, "purple_potion", 0xFFFEC650
			, "marshmallow_bee", 0xFFFEC650
			, "rage", 0xFFE77B0B
			, "clock", 0xFFE2AC35
			, "mondo", 0xFFD4AC0D
			, "map_corruption", 0xFFEC19EB
			, "cool_breeze", 0xFFAED6F1
			, "sticker_stack", 0xFFD9D9D9
			, "puffshroom_blessing", 0xFFBE9A68
			, "robo_party", 0xFF3DA341
			, "dark_heat", 0xFF8F4EB4
			, "coconut_combo", 0xFF88633E
			, "balloon_blessing", 0xFF3350C3
			, "festive_nymph", 0xFF47AC53
			, "scorching_star", 0xFFFF3400
			, "gummy_star", 0xFFF191FF
			, "bubble_bloat", 0xFF4880CC
			, "tide_blessing", 0xFF91C2FD
			
		)

		this.ocr_enabled := true
		this.ocr_language := ""
		for k,v in Map("Windows.Globalization.Language","{9B0252AC-0C27-44F8-B792-9793FB66C63E}", "Windows.Graphics.Imaging.BitmapDecoder","{438CCB26-BCEF-4E95-BAD6-23A822E58D01}", "Windows.Media.Ocr.OcrEngine","{5BFFA85A-3384-3540-9940-699120D428A8}") {
			CreateHString(k, &hString)
			GUID := Buffer(16)
			DllCall("ole32\CLSIDFromString", "WStr", v, "Ptr", GUID)
			result := DllCall("Combase.dll\RoGetActivationFactory", "Ptr", hString, "Ptr", GUID, "PtrP", &pClass:=0)
			DeleteHString(hString)
			if (result != 0) {
				this.ocr_enabled := false
				break
			}
		}
		if (this.ocr_enabled = 1) {
			list := ocr("ShowAvailableLanguages")
			for lang in ["en-", "ko"] {
				Loop Parse list, "`n", "`r" {
					if (InStr(A_LoopField, lang) = 1) {
						this.ocr_language := A_LoopField
						break 2
					}
				}
			}
			if (this.ocr_language = "") {
				if ((this.ocr_language := SubStr(list, 1, InStr(list, "`n") - 1)) = "") {
					this.ocr_enabled := false
				}
			}
		}
	}

	Toggle() {
		if !Config.Get("Main", "StatMonitorEnabled", 0)
			return
		this.isRunning := true
		if (this.scanStartTime = 0)
			this.scanStartTime := A_TickCount
		SetTimer(this.RunScan.Bind(this), 1000)
	}

	Pause() {
		this.isRunning := false
		SetTimer(this.RunScan.Bind(this), 0)
		ToolTip(,,, 20)
	}

	Cleanup() {
		this.Pause()
	}

	RunScan() {
		if (!this.isRunning)
			return
		this.DetectBuffs()
		current_bag := this.DetectBag()
		current_honey := this.DetectHoney()

		if (current_honey = 0 && this.logs.Length > 0)
			current_honey := this.logs[this.logs.Length]["honey"]
		if (this.sessionStartHoney = 0 && current_honey > 0)
			this.sessionStartHoney := current_honey

		snapshot := Map()
		snapshot["time"] := A_TickCount
		snapshot["bag"] := current_bag
		snapshot["honey"] := current_honey
		snapshot["buffs"] := this.currentBuffs.Clone()

		this.logs.Push(snapshot)
		if (this.logs.Length >= 3600) { ; 1 hour limit, it'll probably be better if it exports and starts at 0
			this.Export()
		}
	}

	PrintOutput() {
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok 
			return
		out := "MONITOR`n"
		count := 0
		for buff, val in this.currentBuffs {
			if (val) {
				out .= buff ": " val "`n"
				count++
			}
		}
		if (count = 0) {
			out .= "No buffs detected."
		}
		ToolTip(out, win.x + 350, win.y + State.offsetY + 60, 20)
	}

	GenerateData() {
		this.logs := []
		starTime := this.scanStartTime := A_TickCount

		onOffList := ["oil", "super_smoothie", "bomb_sync_red", "bomb_sync_blue", "festive_blessing", "beesmas_cheer",
					"tabby_blessing", "clouds", "baby_love", "festive_mark", "flame_fuel", "guiding_star", "stinger", "enzyme",
					"extract_red", "extract_blue", "glue", "tropical_drink", "purple_potion", "marshmallow_bee", "jellybean_sharing",
					"bear_morph", "melody", "pop_star", "scorching_star", "gummy_star"]
		
		digitList := ["focus", "bomb", "rage", "inspire", "balloon_aura", "clock", "honey_mark", "pollen_mark",
					"precise_mark", "reindeer_guidance", "mondo", "map_corruption", "cool_breeze", "precision", "sticker_stack",
					"puffshroom_blessing", "robo_party", "dark_heat", "coconut_combo", "balloon_blessing", "haste", "boost_red",
					"boost_blue", "boost_white", "festive_nymph", "bubble_bloat", "tide_blessing", "flame_heat"]

		genOnOff := []
		genDigit := []

		for i in onOffList{
			if (Random(0, 2) = 1)
				genOnOff.Push(i)
		}

		for i in digitList{
			if (Random(0, 1) = 1)
				genDigit.Push(i)
		}

		startHoney := this.sessionStartHoney := Random(100000000000, 999999999999) * 10
		honey_values := Map(0, startHoney)

		com := Random(0, 100)
		mot := Random(0, 100)
		sat := Random(0, 100)
		ref := Random(0, 100)
		inv := Random(0, 100)

				this.wall_render_order := [
			"balloon_blessing"
			, "puffshroom_blessing"
			, "sticker_stack"
			, "robo_party"
			, "mondo"
			, "clock"
			, "festive_nymph"
			, "cool_breeze"
			, "bubble_bloat"
			, "tide_blessing"
		]

		stack := Random(1, 290)
		blessing := Random(1, 100)
		clock := Random(1, 5)
		mondo := Random(1, 10)
		puff := Random(1, 100)
		flake := Random(1, 100)
		robo := Random(1, 100)
		nymph := Random(1, 100)
		bloat := Round(Random(1.0, 6.0), 2)
		tide := Round(Random(1.0, 1.2), 2)



		loop 3600 {
			tick := A_Index
			snapshot := Map()
			snapshot["time"] := starTime + (tick * 1000)
			snapshot["bag"] := Round(Mod(tick, 60) * (100/60), 2)
			snapshot["honey"] := honey_values[tick-1] + ((Mod(tick, 100) < 50) ? Random(100000000, 999999999) : Random(1000000000, 10000000000))
			honey_values[tick] := snapshot["honey"]

			buffs := Map()

			for i, buffName in onOffList {
				cycleLength := 40 + Mod(i * 13, 60) 
				uptime := cycleLength * 0.6
				offset := i * 7
				buffs[buffName] := Mod(tick + offset, cycleLength) < uptime ? 1 : 0
			}

			for i, buffName in digitList {
				waveSpeed := 10 + Mod(i * 3, 30)
				offset := i * 5
				sineValue := Sin((tick + offset) / waveSpeed)
				val := Round((sineValue + 1) * 5)
				if (val < 0)
					val := 0
				if (val > 10)
					val := 10
				buffs[buffName] := val
			}

			buffs["comforting"] := com
			buffs["motivating"] := mot
			buffs["satisfying"] := sat
			buffs["refreshing"] := ref
			buffs["invigorating"] := inv
			buffs["sticker_stack"] := stack
			buffs["balloon_blessing"] := blessing
			buffs["clock"] := clock
			buffs["mondo"] := mondo
			buffs["puffshroom_blessing"] := puff
			buffs["robo_party"] := robo
			buffs["cool_breeze"] := flake
			buffs["festive_nymph"] := nymph
			buffs["bubble_bloat"] := bloat
			buffs["tide_blessing"] := tide

			snapshot["buffs"] := buffs
			this.logs.Push(snapshot)
		}
	}

; this will graph out based off the time, so the "res" of the graph might vary.
	DrawGraph(path?) {
		if (this.logs.Length < 2)
			return

		for index, snap in this.logs {
			if (index > 1 && index < this.logs.Length) {
				prevH := this.logs[index-1]["honey"]
				currH := snap["honey"]

				nextIdx := index + 1
				nextH := this.logs[nextIdx]["honey"]
				while (nextH == currH && nextIdx < this.logs.Length) {
					nextIdx++
					nextH := this.logs[nextIdx]["honey"]
				}
				if (currH > prevH && currH > nextH && (currH - nextH) > (currH * 0.01))
					snap["honey"] := prevH
				else if (currH < prevH && currH < nextH && (prevH - currH) > (prevH * 0.01))
					snap["honey"] := prevH
			}
		}

		for index, snap in this.logs {
			if (index = 1) {
				snap["honey_sec"] := 0
			} else {
				prevSnap := this.logs[index - 1]
				timeDiff := (snap["time"] - prevSnap["time"]) / 1000
				honeyDiff := snap["honey"] - prevSnap["honey"]
				if (timeDiff > 0 && honeyDiff >= 0) {
					snap["honey_sec"] := honeyDiff / timeDiff
				} else {
					snap["honey_sec"] := 0
				}
			}
		}

		peakHoney := 10
		for index, snap in this.logs {
			sum := 0
			count := 0
			loop 10 {
				checkIdx := index - A_Index + 1
				if (checkIdx > 0) {
					sum += this.logs[checkIdx]["honey_sec"]
					count++
				}
			}
			snap["honey_sec_smoothed"] := count > 0 ? sum / count : snap["honey_sec"]

			if (snap["honey_sec_smoothed"] > peakHoney)
				peakHoney := snap["honey_sec_smoothed"]
		}
		
		canvasW := 800
		canvasH := 600
		padding := 10

		; Find out what buffs we had active.
		hasHoney := false
		activeDigitGroups := Map()
		activeOnOffBuffs := Map()

		for index, snapshot in this.logs {
			if (snapshot["honey"] > 0 || snapshot["bag"] > 0) {
				hasHoney := true
			}

			for buff, val in snapshot["buffs"] {
				if (val) {
					if (this.wall_buffs.Has(buff))
						continue
					if (this.IsOnOff(buff)) {
						activeOnOffBuffs[buff] := true
					} else if (this.IsDigit(buff)) {
						groupName := this.buff_groups.Has(buff) ? this.buff_groups[buff] : buff
						if (!activeDigitGroups.Has(groupName))
							activeDigitGroups[groupName] := Map()
						activeDigitGroups[groupName][buff] := true
					}
				}
			}
		}

		; dynamic layout
		leftPanelW := 1800
		rightPanelW := 440
		padding := 20

		onOffCount := 0
		for k, v in activeOnOffBuffs
			onOffCount++
		onOffHeight := onOffCount > 0 ? (onOffCount * 40) + 40 : 0

		groupCount := activeDigitGroups.Count
		bagHeight := 130
		honeyHeight := 200
		sectionH := 120
		
		currentY := padding


		honeyRect := {}
		bagRect := {}
		groupRects := []
		bottomRect := {}

		if (hasHoney) {
			honeyRect := {x: padding, y: currentY, w: leftPanelW, h: honeyHeight}
			currentY += honeyHeight + padding

			bagRect := {x: padding, y: currentY, w: leftPanelW, h: bagHeight}
			currentY += bagHeight + padding

			formattedPeak := this.FormatNumber(peakHoney)
		}
		if (groupCount > 0) {
			for index, expectedGroup in this.active_render_order {
				if (activeDigitGroups.Has(expectedGroup)) {
					buffsInGroup := activeDigitGroups[expectedGroup]
					groupRects.Push({name: expectedGroup, rect: {x: padding, y: currentY, w: leftPanelW, h: sectionH}, buffs: buffsInGroup})
					currentY += sectionH + padding
					activeDigitGroups.Delete(expectedGroup)
				}
			}
			for leftoverGroup, buffsInGroup in activeDigitGroups {
				groupRects.Push({name: leftoverGroup, rect: {x: padding, y: currentY, w: leftPanelW, h: sectionH}, buffs: buffsInGroup})
				currentY += sectionH + padding
			}
		}
		if (onOffCount > 0) {
			bottomRect := {x: padding, y: currentY, w: leftPanelW, h: onOffHeight}
			currentY += onOffHeight + padding
		}

		lastSnap := this.logs[this.logs.Length]
		passiveCount := 0
		for buffName, val in lastSnap["buffs"]
			if (val && this.wall_buffs.Has(buffName) && !(buffName ~= "comforting|motivating|satisfying|refreshing|invigorating") && bitmaps.Has("stat_icon") && bitmaps["stat_icon"].Has(buffName))
				passiveCount++

		passiveRows := Ceil(passiveCount / 4)
		minRightPanelH := 1050 + (passiveRows * 112) + (padding * 2)

		canvasW := leftPanelW + rightPanelW + (padding * 3)
		canvasH := currentY

		if (canvasH < minRightPanelH)
			canvasH := minRightPanelH
		rightRect := {x: leftPanelW + (padding * 2), y: padding, w: rightPanelW, h: canvasH - (padding * 2)}

		; drawing
		pBitmapCanvas := Gdip_CreateBitmap(canvasW, canvasH)
		pGraphic := Gdip_GraphicsFromImage(pBitmapCanvas)
		Gdip_SetSmoothingMode(pGraphic, 4)

		pBrushBg := Gdip_CreateLineBrushFromRect(0, 0, canvasW, canvasH, 0xFF180c2e, 0xFF11103d, 2)
		Gdip_FillRoundedRectangle(pGraphic, pBrushBg, 0, 0, canvasW, canvasH, 15)
		Gdip_DeleteBrush(pBrushBg)

		if (honeyRect.HasOwnProp("x")) {
			GraphLeftOffset := 120
			topPadding := 36

			hInner := {x: honeyRect.x + graphLeftOffset, y: honeyRect.y + topPadding, w: honeyRect.w - graphLeftOffset, h: honeyRect.h - topPadding}
			bInner := {x: bagRect.x + graphLeftOffset, y: bagRect.y + topPadding, w: bagRect.w - graphLeftOffset, h: bagRect.h - topPadding}

			Gdip_TextToGraphics(pGraphic, "Honey/Sec", "s22 Center Bold cFFFFD119 x" hInner.x " y" honeyRect.y + (honeyRect.h / 2) - 110, "Segoe UI", hInner.w)
			Gdip_TextToGraphics(pGraphic, "Capacity", "s22 Center Bold cFF56A4E4 x" bInner.x " y" bagRect.y + (bagRect.h / 2) - 70, "Segoe UI", bInner.w)

			Gdip_TextToGraphics(pGraphic, formattedPeak " honey/s", "s20 Right cFFFFD119 x" 0 " y" honeyRect.y + 2, "Segoe UI", graphLeftOffset - 8)
			Gdip_TextToGraphics(pGraphic, "100%", "s20 Right cFF56A4E4 x" bagRect.x " y" bInner.y, "Segoe UI", graphLeftOffset - 8)
			
			this.DrawLineGraphWithGradient(pGraphic, hInner, "honey_sec_smoothed", 0xFFFCB130, false)
			this.DrawLineGraphWithGradient(pGraphic, bInner, "bag", this.buff_colors["bag"], false)

			pPenGrid := Gdip_CreatePen(0x40FFFFFF, 1)
			Gdip_DrawLine(pGraphic, pPenGrid, hInner.x, hInner.y, hInner.x + hInner.w, hInner.y)
			Gdip_DeletePen(pPenGrid)
		}
		for item in groupRects {
			this.DrawMidGraph(pGraphic, item.rect, item.name, item.buffs)
		}
		if (bottomRect.HasOwnProp("x")) {
			this.DrawBottomGraph(pGraphic, bottomRect, activeOnOffBuffs)
		}
		this.DrawRightPanel(pGraphic, rightRect)
		
		; Save/Dispose
		if (!IsSet(path)) {
			dateFolder := FormatTime(A_Now, "yyyy-MM-dd")
			timeStr := FormatTime(A_Now, "HH-mm-ss")
			dirPath := A_ScriptDir "\..\graphs\" dateFolder
			if !DirExist(dirPath)
				DirCreate(dirPath)
			path := dirPath "\graph_" timeStr ".png"
			txtPath := dirPath "\data_" timeStr ".txt"
			this.ExportData(txtPath)
		} else {
			txtPath := StrReplace(path, ".png", ".txt")
			this.ExportData(txtPath)
		}
		Gdip_SaveBitmapToFile(pBitmapCanvas, path, 100)
		Gdip_DeleteGraphics(pGraphic)
		Gdip_DisposeImage(pBitmapCanvas)
		this.logs := []
	}

	ExportData(path?) {
		if (this.logs.Length = 0)
			return
		if (!IsSet(path)) {
			timeStr := FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss")
			path := A_ScriptDir "\export_" timeStr ".txt"
		}
		out := "RAW DATA OF DETECTION `n====================`n"
		for index, snap in this.logs {
			out .= "Time: " snap["time"] " | Honey: " snap["honey"] " | Bag: " snap["bag"] "%`n"
			out .= "Buffs: "
			buffCount := 0
			for buff, val in snap["buffs"] {
				if (val > 0) {
					out .= buff ": " val ", "
					buffCount++
				}
			}
			if (buffCount > 0)
				out := RTrim(out, ", ")
			else
				out .= "None"
			out .= "`n--------------------`n"
		}
		if FileExist(path)
			FileDelete(path)
		FileAppend(out, path, "UTF-8")
		;Run("notepad.exe " path)
	}

	DrawMidGraph(pGraphic, rect, groupName, groupBuffs) {
		iconColW := 90
		totalOffset := 120

		iconSize := Min(64, rect.h - 20)
		iconX := rect.x + (iconColW / 2) - (iconSize / 2)
		iconY := rect.y + (rect.h / 2) - (iconSize / 2)

		groupMax := 0
		for buffName, isActive in groupBuffs {
			limit := this.buff_limits.Has(buffName) ? this.buff_limits[buffName] : 5
			peak := 0
			for index, snap in this.logs {
				val := snap["buffs"].Has(buffName) ? snap["buffs"][buffName] : 0
				if (val > peak)
					peak := val
			}
			if (peak > limit)
				peak := limit
			if (peak > groupMax)
				groupMax := peak
		}

		if (bitmaps["stat_icon"].Has(groupName) && bitmaps["stat_icon"][groupName] > 0) {
			Gdip_DrawImage(pGraphic, bitmaps["stat_icon"][groupName], iconX, iconY, iconSize, iconSize)
		} else {
			shortName := SubStr(groupName, 1, 5)
			Gdip_TextToGraphics(pGraphic, shortName, "s14 Center Bold cFF888888 x" rect.x " y" iconY + (iconSize / 2) - 6, "Segoe UI", iconColW)
		}

		textY := iconY + iconSize + 5
		Gdip_TextToGraphics(pGraphic, "x0 - " groupMax, "s14 Center Bold cFF888888 x" rect.x " y" textY, "Segoe UI", iconColW)

		topPadding := 10
		innerRect := {x: rect.x + totalOffset, y: rect.y + topPadding, w: rect.w - totalOffset - 20, h: rect.h - topPadding}

		pPenGrid := Gdip_CreatePen(0x40FFFFFF, 1)
		Gdip_DrawLine(pGraphic, pPenGrid, innerRect.x, innerRect.y - 15, innerRect.x + innerRect.w, innerRect.y - 15)
		Gdip_DeletePen(pPenGrid)

		for buffName, isActive in groupBuffs {
			colorHex := this.buff_colors.Has(buffName) ? this.buff_colors[buffName] : 0xFFFFFFFF
			this.DrawLineGraphWithGradient(pGraphic, innerRect, buffName, colorHex, true, groupMax)
		}
	}

	DrawBottomGraph(pGraphic, rect, activeBuffs) {
		if (this.logs.Length < 2)
			return

		onOffCount := 0
		for k, v in activeBuffs
			onOffCount++
		if (onOffCount = 0)
			return
		
		rowHeight := (rect.h - 40) / onOffCount

		iconColW := 90
		totalOffset := 120

		logCount := this.logs.Length
		graphW := rect.w - totalOffset - 20
		segmentW := (rect.w - totalOffset) / (logCount - 1)

		orderedBuffs := []
		tempBuffs := activeBuffs.Clone()
		if (this.HasOwnProp("onoff_render_order")) {
			for index, expectedBuff in this.onoff_render_order {
				if (tempBuffs.Has(expectedBuff) && tempBuffs[expectedBuff]) {
					orderedBuffs.Push(expectedBuff)
					tempBuffs.Delete(expectedBuff)
				}
			}
		}
		for buffName, isActive in tempBuffs {
			if (isActive)
				orderedBuffs.Push(buffName)
		}

		rowIndex := 0
		for index, buffName in orderedBuffs {
			rowY := rect.y + 40 + (rowIndex * rowHeight)
			drawH := rowHeight - 4

			iconSize := Min(56, rowHeight - 4)
			iconX := rect.x + (iconColW / 2) - (iconSize / 2)
			iconY := rowY + (rowHeight / 2) - (iconSize / 2)

			if (bitmaps.Has("stat_icon") && bitmaps["stat_icon"].Has(buffName)) {
				Gdip_DrawImage(pGraphic, bitmaps["stat_icon"][buffName], iconX, iconY, iconSize, iconSize)
			} else {
				shortName := SubStr(buffName, 1, 5)
				Gdip_TextToGraphics(pGraphic, shortName, "s18 Center Bold cFF888888 x" rect.x " y" iconY + (iconSize / 2) - 6, "Segoe UI", iconColW)
			}

			colorHex := this.buff_colors.Has(buffName) ? this.buff_colors[buffName] : 0xFFFFFFFF
			pBrush := Gdip_BrushCreateSolid(colorHex)

			isDrawing := false
			startX := 0

			for index, snap in this.logs {
				val := snap["buffs"].Has(buffName) ? snap["buffs"][buffName] : 0
				currentX := rect.x + totalOffset + ((index - 1) * segmentW)
				if (val) {
					if (!isDrawing) {
						isDrawing := true
						startX := currentX
					}
				} else {
					if (isDrawing) {
						isDrawing := false
						Gdip_FillRectangle(pGraphic, pBrush, startX, rowY, currentX - startX, drawH)
					}
				}
			}
			if (isDrawing) {
				Gdip_FillRectangle(pGraphic, pBrush, startX, rowY, (rect.x + totalOffset + graphW) - startX, drawH)
			}
			Gdip_DeleteBrush(pBrush)
			rowIndex++
		}
	}

	DrawRightPanel(pGraphic, rect) {
		if (this.logs.Length = 0)
			return
	
		lastSnap := this.logs[this.logs.Length]

		pBrushBg := Gdip_CreateLineBrushFromRect(0, 0, rect.w, rect.h, 0xFF0E071A, 0xFF220d42, 1, 1)
		Gdip_FillRoundedRectangle(pGraphic, pBrushBg, rect.x, rect.y, rect.w, rect.h, 20)
		Gdip_DeleteBrush(pBrushBg)

		Gdip_TextToGraphics(pGraphic, "Current Stats", "s32 Center Bold cFFFFFFFF x" rect.x " y" rect.y + 20, "Segoe UI", rect.w)

		currentY := rect.y + 80
		iconSize := 64
		padding := 20

		currentY += this.DrawSessionBlock(pGraphic, rect, currentY)
		pPenLineSession := Gdip_CreatePen(0xFF555555, 2)
		Gdip_DrawLine(pGraphic, pPenLineSession, rect.x + 20, currentY, rect.x + rect.w - 20, currentY)
		Gdip_DeletePen(pPenLineSession)
		currentY += 20

		Gdip_TextToGraphics(pGraphic, "STATIC BUFFS", "s24 Center Bold cFFAAAAAA x" rect.x " y" currentY, "Segoe UI", rect.w)
		currentY += 50

		iconW := 83
		spacing := 18
		maxPerRow := 4

		activeStaticBuffs := []
		for buffName, val in lastSnap["buffs"] {
			if (!val || !this.wall_buffs.Has(buffName))
				continue
			if (buffName ~= "comforting|motivating|satisfying|refreshing|invigorating")
				continue
			if (bitmaps.Has("stat_icon") && bitmaps["stat_icon"].Has(buffName))
				activeStaticBuffs.Push(buffName)
		}

		totalItems := activeStaticBuffs.Length
		if (totalItems > 0) {
			rowIndex := 0
			while ((rowIndex * maxPerRow) < totalItems) {
				itemsInRow := Min(maxPerRow, totalItems - (rowIndex * maxPerRow))
				rowWidth := (itemsInRow * iconW) + ((itemsInRow - 1) * spacing)
				startX := rect.x + (rect.w / 2) - (rowWidth / 2)
				gridX := startX

				loop itemsInRow {
					itemIdx := (rowIndex * maxPerRow) + A_Index
					buffName := activeStaticBuffs[itemIdx]
					peakVal := 0
					for index, snap in this.logs {
						if (snap["buffs"].Has(buffName) && snap["buffs"][buffName] > peakVal)
							peakVal := snap["buffs"][buffName]
					}
					textStr := ""
					if (this.isDigit(buffName))
						textStr := "x" peakVal
					else if (!this.IsOnOff(buffName))
						textStr := peakVal "%"
					Gdip_DrawImage(pGraphic, bitmaps["stat_icon"][buffName], gridX, currentY, iconW, iconW)
					if (textStr != "")
						Gdip_TextToGraphics(pGraphic, textStr, "s18 Center Bold cFFFFFFFF x" (gridX - 10) " y" (currentY + iconW + 4), "Segoe UI", iconW + 20)
					gridX += iconW + spacing
				}
				currentY += iconW + 40
				rowIndex++
			}
		}

		currentY += 15
		pPenLine3 := Gdip_CreatePen(0xFF555555, 2)
		Gdip_DrawLine(pGraphic, pPenLine3, rect.x + 20, currentY, rect.x + rect.w - 20, currentY)
		Gdip_DeletePen(pPenLine3)
		currentY += 20

		Gdip_TextToGraphics(pGraphic, "NECTARS", "s24 Center Bold cFFAAAAAA x" rect.x " y" currentY, "Segoe UI", rect.w)
		currentY += 60
		currentY += this.DrawNectarRings(pGraphic, rect, currentY)

		currentY += 20
		pPenLine4 := Gdip_CreatePen(0xFF555555, 2)
		Gdip_DrawLine(pGraphic, pPenLine4, rect.x + 20, currentY, rect.x + rect.w - 20, currentY)
		Gdip_DeletePen(pPenLine4)
		currentY += 30

		startTimeTick := this.logs[1]["time"]
		endTimeTick := lastSnap["time"]
		durationSec := (endTimeTick - startTimeTick) // 1000

		startTime := FormatTime(DateAdd(A_Now, -durationSec, "Seconds"), "HH:mm:ss")
		endTime := FormatTime(A_Now, "HH:mm:ss")
		date := FormatTime(A_Now, "yyyy-MM-dd")

		ocrStatus := this.ocr_enabled ? "Enabled (" this.ocr_language ")" : "Disabled"
		ver := "v" version
		os_ver := "n/a"
		for objItem in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_OperatingSystem")
			os_ver := Trim(StrReplace(StrReplace(StrReplace(StrReplace(objItem.Caption, "Microsoft"), "Майкрософт"), "مايكروسوفت"), "微软"))

		Gdip_TextToGraphics(pGraphic, "StatMonitor - Kairos " ver, "s23 Bold cffdbb35d x" (rect.x + 20) " y" currentY, "Segoe UI", rect.w - 40)
		currentY += 30

		currentX := rect.x + 20
		startW := StrSplit(Gdip_TextToGraphics(pGraphic, startTime, "s23 Bold cff5d70db x" (currentX) " y" currentY, "Segoe UI", rect.w - 40), "|")[3], currentX += startW
		arrowW := StrSplit(Gdip_TextToGraphics(pGraphic,"->", "s23 Bold cffc7c7c7 x" (currentX) " y" currentY, "Segoe UI", rect.w - 40), "|")[3], currentX += arrowW
		endW := StrSplit(Gdip_TextToGraphics(pGraphic, endTime, "s23 Bold cff4f52e2 x" (currentX) " y" currentY, "Segoe UI", rect.w - 40 - startW - arrowW), "|")[3], currentX += endW
		slashW := StrSplit(Gdip_TextToGraphics(pGraphic, " / ", "s23 Bold cffc7c7c7 x" (currentX) " y" currentY, "Segoe UI", rect.w - 40), "|")[3], currentX += slashW
		Gdip_TextToGraphics(pGraphic, date, "s23 Bold cffc540c5 x" (currentX) " y" currentY, "Segoe UI", rect.w - 40)

		currentY += 30
		col := this.ocr_enabled ? "cff44e4c1" : "cffaf2626"
		Gdip_TextToGraphics(pGraphic, "OCR: ", "s23 Bold cff943eb9 x" (rect.x + 20) " y" currentY, "Segoe UI", rect.w - 40)
		Gdip_TextToGraphics(pGraphic, ocrStatus, "s23 Bold " col " x" (rect.x + 85) " y" currentY, "Segoe UI", rect.w - 120)
		currentY += 30
		Gdip_TextToGraphics(pGraphic, "WIN VER: " os_ver, "s23 Bold cff5e5e5e x" (rect.x + 20) " y" currentY, "Segoe UI", rect.w - 40)
		currentY += 30
		Gdip_GetImageDimensions(bitmaps["stat_icon"]["watermark"], &imgW, &imgH)
		scaleFactor := Max(400 // imgW, 400 // imgH)
		Gdip_DrawImage(pGraphic, bitmaps["stat_icon"]["watermark"], rect.x + (rect.w / 2) - 200, currentY, imgW * scaleFactor, imgH * scaleFactor // 2)
	}

	DrawNectarRings(pGraphic, rect, startY) {
		static nectars := ["comforting", "motivating", "satisfying", "refreshing", "invigorating"]
		static colors := Map(
			"comforting", 0xFF7E9EB3,
			"motivating", 0xFF937DB3,
			"satisfying", 0xFFB398A7,
			"refreshing", 0xFF78B375,
			"invigorating", 0xFFB35951
		)
		lastSnap := this.logs[this.logs.Length]
		ringSize := 65
		penWidth := 10

		totalRingsWidth := 5 * ringSize
		remainingSpace := rect.w - totalRingsWidth
		spacing := remainingSpace / 6

		for index, nectar in nectars {
			val := lastSnap["buffs"].Has(nectar) ? lastSnap["buffs"][nectar] : 0
			hex := colors[nectar]
			trans := (hex & 0x00FFFFFF) | 0x40000000

			ringX := rect.x + (spacing * index) + (ringSize * (index - 1))

			pPenBg := Gdip_CreatePen(trans, penWidth)
			Gdip_DrawArc(pGraphic, pPenBg, ringX, startY, ringSize, ringSize, 0, 360)
			Gdip_DeletePen(pPenBg)

			if (val > 0) {
				pPenVal := Gdip_CreatePen(hex, penWidth)
				sweepAngle := (val / 100) * 360
				Gdip_DrawArc(pGraphic, pPenVal, ringX, startY, ringSize, ringSize, -90, sweepAngle)
				Gdip_DeletePen(pPenVal)
			}
			Gdip_TextToGraphics(pGraphic, val "%", "s17 Center Bold cFFFFFFFF x" ringX " y" (startY + (ringSize / 2) - 12), "Segoe UI", ringSize)
			name := Format("{1:Us}", SubStr(nectar, 1, 3))
			pBrushTxt := Gdip_BrushCreateSolid(hex)
			Gdip_TextToGraphics(pGraphic, name, "s17 Center Bold c" StrReplace(Format("{:08X}", hex), "0x", "") " x" ringX " y" (startY + ringSize + 10), "Segoe UI", ringSize)
			Gdip_DeleteBrush(pBrushTxt)
		}
		return ringSize + 40
	}

	DrawSessionBlock(pGraphic, rect, startY) {
		lastSnap := this.logs[this.logs.Length]
		currentHoney := lastSnap["honey"]

		startHoney := (this.sessionStartHoney > 0) ? this.sessionStartHoney : this.logs[1]["honey"]
		sessionHoney := currentHoney - startHoney

		if (sessionHoney < 0)
			sessionHoney := 0
				
		elapseSecs := (A_TickCount - this.scanStartTime) // 1000
		h := elapseSecs // 3600
		m := Mod(elapseSecs // 60, 60)
		s := Mod(elapseSecs, 60)
		timeStr := Format("{:02}:{:02}:{:02}", h, m, s)

		Gdip_TextToGraphics(pGraphic, "SESSION", "s24 Center Bold cFFAAAAAA x" rect.x " y" startY, "Segoe UI", rect.w)
		currentY := startY + 45

		leftPad := rect.x + 20
		rightW := rect.w - 40
		rowSpacing := 35
		graphHeight := 250

		Gdip_TextToGraphics(pGraphic, "Current Honey:", "s20 Bold cFFFFFFFF x" leftPad " y" currentY, "Segoe UI")
		Gdip_TextToGraphics(pGraphic, this.FormatNumber(currentHoney), "s20 Bold Right cFFFFFFFF x" leftPad " y" currentY, "Segoe UI", rightW)
		currentY += rowSpacing

		Gdip_TextToGraphics(pGraphic, "Session Honey:", "s20 Bold cFF41FF80 x" leftPad " y" currentY, "Segoe UI")
		Gdip_TextToGraphics(pGraphic, "+" this.FormatNumber(sessionHoney), "s20 Bold Right cFF41FF80 x" leftPad " y" currentY, "Segoe UI", rightW)
		currentY += rowSpacing

		Gdip_TextToGraphics(pGraphic, "Session Time:", "s20 Bold cFF56A4E4 x" leftPad " y" currentY, "Segoe UI")
		Gdip_TextToGraphics(pGraphic, timeStr, "s20 Bold Right cFF56A4E4 x" leftPad " y" currentY, "Segoe UI", rightW)
		currentY += rowSpacing

		Gdip_TextToGraphics(pGraphic, "Elapse Honey", "s20 Bold cffa3a3a3 x" leftPad " y" currentY, "Segoe UI")
		currentY += 30

		graphBg := Gdip_BrushCreateSolid(0x66000000)
		Gdip_FillRoundedRectangle(pGraphic, graphBg, leftPad, currentY, rightW, graphHeight, 10)
		Gdip_DeleteBrush(graphBg)
		if (this.logs.Length > 1) {
			baseHoney := (this.sessionStartHoney > 0) ? this.sessionStartHoney : this.logs[1]["honey"]

			maxGain := 0
			for index, entry in this.logs {
				gain := entry["honey"] - baseHoney
				if (gain < 0)
					gain := 0
				if (gain > maxGain)
					maxGain := gain
			}
			if (maxGain = 0)
				maxGain := 1
			labelX := leftPad
			labelW := 55
			padding := 10

			levels := [1.0, .75, .5, .25, 0.0]
			for i, percent in levels {
				val := baseHoney + (maxGain * percent)
				textVal := this.FormatNumber(val)
				labelY := (currentY + padding) + ((1 - percent) * (graphHeight - (padding * 2))) - 10
				Gdip_TextToGraphics(pGraphic, textVal, "s14 Bold Right cFFAAAAAA x" labelX " y" labelY, "Segoe UI", labelW)
			}

			gX := leftPad + labelW + 5
			gW := rightW - labelW - padding - 5
			gH := graphHeight - (padding * 2)
			bottomY := currentY + graphHeight - 10

			linePoints := []
			polyPoints := []

			polyPoints.Push([gX, bottomY])
			for index, entry in this.logs {
				x := gX + ((index-1) / (this.logs.Length-1) * gW)
				gain := entry["honey"] - baseHoney
				y := bottomY - ((gain / maxGain) * gH)
				if (y < currentY + padding)
					y := currentY + padding
				if (y > bottomY)
					y := bottomY
				linePoints.Push([x, y])
				polyPoints.Push([x, y])
			}
			polyPoints.Push([gX + gW, bottomY])

			pBrush := Gdip_CreateLineBrushFromRect(gX, currentY, gW, graphHeight, 0x6000FF00, 0x00000000, 1)
			Gdip_FillPolygon(pGraphic, pBrush, polyPoints)
			Gdip_DeleteBrush(pBrush)

			pPen := Gdip_CreatePen(0xFF41FF80, 2)
			Gdip_DrawLines(pGraphic, pPen, linePoints)
			Gdip_DeletePen(pPen)
		}
		return (currentY + graphHeight + 20) - startY
	}

	FormatNumber(num) {
		if (num >= 1000000000000000)
			return Round(num / 1000000000000000, 2) "q"
		else if (num >= 1000000000000)
			return Round(num / 1000000000000, 2) "t"
		else if (num >= 1000000000)
			return Round(num / 1000000000, 2) "b"
		else if (num >= 1000000)
			return Round(num / 1000000, 2) "m"
		else if (num >= 1000)
			return Round(num / 1000, 2) "k"
		else
			return num
	}

	DrawLineGraphWithGradient(pGraphic, rect, dataKey, colorHex, isBuff := true, forcedMax := 0) {
		if (this.logs.Length < 2)
			return
		
		maxVal := forcedMax
		if (maxVal = 0) {
			for index, snap in this.logs {
				val := isBuff ? (snap["buffs"].Has(dataKey) ? snap["buffs"][dataKey] : 0) : snap[dataKey]
				if (val > maxVal)
					maxVal := val
			}
			if (maxVal = 0)
				maxVal := 10
		}
		
		points := []
		logCount := this.logs.Length
		points.Push([rect.x, rect.y + rect.h])
		
		for index, snap in this.logs {
			val := isBuff ? (snap["buffs"].Has(dataKey) ? snap["buffs"][dataKey] : 0) : snap[dataKey]
			if (val < 0)
				val := 0
			if (val > maxVal)
				val := maxVal
			xPos := rect.x + ((index - 1) * (rect.w / (logCount - 1)))
			yPos := rect.y + rect.h - ((val / maxVal) * rect.h)
			points.Push([xPos, yPos])
		}
		points.Push([rect.x + rect.w, rect.y + rect.h])

		if (dataKey = "bag") {
			pBrush := Gdip_CreateLinearGrBrushFromRect(rect.x, rect.y, rect.w, rect.h, 0x00000000, 0x00000000)
			Gdip_SetLinearGrBrushPresetBlend(pBrush, [0.0, 0.2, 0.8], [0x80FF0000, 0x80FF8000, 0x8041FF80])
		} else {
			transColor := (colorHex &0x00FFFFFF) | 0x60000000
			pBrush := Gdip_CreateLinearGrBrushFromRect(rect.x, rect.y, rect.w, rect.h, transColor, 0x00000000)
		}
		Gdip_FillPolygon(pGraphic, pBrush, points)
		Gdip_DeleteBrush(pBrush)

		points.RemoveAt(1)
		points.Pop()

		if (dataKey = "bag") {
			pPeBrush := pPenBrush := Gdip_CreateLinearGrBrushFromRect(rect.x, rect.y, rect.w, rect.h, 0x00000000, 0x00000000)
			Gdip_SetLinearGrBrushPresetBlend(pPenBrush, [0.0, 0.2, 0.8], [0xFFFF0000, 0xFFFF8000, 0xFF41FF80])
			pPen := Gdip_CreatePenFromBrush(pPenBrush, 2)
		} else {
			pPen := Gdip_CreatePen(colorHex, 2)
		}
		Gdip_DrawLines(pGraphic, pPen, points)
		Gdip_DeletePen(pPen)
		if (dataKey = "bag") {
			Gdip_DeleteBrush(pPenBrush)
		}
	}

	IsOnOff(buffName) {
		static onOffList := Map("melody", 1, "morph", 1, "bear_morph", 1, "oil", 1, "super_smoothie", 1,
		"bomb_sync_red", 1, "bomb_sync_blue", 1, "festive_blessing", 1, "beesmas_cheer", 1, "tabby_blessing", 1,
		"clouds", 1, "baby_love", 1, "festive_mark", 1, "flame_fuel", 1, "guiding_star", 1, "stinger", 1,
		"enzyme", 1, "extract_red", 1, "extract_blue", 1, "glue", 1, "tropical_drink", 1, "purple_potion", 1,
		"marshmallow_bee", 1, "jellybean_sharing", 1, "pop_star", 1, "scorching_star", 1, "gummy_star", 1)
		return onOffList.Has(buffName)
	}

	isDigit(buffName) {
		static digitList := Map("focus", 1, "bomb", 1, "rage", 1, "inspire", 1, "balloon_aura", 1, "clock", 1,
		"honey_mark", 1, "pollen_mark", 1, "precise_mark", 1, "reindeer_guidance", 1, "mondo", 1, "map_corruption", 1,
		"cool_breeze", 1, "precision", 1, "sticker_stack", 1, "puffshroom_blessing", 1, "robo_party", 1,
		"dark_heat", 1, "coconut_combo", 1, "balloon_blessing", 1, "haste", 1, "boost_red", 1, "boost_blue", 1,
		"boost_white", 1, "boost", 1, "flame_heat", 1, "bubble_bloat", 1, "comforting", 1, "motivating", 1, "satisfying", 1,
		"refreshing", 1, "invigorating", 1, "tide_blessing", 1, "festive_nymph", 1)
		return digitList.Has(buffName)
	}


	DetectBuffs() {
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok 
			return
		
		if win.w <= 500
			return

		this.currentBuffs := Map()
		pBMTop := Gdip_BitmapFromScreen(win.x "|" win.y + State.offsetY + 30 "|" win.w "|" 50)
		pBMBottom := Gdip_BitmapFromScreen(win.x + (win.w // 2) - 257 "|" win.y + win.h - 142 "|517|36")

		; --------------------
		; STANDARD ON/OFF BUFFS (TOP)
		; --------------------
		onOffList := ["oil", "super_smoothie", "bomb_sync_red", "bomb_sync_blue"
							, "festive_blessing", "beesmas_cheer", "tabby_blessing", "clouds"
							, "baby_love", "festive_mark", "flame_fuel", "guiding_star"
							, "stinger", "enzyme", "extract_red", "extract_blue"
							, "glue", "tropical_drink", "purple_potion", "marshmallow_bee"
							, "jellybean_sharing"]
		; "galentine", "honeyday", "beesmas_repentance"
		for index, buffName in onOffList {
			rules := buff_params[buffName]
			if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"][buffName], &loc, rules.x1, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
				this.Verify(buffName, true, 0)
			} else {
				this.Verify(buffName, false, 0)
			}
		}

		; --------------------
		; BEAR MORPHS
		; --------------------
		bearActive := false
		bearList := ["brown", "black", "panda", "polar", "gummy", "science", "mother"]
		rules := buff_params["morph"]
		for index, bear in bearList {
			if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"][bear], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
				bearActive := true
				break
			}
		}
		this.Verify("bear_morph", bearActive, 0)

		; --------------------
		; STANDARD BUFFS (DIGITS) "1x - 999x"
		; --------------------
		digitList := ["focus", "bomb", "rage", "inspire", "balloon_aura", "clock"
						, "honey_mark", "pollen_mark", "precise_mark", "reindeer_guidance"
						, "mondo", "map_corruption", "cool_breeze", "precision", "sticker_stack"
						, "puffshroom_blessing", "robo_party", "dark_heat", "coconut_combo", "festive_nymph"]
		for index, buffName in digitList {
			rules := buff_params[buffName]
			if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"][buffName], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
				x := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				val := this.ReadDigits(pBMTop, x, 20, x + 40, 46)
				this.Verify(buffName, val, 1)
			} else {
				this.Verify(buffName, 0, 1)
			}
		}

		; --------------------
		; BLESSING (1x- 100x) - USES A SPECIFIC BITMAP FOR 100x
		this.currentBuffs["balloon_blessing"] := 0
		rules := buff_params["balloon_blessing"]
		balloon := 0
		if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["balloon_blessing_100"], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
			balloon := 100
		} else if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["balloon_blessing"], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
			x := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
			balloon := this.ReadDigits(pBMTop, x + 8, 15, x + 36, 46)
		}
		this.Verify("balloon_blessing", balloon, 1)

		; --------------------
		; SPECIAL BUFFS (DIGITS) Haste / Melody / Coco Haste
		; --------------------
		haste := 0, melody := 0
		searchX := 0
		rules := buff_params["haste"]
		mel := buff_params["melody"]
		loop 3 {
			if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["haste"], &loc, searchX, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
				x := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["melody"], , x + 2, mel.y1, x + 34, mel.y2, mel.var) = 1) {
					melody := 1
				} else if (haste = 0) {
					haste := this.ReadDigits(pBMTop, x + 6, 15, x + 44, 50, "big")
				}
				searchX := x + 44
			} else {
				break
			}
		}
		this.Verify("haste", haste, 1)
		this.Verify("melody", melody, 0)

		; --------------------
		; SPECIAL BUFFS (DIGITS) Red / Blue / White Boost
		; --------------------
		red := 0, blue := 0, white := 0
		searchX := win.w
		rules := buff_params["boost"]
		loop 3 {
			if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["boost"], &loc, 0, rules.y1, searchX, rules.y2, rules.var, , rules.dir) = 1) {
				x := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				y := Integer(SubStr(loc, InStr(loc, ",") + 1))
				r_red := buff_params["boost_red"]
				r_blue := buff_params["boost_blue"]

				isRed := Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["boost_red"], , x-30, 15, x-4, 34, r_red.var, r_red.trans, r_red.dir, r_red.instances)
				isBlue := Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"]["boost_blue"], , x-30, 15, x-4, 34, r_blue.var, r_blue.trans, r_blue.dir, r_blue.instances)

				val := this.ReadDigits(pBMTop, x - 30, 15, x + 3, 50, "big")
				if (isRed = 2) {
					red := val
				} else if (isBlue = 2) {
					blue := val
				} else {
					white := val
				}
				searchX := x - (2 * y - 53)
			} else {
				break
			}
		}
		this.Verify("boost_red", red, 1)
		this.Verify("boost_blue", blue, 1)
		this.Verify("boost_white", white, 1)

		; ---------------------
		; SCALED FILLS (0% - 100%) BASED OFF THE ICON
		; ---------------------
		scaledList := ["bubble_bloat", "comforting", "motivating", "satisfying", "refreshing", "invigorating", "tide_blessing", "flame_heat"]
		for index, buffName in scaledList {
			rules := buff_params["scaling"]
			if (Gdip_ImageSearch(pBMTop, bitmaps["stat_buff"][buffName], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
				x := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				val := this.ReadScaleFill(pBMTop, bitmaps["stat_buff"][buffName], x, buffName)
				this.Verify(buffName, val, 0)
			} else {
				this.Verify(buffName, 0, 0)
			}
		}

		; --------------------
		; PASSIVES (BOTTOM) - AUTO DETECT + TRACKING (fix, not working)
		; --------------------
		if (A_TickCount - this.scanStartTime < this.learningPeriod) {
			for index, buffName in this.possiblePassives {
				rules := buff_params[buffName]
				if (Gdip_ImageSearch(pBMBottom, bitmaps["stat_buff"][buffName], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1) {
					this.currentBuffs[buffName] := false
					hasBuff := false
					for item in this.confirmedPassives {
						if (item = buffName) {
							hasBuff := true
							break
						}
					}
					if !hasBuff {
						this.confirmedPassives.Push(buffName)
					}
				} else {
					hasBuff := false
					for item in this.confirmedPassives {
						if (item = buffName) {
							hasBuff := true
						}
					}
					if (hasBuff) {
						this.currentBuffs[buffName] := true
					}
				}
			}
		} else {
			for index, buffName in this.confirmedPassives {
				rules := buff_params[buffName]
				this.currentBuffs[buffName] := !(Gdip_ImageSearch(pBMBottom, bitmaps["stat_buff"][buffName], &loc, 0, rules.y1, 0, rules.y2, rules.var, , rules.dir) = 1)
			}
		}

		Gdip_DisposeImage(pBMTop), Gdip_DisposeImage(pBMBottom)
	}

	Verify(buffName, val, threshold := 1) {
		if (this.buff_limits.Has(buffName) && val > this.buff_limits[buffName])
			val := this.buff_limits[buffName]
		lastVal := this.previousBuffs.Has(buffName) ? this.previousBuffs[buffName] : 0
		if (val <= threshold && lastVal > threshold) {
			this.currentBuffs[buffName] := lastVal
		} else {
			this.currentBuffs[buffName] := val
		}
		this.previousBuffs[buffName] := val
	}

	ReadDigits(pBitmap, sX, sY, sW, sH, type := "auto") {
		if (type = "tiny" || type = "auto") {
			val := this.DetectNum(pBitmap, "tiny", sX, sY, sW, sH)
			if (val >= 100) {
				return val
			}
		}
		if (type = "big" || type = "auto") {
			val := this.DetectNum(pBitmap, "big", sX, sY, sW, sH)
			if (val > 0) {
				return val
			} 
		}
		return 1
	}

	DetectNum(pBitmap, numType, sX, sY, sW, sH) {
		offsets := (numType = "big") ? bigOffset : tinyOffset
		found := []
		priorityOrder := [8, 0, 6, 9, 4, 7, 2, 3, 5, 1]

		for idx in priorityOrder {
			currentX := sX
			while (Gdip_ImageSearch(pBitmap, bitmaps["stat_digits_" numType][idx], &loc, currentX, sY, sW, sH, , , 6)) {
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

	ReadScaleFill(pBitmap, bitmap, x, buffName) {
		if (Gdip_ImageSearch(pBitmap, bitmap, &loc, x, 6, x + 38, 44) = 1) {
			y := Integer(SubStr(loc, InStr(loc, ",") + 1))
			fillRatio := Min((44 - y) / 38, 1)
			if (buffName = "bubble_bloat") {
				return Round(fillRatio * 5 + 1, 2)
			} else if (buffName = "tide_blessing") {
				return Round(1.01 + 0.19 * (44.3 - y) / 38, 2)
			} else if (buffName = "flame_heat") {
				return Round(1 + fillRatio, 2)
			} else {
				return Round(fillRatio * 100)
			}
		}
		return 0
	}

	DetectBag() { ; natro
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok
			return 0

		pX := win.x + (win.w // 2) + 61
		pY := win.y + State.offsetY + 6
		bag_color := PixelGetColor(pX, pY)

		if (bag_color = 0xF70017) {
			return 100
		}

		; THIS IS A MESS
		R := bag_color & 0xFF0000
		GB := bag_color & 0x00FFFF

		; 5% - 45%
		if (R <= 0x690000) {
			; 5% - 20%
			if (R <= 0x4B0000) {
				if (R > 0x410000 && R <= 0x420000 && GB > 0x00FC85 && GB <= 0x00FF80)
					return 5
				if (R > 0x420000 && R <= 0x440000 && GB > 0x00F984 && GB <= 0x00FE85)
					return 10
				if (R > 0x440000 && R <= 0x470000 && GB > 0x00F582 && GB <= 0x00FB84)
					return 15
				if (R > 0x470000 && R <= 0x4B0000 && GB > 0x00F080 && GB <= 0x00F782)
					return 20
			} else { ; 25% - 45%
				if (R > 0x4B0000 && R <= 0x4F0000 && GB > 0x00EA7D && GB <= 0x00F280)
					return 25
				if (R > 0x4F0000 && R <= 0x550000 && GB > 0x00E37A && GB <= 0x00EC7D)
					return 30
				if (R > 0x550000 && R <= 0x5B0000 && GB > 0x00DA76 && GB <= 0x00E57A)
					return 35
				if (R > 0x5B0000 && R <= 0x620000 && GB > 0x00D072 && GB <= 0x00DC76)
					return 40
				if (R > 0x620000 && R <= 0x690000 && GB > 0x00C66D && GB <= 0x00D272)
					return 45
			}
		} else { ; 50% - 100%
			if (R <= 0x9C0000) { ; 50% - 70%
				if (R > 0x690000 && R <= 0x720000 && GB > 0x00BA68 && GB <= 0x00C86D)
					return 50
				if (R > 0x720000 && R <= 0x7B0000 && GB > 0x00AD62 && GB <= 0x00BC68)
					return 55
				if (R > 0x7B0000 && R <= 0x850000 && GB > 0x009E5C && GB <= 0x00AF62)
					return 60
				if (R > 0x850000 && R <= 0x900000 && GB > 0x008F55 && GB <= 0x00A05C)
					return 65
				if (R > 0x900000 && R <= 0x9C0000 && GB > 0x007E4E && GB <= 0x009155)
					return 70
			} else { ; 75% - 100%
				if (R > 0x9C0000 && R <= 0xA90000 && GB > 0x006C46 && GB <= 0x00804E)
					return 75
				if (R > 0xA90000 && R <= 0xB60000 && GB > 0x005A3F && GB <= 0x006E46)
					return 80
				if (R > 0xB60000 && R <= 0xC40000 && GB > 0x004637 && GB <= 0x005D3F)
					return 85
				if (R > 0xC40000 && R <= 0xD30000 && GB > 0x00322E && GB <= 0x004A37)
					return 90
				if (GB <= 0x00342E)
					return 95
				if (R >= 0xE00000 && GB > 0x001000 && GB <= 0x002427)
					return 100
			}
		}
		return 0
	}

	DetectHoney() { ; natro
		win := WindowTracker.Get()
		if !IsObject(win) || !win.ok || win.w <= 500
			return 0
		
		pBMScreen := Gdip_BitmapFromScreen(win.x + (win.w // 2) - 241 "|" win.y + State.offsetY "|140|36")
		pEffect := Gdip_CreateEffect(5, -80, 30)
		detected := Map()
		loop 25 {
			i := A_Index
			loop 2 {
				pBMRes := Gdip_ResizeBitmap(pBMScreen, ((A_Index = 1) ? (250 + i * 20) : (750 - i * 20)), 36 + i * 4, 2)
				Gdip_BitmapApplyEffect(pBMRes, pEffect)
				hBM := Gdip_CreateHBITMAPFromBitmap(pBMRes)

				Gdip_DisposeImage(pBMRes)

				pIRandomAccessStream := HBitmapToRandomAccessStream(hBM)
				DllCall("DeleteObject", "Ptr", hBM)

				try rawText := ocr(pIRandomAccessStream, this.ocr_language)
				catch
					rawText := ""

				cleanText := RegExReplace(StrReplace(StrReplace(StrReplace(StrReplace(rawText, "o", "0"), "i", "1"), "l", "1"), "a", "4"), "\D")
				v := (StrLen(cleanText) > 0) ? Integer(cleanText) : 0
				if (v > 0) {
					detected[v] := detected.Has(v) ? detected[v] + 1 : 1
					if (detected[v] >= 3) {
						Gdip_DisposeImage(pBMScreen)
						Gdip_DisposeEffect(pEffect)
						DllCall("psapi.dll\EmptyWorkingSet", "UInt", -1)
						return v
					}
				}
			}
		}
		Gdip_DisposeImage(pBMScreen)
		Gdip_DisposeEffect(pEffect)
		DllCall("psapi.dll\EmptyWorkingSet", "UInt", -1)

		current_honey := 0
		for k, val in detected
			if (val > 2 && k > current_honey)
				current_honey := k
		return current_honey
	}

	Export() {
		if (this.logs.Length >= 2)
			this.DrawGraph()
		this.logs := []
		this.previousBuffs := Map()
		this.currentBuffs := Map()
		this.confirmedPassives := []
		this.scanStartTime := A_TickCount
	}
}
