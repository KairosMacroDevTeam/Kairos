; ===================
; TIME UTILITY
; ===================
/**
 * @description QueryPerformanceCounter
 * @author Thqby
 **/
QPC() {
	static _ := 0, f := (DllCall("QueryPerformanceFrequency", "int64*", &_), _ /= 1000)
	return (DllCall("QueryPerformanceCounter", "int64*", &_), _ / f)
}

/**
 * @description NowUnix
 * @author N/A
 **/
nowUnix() => DateDiff(A_NowUTC, "19700101000000", "Seconds")

/**
 * @description HyperSleep
 * @author N/A
 **/
HyperSleep(ms)
{
	static freq := (DllCall("QueryPerformanceFrequency", "Int64*", &f := 0), f)
	DllCall("QueryPerformanceCounter", "Int64*", &begin := 0)
	current := 0, finish := begin + ms * freq / 1000
	while (current < finish)
	{
		if ((finish - current) > 30000)
		{
			DllCall("Winmm.dll\timeBeginPeriod", "UInt", 1)
			DllCall("Sleep", "UInt", 1)
			DllCall("Winmm.dll\timeEndPeriod", "UInt", 1)
		}
		DllCall("QueryPerformanceCounter", "Int64*", &current)
	}
}

/**
* @description: Simple GetDurationFormatEx parser
* https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getdurationformatex
* @author SP
**/
DurationFromSeconds(secs, format:="hh:mm:ss", capacity:=64)
{
	dur := Buffer(capacity), DllCall("GetDurationFormatEx"
		, "Ptr", 0
		, "UInt", 0
		, "Ptr", 0
		, "Int64", secs*10000000
		, "Str", format
		, "Ptr", dur.Ptr
		, "Int", 32)
	return StrGet(dur)
}
hmsFromSeconds(secs) => DurationFromSeconds(secs, ((secs >= 3600) ? "h'h' m" : "") ((secs >= 60) ? "m'm' s" : "") "s's'")

; ===================
; OBJECT/ARRAY UTILITY
; ===================
ObjFullyClone(obj)
{
	nobj := obj.Clone()
	for k, v in nobj
		if IsObject(v)
			nobj[k] := ObjFullyClone(v)
	return nobj
}
ObjHasValue(obj, value)
{
	for k, v in obj
		if (v = value)
			return 1
	return 0
}
ObjMinIndex(obj)
{
	for k, v in obj
		return k
	return 0
}
ObjIndexOf(obj, val)
{
	for k, v in obj
		if (v = val)
			return k
	return 0
}
ObjStrJoin(delim, arr) {
	out := ""
	try {
		for k, v in arr
			out .= (out = "" ? "" : delim) . v
		return out
	} catch
		return 0
}