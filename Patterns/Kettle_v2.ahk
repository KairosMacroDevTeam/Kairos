/************************************************************************
 * @description Kettle_v2 - A simple pattern for pine tree, with a twist.
 * @author Dully176
 * @date 2026/02/16
 * @settings {"Name":"Pine Tree","Pattern":"Kettle_v2","DriftCheck":0,"PatternInvertFB":0,"PatternInvertLR":0,"PatternReps":1,"PatternShift":1,"PatternSize":"M","ReturnType":"Walk","RotateDirection":"Right","RotateTimes":4,"SprinklerDist":7,"SprinklerLoc":"Upper Left","UntilMins":10,"UntilPack":95}
 ***********************************************************************/
#Warn All, Off
PassiveFieldDriftComp := 0.3
DiamondMaskWallOffset := 1.5
DiamondMaskWallDriftComp := 3
HoneyBeeWallOffset := 1.5
HoneyBeeWallDriftComp := 3

global cameraOffset := 0
global targetIdx := 0
global rotStep := 0
global isSurge := 0

loops := 2
longWalk := 6.25
shortWalk := longWalk / 4
halfWalk := longWalk / 2

(bitmaps := Map()).CaseSense := false
(bitmaps["big"] := Map()).CaseSense := false
(bitmaps["tiny"] := Map()).CaseSense := false

bitmaps["tide"] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAA4AAAABCAYAAADuHp8EAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAARSURBVBhXY5h46O9/0vHf/wAeAi5T1zfRIwAAAABJRU5ErkJggg==")

bitmaps["big"][0] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAxSURBVChTY4CBz58//0fGUGEIwBAAAmxiGACsCJ9KeinAB+AKsKnEEAMJIGOIKAMDABgYVJGLK3DUAAAAAElFTkSuQmCC")
bitmaps["big"][1] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAIAAAAMCAYAAABIvGxUAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAYSURBVBhXYwCBz58//wcTYAZchLqMz/8B0YQx+R5O9MAAAAAASUVORK5CYII=")
bitmaps["big"][2] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAcAAAALCAYAAACzkJeoAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAuSURBVChTYwCBz58//0fHcAkwAw3gEgcDvJI4AVZdOI2iogQIgCRxYTySn/8DAMvDZ8llWGsTAAAAAElFTkSuQmCC")
bitmaps["big"][3] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAcAAAAKCAYAAAB4zEQNAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAqSURBVChTYwCBz58//0fGYEFcAK8C0iUptxMECNuLTQWKGIiDjCGiDAwAShFFMY02eJ0AAAAASUVORK5CYII=")
bitmaps["big"][4] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAMCAYAAABfnvydAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAABASURBVChTY8AFPn/+/B/KxAQgSZwKYJJYFSAL4jQBBjAUoAug8LEZBxcDMXApAIvDGLgwVD0mwCsJAkQqYGAAANoXa6Ec6+LhAAAAAElFTkSuQmCC")
bitmaps["big"][5] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAcAAAALCAYAAACzkJeoAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAA1SURBVChTY/j8+fN/bJgBBLBJgDBcEszABghKomOoFHZAUAFegFM3XmPhkiAGOgZLMDAwAADqF2uhqKEf6gAAAABJRU5ErkJggg==")
bitmaps["big"][6] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAxSURBVChTY0AHnz9//g9lYgIaSYIAUQrQMVQKIQnlYgJ8knA5bIowxEAC6JiBgYEBACitULlgPRFaAAAAAElFTkSuQmCC")
bitmaps["big"][7] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAMCAYAAABfnvydAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAgSURBVChTY/j8+fN/fJiwAlwAryRBQFA3ZXYPPuMZGAB2A2AZaBGLjgAAAABJRU5ErkJggg==")
bitmaps["big"][8] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAA4SURBVChTY4CBz58//0fGUGEIwBAAAhQxohSgY6gUAuBVgE0HNjEMAFZEvEo0gCEGEkDGEFEGBgDC6WfJEOXd3QAAAABJRU5ErkJggg==")
bitmaps["big"][9] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAxSURBVChTY4CBz58//0fGUGEIwBAAArgYNkkYwKsIJIYiDhNAxlAp7IAyBdSUZGAAAG2VULlLev2qAAAAAElFTkSuQmCC")

bitmaps["tiny"][0] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAGCAYAAADgzO9IAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAfSURBVBhXY/j8+fN/BmwAmwRYjDoScACSRMYMDAwMAJATLiH0haORAAAAAElFTkSuQmCC")
bitmaps["tiny"][1] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAAICAYAAAA4GpVBAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAARSURBVBhXY/j8+fN/gsTn/wBmth7BgQALagAAAABJRU5ErkJggg==")
bitmaps["tiny"][2] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAJCAYAAAD6reaeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAeSURBVBhXY/j8+fN/ZMyADeCUoAlAdxLYdkzBz/8BPaM5qQpRvlAAAAAASUVORK5CYII=")
bitmaps["tiny"][3] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAQAAAAICAYAAADeM14FAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAcSURBVBhXY/j8+fN/ZMxAPCBDCxwgW/n58+f/AFjCJnH3HUWFAAAAAElFTkSuQmCC")
bitmaps["tiny"][4] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAJCAYAAAARml2dAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAoSURBVBhXY0AHnz9//g9lIgBIEKsECFAgga4CxMeqi7BR6AAiwcAAAM8OLiGDjp3KAAAAAElFTkSuQmCC")
bitmaps["tiny"][5] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAICAYAAAAx8TU7AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAbSURBVBhXY/j8+fN/ZMxAGiBfO27VmOYxMAAAswAuITuolG4AAAAASUVORK5CYII=")
bitmaps["tiny"][6] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAeSURBVBhXYwCBz58//wcz8AKsqogXBAGQBAJ//g8AB+EewSn4yt0AAAAASUVORK5CYII=")
bitmaps["tiny"][7] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAYAAAAJCAYAAAARml2dAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAbSURBVBhXY/j8+fN/bJiBRoBKZuM0BlWCgQEAno4imbvu4ggAAAAASUVORK5CYII=")
bitmaps["tiny"][8] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAICAYAAAAx8TU7AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAoSURBVBhXYwCBz58//0fGYEHiAVatyIJgCRRZGMAqCALIWj9//vwfAOd3QVmQ8MdJAAAAAElFTkSuQmCC")
bitmaps["tiny"][9] := Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABmZVhJZklJKgAIAAAAAQBphwQAAQAAABoAAAAAAAAAAwAAkAcABAAAADAyMzABoAMAAQAAAAEAAAAFoAQAAQAAAEQAAAAAAAAAAgABAAIABAAAAFI5OAACAAcABAAAADAxMDAAAAAAIvvHMbnUA7gAAAAeSURBVBhXYwCBz58//0fGYAGwDDLAKkgUwGHc5/8A+LUewc6D4egAAAAASUVORK5CYII=")

bigOffset := Map(0, 8, 1, 2, 2, 7, 3, 7, 4, 8, 5, 7, 6, 8, 7, 8, 8, 8, 9, 8)
tinyOffset := Map(0, 6, 1, 1, 2, 5, 3, 4, 4, 6, 5, 5, 6, 5, 7, 6, 8, 5, 9, 5)

DirMap := Map()
DirMap[FwdKey] := 1
DirMap[FwdKey . RightKey] := 2
DirMap[RightKey . FwdKey] := 2
DirMap[RightKey] := 3
DirMap[RightKey . BackKey] := 4
DirMap[BackKey . RightKey] := 4
DirMap[BackKey] := 5
DirMap[BackKey . LeftKey] := 6
DirMap[LeftKey . BackKey] := 6
DirMap[LeftKey] := 7
DirMap[LeftKey . FwdKey] := 8
DirMap[FwdKey . LeftKey] := 8
OnExit(ExitFunc)
global isWalking := 0
SetTimer RotLoop, 1

isWalking := 1

dy_walk(halfWalk, LeftKey)
dy_walk(shortWalk, FwdKey)
dy_walk(longWalk, RightKey)
dy_walk(shortWalk, FwdKey)
dy_walk(longWalk, LeftKey)

dy_walk(longWalk + (DiamondMaskWallDriftComp>0 ?  DiamondMaskWallDriftComp + DiamondMaskWallOffset : 0), BackKey)

if DiamondMaskWallDriftComp > 0
	dy_walk(DiamondMaskWallOffset, FwdKey)

dy_walk(shortWalk, RightKey)
dy_walk(longWalk, FwdKey)
dy_walk(shortWalk, RightKey)
dy_walk(longWalk, BackKey)

dy_walk(shortWalk, RightKey)
dy_walk(longWalk, FwdKey)
dy_walk(shortWalk + (HoneyBeeWallDriftComp>0 ? HoneyBeeWallDriftComp + HoneyBeeWallOffset : 0), RightKey)

dy_walk(shortWalk, LeftKey)

dy_walk(longWalk, BackKey)

dy_walk(longWalk, LeftKey)
dy_walk(shortWalk, FwdKey)
dy_walk(longWalk, RightKey)
dy_walk(shortWalk, FwdKey)
dy_walk(halfWalk, LeftKey)

dy_walk(halfWalk, FwdKey, LeftKey)
dy_walk(shortWalk, FwdKey, RightKey)
dy_walk(longWalk + PassiveFieldDriftComp, BackKey, RightKey)
dy_walk(shortWalk, FwdKey, RightKey)
dy_walk(longWalk, FwdKey, LeftKey)

dy_walk(longWalk, BackKey, LeftKey)
dy_walk(shortWalk + PassiveFieldDriftComp, BackKey, RightKey)
dy_walk(longWalk, FwdKey, RightKey)
dy_walk(shortWalk + PassiveFieldDriftComp, BackKey, RightKey)
dy_walk(longWalk, BackKey, LeftKey)

dy_walk(shortWalk + PassiveFieldDriftComp, BackKey, RightKey)
dy_walk(longWalk, FwdKey, RightKey)
dy_walk(shortWalk + PassiveFieldDriftComp, BackKey, RightKey)
dy_walk(longWalk, BackKey, LeftKey)

dy_walk(longWalk, FwdKey, LeftKey)
dy_walk(shortWalk, FwdKey, RightKey)
dy_walk(longWalk + PassiveFieldDriftComp, BackKey, RightKey)
dy_walk(shortWalk, FwdKey, RightKey)
dy_walk(halfWalk, FwdKey, LeftKey)
isWalking := 0
SetTimer RotLoop, 0
comp(0)
ResetCam()

dy_walk(amount, dir1, dir2 := "") {
   key := dir1 . dir2
   if DirMap.Has(key)
      global targetIdx := DirMap[key]
   else
      global targetIdx := 1
   UpdateMovement()
   walk(amount)
}

scanDigits(x, y, pBitmap, numType := "big") {
   offsets := (numType = "big") ? bigOffset : tinyOffset
   found := []
   priorityOrder := [8, 0, 6, 9, 4, 7, 2, 3, 5, 1]
   sX := x - 13
   sY := 0
   sW := sX + 38
   sH := 32
   for idx in priorityOrder {
		currentX := sX
      while (Gdip_ImageSearch(pBitmap, bitmaps[numType][idx], &loc, currentX, sY, sW, sH, , , 6)) {
			
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

DetectTide() {
	static last := 0
	static bug := 0

   if !GetRobloxClientPos()
		return 0

   pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY + offsetY + 48 "|" windowWidth "|" 32)
   if (!Gdip_ImageSearch(pBMScreen, bitmaps["tide"], &loc, , , , , , , 8)) {
      Gdip_DisposeImage(pBMScreen)
		last := 0
      return 0
   }

   x := SubStr(loc, 1, InStr(loc, ",") - 1)
   y := SubStr(loc, InStr(loc, ",") + 1)

   current := ScanDigits(x, y, pBMScreen, "tiny")
	if (current < 100)
		current := ScanDigits(x, y, pBMScreen, "big")
   Gdip_DisposeImage(pBMScreen)

	if (current = 0 && last > 1 && ++bug <= 10)
		return last
	bug := 0
	last := current
   return current
}

GetRotInterval(val := -1) {
	static prev := 0
	global isSurge
	if (val = -1)
		val :=DetectTide()
	if (prev > 450 && val <= 100 && val > 0)
		isSurge := true
	if val = 0
		isSurge := false
	if (isSurge)
		multiplier := 1.5 + (val / 100)
	else
		multiplier := 1 + (val / 500)
	prev := val
	return 1000 / multiplier
}

RotLoop() {
	global cameraOffset, rotStep
	static swing := 0
	static wasInSurge := 0
	if (!isWalking)
		return
	val := DetectTide()
	interval := GetRotInterval(val)
	swing++
	isSurge := (val <= 100 && val > 0 && wasInSurge)
	isHigh := (val >= 495)

	if (val >= 495)
		wasInSurge := true
	if (val = 0)
		wasInSurge := false

	if (isSurge || isHigh || swing >= 3) {
		if (rotStep < 2) {
			send "{" RotLeft "}"
			cameraOffset--
		} else {
			send "{" RotRight "}"
			cameraOffset++
		}
		rotStep++
		if (rotStep >= 4)
			rotStep := 0
		UpdateMovement()
		swing := 0
	}
	SetTimer RotLoop, -interval

}

UpdateMovement() {
   global targetIdx, cameraOffset
   if (targetIdx = 0) {
      comp(0)
      return
   }
   actualIdx := targetIdx - cameraOffset
   actualIdx := Mod(actualIdx - 1, 8)
   if (actualIdx < 0)
      actualIdx += 8
   actualIdx++
   comp(actualIdx)
}

ResetCam() {
   global cameraOffset
   while (cameraOffset != 0) {
      if (cameraOffset < 0) {
         send "{" RotRight "}"
         cameraOffset++
      } else {
         send "{" RotLeft "}"
         cameraOffset--
      }
   }
}

comp(idx) {
   static cycle := [
      [FwdKey], ; 1
      [FwdKey, RightKey], ; 2
      [RightKey], ; 3
      [RightKey, BackKey], ; 4
      [BackKey], ; 5
      [BackKey, LeftKey], ; 6
      [LeftKey], ; 7
      [LeftKey, FwdKey] ; 8
   ]
   if (idx = 0) {
      for k in [FwdKey, BackKey, LeftKey, RightKey]
			if GetKeyState(k)
				send "{" k " up}"
      return
   }
   target := cycle[idx]
   for k in [FwdKey, BackKey, LeftKey, RightKey] {
      press := false
      for tk in target
         if (k = tk)
            press := true
      if (!press && GetKeyState(k))
         send "{" k " up}"
   }
   for k in target
      if (!GetKeyState(k))
         send "{" k " down}"
}

ExitFunc(*) {
   comp(0)
   ResetCam()
}
