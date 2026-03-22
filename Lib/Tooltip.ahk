GdipTooltip__OnMouseWheel(wParam, lParam, msg, hwnd) {
	return GdipTooltip._OnMouseWheel(wParam, lParam, msg, hwnd)
}
GdipTooltip__OnLButtonDown(wParam, lParam, msg, hwnd) {
	return GdipTooltip._OnLButtonDown(wParam, lParam, msg, hwnd)
}
GdipTooltip__OnMove(wParam, lParam, msg, hwnd) {
	return GdipTooltip._OnMove(wParam, lParam, msg, hwnd)
}

class GdipTooltip {
	__New(draggable := false) {
		this.Draggable := draggable

		this.Gui := Gui("-Caption +E0x80000 +E0x08000000 +AlwaysOnTop +ToolWindow +OwnDialogs")
		this.Gui.Show("NA")
		this.hwnd := this.Gui.Hwnd

		; interactive stuff
		this.BaseMaxWidth := 600
		this.BaseMaxHeight := 800
		this.BaseFontSize := 15
		this.BaseImageSize := 20
		this.BasePadX := 5
		this.BasePadY := 5
		this.BaseRowSpacing := 2
		this.BaseColumnSpacing := 2

		this.Zoom := 1.0
		this.MinZoom := 0.6
		this.MaxZoom := 2.5

		; remember last draw so Ctrl+Wheel can redraw at new zoom
		this._lastData := ""
		this._lastX := ""
		this._lastY := ""
		this._lastBackground := 0xCC000000

		; manual position support (so Tracker.Show() won't snap it back)
		this._manualPos := false
		this._manualX := ""
		this._manualY := ""

		; register this instance so OnMessage handlers can find it
		GdipTooltip._Register(this)

		this.MaxWidth := this.BaseMaxWidth
		this.MaxHeight := this.BaseMaxHeight

		this.hbm := CreateDIBSection(this.MaxWidth, this.MaxHeight)
		this.hdc := CreateCompatibleDC()
		this.obm := SelectObject(this.hdc, this.hbm)
		this.G := Gdip_GraphicsFromHDC(this.hdc)
		Gdip_SetSmoothingMode(this.G, 4)

		this.fontName := "Arial"
		this.fontSize := this.BaseFontSize
		this.fontStyle := 0
		this.fontColor := "FFFFFFFF"

		this.imageSize := this.BaseImageSize

		this.padX := this.BasePadX
		this.padY := this.BasePadY
		this.rowSpacing := this.BaseRowSpacing
		this.columnSpacing := this.BaseColumnSpacing
	}

	; OnMessage Hooks
	static Instances := Map()
	static _hooksInstalled := false

	static _Register(inst) {
		GdipTooltip.Instances[inst.hwnd] := inst
		if !GdipTooltip._hooksInstalled {
			GdipTooltip._hooksInstalled := true
			; WM_MOUSEWHEEL / WM_LBUTTONDOWN / WM_MOVE
			OnMessage(0x20A, GdipTooltip__OnMouseWheel)
			OnMessage(0x201, GdipTooltip__OnLButtonDown)
			OnMessage(0x0003, GdipTooltip__OnMove)
		}
	}

	static _OnMouseWheel(wParam, lParam, msg, hwnd) {
		if !GetKeyState("Ctrl", "P")
			return
		if !GdipTooltip.Instances.Has(hwnd)
			return

		inst := GdipTooltip.Instances[hwnd]

		; wheel delta is the high word of wParam (signed)
		delta := (wParam >> 16) & 0xFFFF
		if (delta > 0x7FFF)
			delta -= 0x10000

		step := 1.10
		if (delta > 0)
			inst.Zoom := Min(inst.MaxZoom, inst.Zoom * step)
		else if (delta < 0)
			inst.Zoom := Max(inst.MinZoom, inst.Zoom / step)

		inst.RedrawLast()
		return 0
	}

	static _OnLButtonDown(wParam, lParam, msg, hwnd) {
		if !GdipTooltip.Instances.Has(hwnd)
			return

		inst := GdipTooltip.Instances[hwnd]
		if (!inst.Draggable)
			return
		if !GetKeyState("LCtrl")
			return
		inst._manualPos := true

		; drag by clicking
		PostMessage(0xA1, 2,,, "ahk_id " hwnd) ; WM_NCLBUTTONDOWN, HTCAPTION
		return 0
	}

	static _OnMove(wParam, lParam, msg, hwnd) {
		if !GdipTooltip.Instances.Has(hwnd)
			return

		inst := GdipTooltip.Instances[hwnd]
		if !inst._manualPos
			return

		; lParam: low word = x, high word = y (signed 16-bit)
		x := lParam & 0xFFFF
		y := (lParam >> 16) & 0xFFFF
		if (x > 0x7FFF)
			x -= 0x10000
		if (y > 0x7FFF)
			y -= 0x10000

		inst._manualX := x
		inst._manualY := y
	}

	EnsureBuffer(reqW, reqH) {
		; expand backing bitmap if zoom makes the tooltip larger than our buffer. - Souka
		if (reqW <= this.MaxWidth && reqH <= this.MaxHeight)
			return

		this.MaxWidth := Max(this.MaxWidth, Ceil(reqW * 1.2))
		this.MaxHeight := Max(this.MaxHeight, Ceil(reqH * 1.2))

		; recreate DIB + graphics context - Souka
		SelectObject(this.hdc, this.obm)
		DeleteObject(this.hbm)

		this.hbm := CreateDIBSection(this.MaxWidth, this.MaxHeight)
		this.obm := SelectObject(this.hdc, this.hbm)

		try Gdip_DeleteGraphics(this.G)
		this.G := Gdip_GraphicsFromHDC(this.hdc)
		Gdip_SetSmoothingMode(this.G, 4)
	}

	RedrawLast() {
		if (this._lastData = "")
			return
		this.Show(this._lastData, this._lastX, this._lastY, 0, this._lastBackground)
	}

	Show(data, x := "", y := "", scale := 0, background := 0xCC000000) {
		if !IsObject(data)
			data := [[String(data)]]
		else if (data.Length > 0 && Type(data[1]) != "Array")
			data := [data]

		; remember the request so Ctrl+Wheel can redraw with a new zoom - Souka
		this._lastData := data
		this._lastBackground := background

		zoom := (this.Zoom ? this.Zoom : 1.0)

		; apply zoom to layout metrics
		this.fontSize := Max(8, Round(this.BaseFontSize * zoom))
		this.imageSize := Max(8, Round(this.BaseImageSize * zoom))
		this.padX := Max(1, Round(this.BasePadX * zoom))
		this.padY := Max(1, Round(this.BasePadY * zoom))
		this.rowSpacing := Max(0, Round(this.BaseRowSpacing * zoom))
		this.columnSpacing := Max(0, Round(this.BaseColumnSpacing * zoom))

		layout := []
		totalH := this.padY * 2
		maxRowW := 0
		trash := []

		for i, row in data {
			if !IsObject(row)
				row := [row]

			rowHeight := 0
			rowWidth := 0
			rowItems := []

			for k, item in row {
				obj := {}
				isImage := false
				pBM := 0

				if IsInteger(item) && item > 65535 {
					pBM := item
					isImage := true
				} else if FileExist(item) {
					pBM := Gdip_CreateBitmapFromFile(item)
					isImage := true
					trash.Push(pBM)
				}

				if (isImage) {
					obj.Type := "Image"
					obj.Ptr := pBM
					obj.w := (scale ? Round(Gdip_GetImageWidth(pBM) * zoom) : this.imageSize)
					obj.h := (scale ? Round(Gdip_GetImageHeight(pBM) * zoom) : this.imageSize)
				} else {
					obj.Type := "Text"
					obj.Text := String(item)

					rect := this.MeasureText(obj.Text)
					obj.w := rect.w
					obj.h := rect.h
				}

				if (k > 1)
					rowWidth += this.columnSpacing
				rowWidth += obj.w
				if (obj.h > rowHeight)
					rowHeight := obj.h
				rowItems.Push(obj)
			}

			layout.Push({ Items: rowItems, w: rowWidth, h: rowHeight })

			if (rowWidth > maxRowW)
				maxRowW := rowWidth
			totalH += rowHeight + this.rowSpacing
		}

		totalH -= this.rowSpacing
		finalW := maxRowW + this.padX * 2

		this.EnsureBuffer(finalW, totalH)

		Gdip_GraphicsClear(this.G)
		pBrushBackground := Gdip_BrushCreateSolid(background)
		Gdip_FillRoundedRectangle(this.G, pBrushBackground, 0, 0, finalW, totalH, 5)
		Gdip_DeleteBrush(pBrushBackground)

		currentY := this.padY
		for i, rowData in layout {
			currentX := this.padX
			for item in rowData.Items {
				yOffset := (rowData.h - item.h) // 2
				drawY := currentY + yOffset

				if (item.Type = "Image") {
					Gdip_DrawImage(this.G, item.Ptr, currentX, drawY, item.w, item.h)
				} else {
					Options := "x" currentX " y" drawY " c" this.fontColor " s" this.fontSize " " this.fontStyle " NoWrap"
					Gdip_TextToGraphics(this.G, item.Text, Options, this.fontName, item.w + 10, item.h + 10)
				}
				currentX += item.w + this.columnSpacing
			}
			currentY += rowData.h + this.rowSpacing
		}

		for bm in trash
			Gdip_DisposeImage(bm)

		; if user dragged it, keep their position forever until Hide() is called. - Souka
		if (this._manualPos && this._manualX != "" && this._manualY != "") {
			x := this._manualX
			y := this._manualY
		}

		if (x = "" || y = "") {
			MouseGetPos(&mx, &my)
			x := mx + 15
			y := my + 15
		}

		this._lastX := x
		this._lastY := y

		if (x + finalW > A_ScreenWidth)
			x := A_ScreenWidth - finalW - 10

		UpdateLayeredWindow(this.hwnd, this.hdc, x, y, finalW, totalH)
	}

	MeasureText(text) {
		hFormat := Gdip_StringFormatCreate()
		hFamily := Gdip_FontFamilyCreate(this.fontName)
		hFont := Gdip_FontCreate(hFamily, this.fontSize, this.fontStyle)

		CreateRectF(&RC := "", 0, 0, 0, 0)
		Rect := Gdip_MeasureString(this.G, String(text), hFont, hFormat, &RC)

		Gdip_DeleteStringFormat(hFormat)
		Gdip_DeleteFont(hFont)
		Gdip_DeleteFontFamily(hFamily)

		RectArr := StrSplit(Rect, "|")
		return { w: Ceil(RectArr[3]), h: Ceil(RectArr[4]) }
	}

	Hide() {
		; hiding resets manual positioning (next Show snaps back to caller's coords) - Souka
		this._manualPos := false
		this._manualX := ""
		this._manualY := ""

		Gdip_GraphicsClear(this.G)
		UpdateLayeredWindow(this.hwnd, this.hdc, -1000, -1000, 1, 1)
	}

	__Delete() {
		SelectObject(this.hdc, this.obm)
		DeleteObject(this.hbm)
		DeleteDC(this.hdc)
		try Gdip_DeleteGraphics(this.G)
		this.Gui.Destroy()
	}
}
