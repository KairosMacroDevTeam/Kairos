class Detection {
	numOffset := Map(0, 7, 1, 2, 2, 6, 3, 6, 4, 7, 5, 6, 6, 7, 7, 7, 8, 7, 9, 7)
	
	__New() {

	}

	SearchIcon(pBitmap, pImg, x1 := 0, y1 := 0, x2 := 0, y2 := 0, var := 6) {
		if (Gdip_ImageSearch(pBitmap, pImg, &loc, x1, y1, x2, y2, var, , 6) = 1)
			return { found: true, x: Integer(SubStr(loc, 1, InStr(loc, ",") - 1)), y: Integer(SubStr(loc, InStr(loc, ",") + 1)) }
		return { found: false , x: 0, y: 0 }
	}

	ReadDigits(pBitmap, x1, y1, x2, y2, numType := "auto") {
		if (numType = "passive")
			return this._ReadPassive(pBitmap, x1, y1, x2, y2)

		if (numType = "auto" || numType ~= "tiny|small") {
			val := this._ReadBuff(pBitmap, "tiny", x1, y1, x2, y2)
			if (val >= 100 || numType != "auto")
				return val
		}
		if (numType = "auto" || numType = "big") {
			val := this._ReadBuff(pBitmap, "big", x1, y1, x2, y2)
			if (val > 0)
				return val
		}
		return 1
	}

	ReadPercentageFill(pBitmap, scanX, topY, bottomY, targetColors, tolerance := 0) {
		low := topY
		high := bottomY
		while (low < high) {
			mid := Floor((low + high) / 2)
			pixelColor := Gdip_GetPixel(pBitmap, scanX, mid)
			match := false
			if IsObject(targetColors) {
				for col in targetColors {
					if this._IsColorMatch(pixelColor, col, tolerance) {
						match := true
						break
					}
				}
			} else {
				match := this._IsColorMatch(pixelColor, targetColors, tolerance)
			}
			if (match)
				high := mid
			else
				low := mid + 1
		}
		return low
	}

	_IsColorMatch(pixel, target, tolerance := 0) {
		if (tolerance = 0)
			return pixel = target
		r := (pixel >> 16) & 0xFF
		g := (pixel >> 8) & 0xFF
		b := pixel & 0xFF

		tr := (target >> 16) & 0xFF
		tg := (target >> 8) & 0xFF
		tb := target & 0xFF

		return (Abs(r - tr) <= tolerance) && (Abs(g - tg) <= tolerance) && (Abs(b - tb) <= tolerance)
	}

	_ReadPassive(pBitmap, x1, y1, x2, y2) {
		found := []
		loop 10 {
			idx := 10 - A_Index
			if (Gdip_ImageSearch(pBitmap, bitmaps["buff"][idx], &loc1, x1, y1, x2, y2, 6) = 1) {
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
					if (Gdip_ImageSearch(pBitmap, bitmaps["buff"][idx], &loc2, mX + currentWidth - 1, y1, x2, y2, 6) = 1) {
						mX2 := SubStr(loc2, 1, InStr(loc2, ",") - 1)
						found.Push({ num: idx, x: Integer(mX2), w: currentWidth })
					}
				}
			}
		}
		if (found.Length = 0)
			return 0
		else if (found.Length = 1)
			return found[1].num
		else
			if (found[1].x < found[2].x)
				return found[1].num . found[2].num
			else
				return found[2].num . found[1].num
	}

	_ReadBuff(pBitmap, sizeType, x1, y1, x2, y2) {
		offsets := (sizeType = "big") ? bigOffset: tinyOffset
		found := []
		priorityOrder := [8, 0, 6, 9, 4, 7, 2, 3, 5, 1]
		for idx in priorityOrder {
			currentX := x1
			while (Gdip_ImageSearch(pBitmap, bitmaps["buff"][sizeType][idx], &loc, currentX, y1, x2, y2, , , 6)) {
				mX := Integer(SubStr(loc, 1, InStr(loc, ",") - 1))
				isOverlap := false
				for item in found {
					if (mX >= item.x && mX < item.x + item.w) || (item.x >= mX && item.x < mX + offsets[idx]) {
						isOverlap := true
						break
					}
				}
				if (!isOverlap)
					found.Push({ num: idx, x: mX, w: offsets[idx] })
				currentX := mX + offsets[idx]
				if (currentX >= x2)
					break
			}
		}
		if (found.Length = 0)
			return 0
		loop found.Length {
			i := A_Index
			loop found.Length - i {
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
}