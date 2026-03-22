global DarkColors := Map("Background", "0x202020", "Controls", "0x404040", "Font", "0xE0E0E0")
global TextBackgroundBrush := DllCall("gdi32\CreateSolidBrush", "UInt", DarkColors["Background"], "Ptr")
global ControlsBackgroundBrush := DllCall("gdi32\CreateSolidBrush", "UInt", DarkColors["Controls"], "Ptr")
global IsDarkMode := False

ToggleTheme(GuiCtrlObj, *)
{
	switch GuiCtrlObj.Text
	{
		case "DarkMode":
		{
			SetWindowAttribute(GuiCtrlObj.Gui)
			SetWindowTheme(GuiCtrlObj.Gui)
		}
		default:
		{
			SetWindowAttribute(GuiCtrlObj.Gui, False)
			SetWindowTheme(GuiCtrlObj.Gui, False)
		}
	}
}

SetWindowAttribute(GuiObj, DarkMode := True)
{
	static PreferredAppMode := Map("Default", 0, "AllowDark", 1, "ForceDark", 2, "ForceLight", 3, "Max", 4)

	if (VerCompare(A_OSVersion, "10.0.17763") >= 0)
	{
		DWMWA_USE_IMMERSIVE_DARK_MODE := 19
		if (VerCompare(A_OSVersion, "10.0.18985") >= 0)
		{
			DWMWA_USE_IMMERSIVE_DARK_MODE := 20
		}
		
		DllCall("LoadLibrary", "Str", "uxtheme", "Ptr")
		uxtheme := DllCall("kernel32\GetModuleHandle", "Str", "uxtheme", "Ptr")
		SetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
		FlushMenuThemes := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")
		
		switch DarkMode
		{
			case True:
			{
				DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
				DllCall(SetPreferredAppMode, "Int", PreferredAppMode["ForceDark"])
				DllCall(FlushMenuThemes)
				GuiObj.BackColor := DarkColors["Background"]
			}
			default:
			{
				DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", False, "Int", 4)
				DllCall(SetPreferredAppMode, "Int", PreferredAppMode["Default"])
				DllCall(FlushMenuThemes)
				GuiObj.BackColor := "Default"
			}
		}
	}
}

SetWindowTheme(GuiObj, DarkMode := True)
{
	static GWL_WNDPROC := -4
	static GWL_STYLE := -16
	static ES_MULTILINE := 0x0004
	static LVM_GETTEXTCOLOR := 0x1023
	static LVM_SETTEXTCOLOR := 0x1024
	static LVM_GETTEXTBKCOLOR := 0x1025
	static LVM_SETTEXTBKCOLOR := 0x1026
	static LVM_GETBKCOLOR := 0x1000
	static LVM_SETBKCOLOR := 0x1001
	static LVM_GETHEADER := 0x101F
	static GetWindowLong := A_PtrSize = 8 ? "GetWindowLongPtr" : "GetWindowLong"
	static SetWindowLong := A_PtrSize = 8 ? "SetWindowLongPtr" : "SetWindowLong"
	static Init := False
	static LV_OriginalColors := Map()
	global IsDarkMode := DarkMode

	Mode_Explorer := (DarkMode ? "DarkMode_Explorer" : "Explorer")
	Mode_CFD := (DarkMode ? "DarkMode_CFD" : "CFD")
	Mode_ItemsView := (DarkMode ? "DarkMode_ItemsView" : "ItemsView")

	for hWnd, GuiCtrlObj in GuiObj
	{
		switch GuiCtrlObj.Type
		{
			case "Button", "CheckBox", "ListBox", "UpDown":
			{
				DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
			}
			case "ComboBox", "DDL":
			{
				DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
			}
			case "Edit":
			{
				if (DllCall("user32\" GetWindowLong, "Ptr", GuiCtrlObj.hWnd, "Int", GWL_STYLE) & ES_MULTILINE)
				{
					DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
				}
				else
				{
					DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
				}
			}
			case "ListView":
			{
				if !LV_OriginalColors.Has(GuiCtrlObj.hWnd)
				{
					LV_OriginalColors[GuiCtrlObj.hWnd] := {
						TextColor: SendMessage(LVM_GETTEXTCOLOR, 0, 0, GuiCtrlObj.hWnd),
						TextBkColor: SendMessage(LVM_GETTEXTBKCOLOR, 0, 0, GuiCtrlObj.hWnd),
						BkColor: SendMessage(LVM_GETBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
					}
				}
				
				GuiCtrlObj.Opt("-Redraw")
				switch DarkMode
				{
					case True:
					{
						SendMessage(LVM_SETTEXTCOLOR, 0, DarkColors["Font"], GuiCtrlObj.hWnd)
						SendMessage(LVM_SETTEXTBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
						SendMessage(LVM_SETBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
					}
					default:
					{
						colors := LV_OriginalColors[GuiCtrlObj.hWnd]
						SendMessage(LVM_SETTEXTCOLOR, 0, colors.TextColor, GuiCtrlObj.hWnd)
						SendMessage(LVM_SETTEXTBKCOLOR, 0, colors.TextBkColor, GuiCtrlObj.hWnd)
						SendMessage(LVM_SETBKCOLOR, 0, colors.BkColor, GuiCtrlObj.hWnd)
					}
				}
				DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)

				LV_Header := SendMessage(LVM_GETHEADER, 0, 0, GuiCtrlObj.hWnd)
				DllCall("uxtheme\SetWindowTheme", "Ptr", LV_Header, "Str", Mode_ItemsView, "Ptr", 0)
				GuiCtrlObj.Opt("+Redraw")
			}
		}
	}

	if !(Init)
	{
		global WindowProcNew := CallbackCreate(WindowProc)
		global WindowProcOld := DllCall("user32\" SetWindowLong, "Ptr", GuiObj.Hwnd, "Int", GWL_WNDPROC, "Ptr", WindowProcNew, "Ptr")
		Init := True
	}
}

WindowProc(hwnd, uMsg, wParam, lParam)
{
	critical
	static WM_CTLCOLOREDIT := 0x0133
	static WM_CTLCOLORLISTBOX := 0x0134
	static WM_CTLCOLORBTN := 0x0135
	static WM_CTLCOLORSTATIC := 0x0138

	if (IsDarkMode)
	{
		switch uMsg
		{
			case WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
			{
				DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
				DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Controls"])
				return ControlsBackgroundBrush
			}
			case WM_CTLCOLORBTN:
			{
				return TextBackgroundBrush
			}
			case WM_CTLCOLORSTATIC:
			{
				DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
				DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Background"])
				return TextBackgroundBrush
			}
		}
	}
	return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}
