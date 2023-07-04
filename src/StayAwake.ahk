; ===========================================================================================================================================================================

/*
    Stay Awake Light mod by sergrt based on Stay Awake by jNizM:
	
	Stay Awake (written in AutoHotkey)

	Author ....: jNizM
	Released ..: 2021-10-21
	Modified ..: 2021-11-16
	License ...: MIT
	GitHub ....: https://github.com/jNizM/stay-awake
	Forum .....: https://www.autohotkey.com/boards/viewtopic.php?t=95857
*/


; SCRIPT DIRECTIVES =========================================================================================================================================================

#Requires AutoHotkey v2.0-

#SingleInstance
Persistent


; GLOBALS ===================================================================================================================================================================

app := Map("name", "Stay Awake Light", "version", "0.5.1", "release", "2023-06-30", "author", "sergrt", "licence", "MIT")

; TRAY ======================================================================================================================================================================

TrayMain := A_TrayMenu
TrayMain.Delete()

TrayMode := Menu()
TrayMode.Add("Enabled", EnableStayAwake, "+Radio")
TrayMode.Add("Disabled", DisableStayAwake, "+Radio")

TrayTemp := Menu()
TrayTemp.Add("1 hour", SetTemporarily1Hour, "+Radio")
TrayTemp.Add("2 hours", SetTemporarily2Hours, "+Radio")
TrayTemp.Add("4 hours", SetTemporarily4Hours, "+Radio")
TrayTemp.Add("8 hours", SetTemporarily8Hours, "+Radio")
TrayTemp.Add("10 hours", SetTemporarily10Hours, "+Radio")
TrayMode.Add("Enabled for period", TrayTemp, "+Radio")

TrayMain.Add("Mode", TrayMode)
TrayMain.Add("Keep Screen On", SetDisplayOn)
TrayMain.Add("Exit", ExitFunc)


; FUNCTIONS =================================================================================================================================================================

Restart()
{
	StayAwake.Stop()
	StayAwake.Start()
}

UncheckAll()
{
	TrayMode.Uncheck("Enabled")
	TrayMode.Uncheck("Disabled")
	TrayMode.Uncheck("Enabled for period")
	TrayTemp.Uncheck("1 hour")
	TrayTemp.Uncheck("2 hours")
	TrayTemp.Uncheck("4 hours")
	TrayTemp.Uncheck("8 hours")
	TrayTemp.Uncheck("10 hours")
}

EnableStayAwake(ItemName, ItemPos, *)
{
	UncheckAll()
	TrayMode.Check(ItemName)
	StayAwake.Period := 0
	Restart()
}

DisableStayAwake(ItemName, ItemPos, *)
{
	UncheckAll()
	TrayMode.Check(ItemName)
	StayAwake.Stop()
}

SetTemporarilyImpl(ItemName, hours)
{
	UncheckAll()
	TrayMode.Check("Enabled for period")
	TrayTemp.Check(ItemName)
	StayAwake.Period := 1000 * (hours * 3600)
	Restart()
}

SetTemporarily1Hour(ItemName, ItemPos, *)
{
	SetTemporarilyImpl(ItemName, 1)
}

SetTemporarily2Hours(ItemName, ItemPos, *)
{
	SetTemporarilyImpl(ItemName, 2)
}

SetTemporarily4Hours(ItemName, ItemPos, *)
{
	SetTemporarilyImpl(ItemName, 4)
}

SetTemporarily8Hours(ItemName, ItemPos, *)
{
	SetTemporarilyImpl(ItemName, 8)
}

SetTemporarily10Hours(ItemName, ItemPos, *)
{
	SetTemporarilyImpl(ItemName, 10)
}

SetDisplayOn(ItemName, ItemPos, *)
{
	TrayMain.ToggleCheck(ItemName)

    ; -1 handles unconditional enable at program startup
	if (ItemPos = -1 || MenuCheckState(TrayMain.Handle, ItemPos))
	{
		StayAwake.Flags := "DisplayOn"
	}
	else
	{
		StayAwake.Flags := ""
	}
	
	Restart()
}

MenuCheckState(Handle, Item)
{
	static MF_BYPOSITION := 0x00000400
	static MF_CHECKED    := 0x00000008

	MenuState := DllCall("user32\GetMenuState", "Ptr", Handle, "UInt", Item - 1, "UInt", MF_BYPOSITION, "UInt")
	if (MenuState = -1)
		return -1
	return !!(MenuState & MF_CHECKED)
}

ExitFunc(*)
{
	StayAwake.Stop()
	ExitApp
}


; Auto start with default params ============================================================================================================================================

SetDisplayOn("Keep Screen On", -1)
EnableStayAwake("Enabled", -1)

; CLASS =====================================================================================================================================================================

class StayAwake
{
	static Timer  := 0
	static Period := 0
	static Flags  := ""


	Flags[Flags]
	{
		set => Flags
	}


	Period[Period]
	{
		set => Period
	}


	;static TimeLeft() => (this.StartTime + this.Period) - A_TickCount


	static Start()
	{
		this.Timer := Timer := this.RunLoop.bind(this)
		SetTimer Timer, 60000

		if (this.Period > 0)
		{
			this.RunOnce := RunOnce := this.StopByTimer.bind(this)
			this.StartTime := A_TickCount
			SetTimer RunOnce, - this.Period
		}
	}


	static Stop()
	{
		this.SetState(this.EXECUTION_STATE.CONTINUOUS)
		if (Timer := this.Timer)
			SetTimer Timer, 0
	}


	static StopByTimer()
	{
		this.Stop()
		UncheckAll()
		TrayMode.Check("Disabled")
	}


	static RunLoop()
	{
		switch this.Flags
		{
			case "DisplayOn":
				this.SetState(this.EXECUTION_STATE.CONTINUOUS | this.EXECUTION_STATE.SYSTEM_REQUIRED | this.EXECUTION_STATE.DISPLAY_REQUIRED)
			case "AwayMode":
				this.SetState(this.EXECUTION_STATE.CONTINUOUS | this.EXECUTION_STATE.SYSTEM_REQUIRED | this.EXECUTION_STATE.AWAYMODE_REQUIRED)
			default:
				this.SetState(this.EXECUTION_STATE.CONTINUOUS | this.EXECUTION_STATE.SYSTEM_REQUIRED)
		}
	}


	static SetState(State)
	{
		try
		{
			if (EXECUTION_STATE := DllCall("kernel32\SetThreadExecutionState", "UInt", State) != 0)
				return EXECUTION_STATE
		}
		catch
		{
			throw Error("SetThreadExecutionState failed", -1)
		}
	}


	class EXECUTION_STATE
	{
		static AWAYMODE_REQUIRED := 0x00000040
		static CONTINUOUS        := 0x80000000
		static DISPLAY_REQUIRED  := 0x00000002
		static SYSTEM_REQUIRED   := 0x00000001
	}
}


; ===========================================================================================================================================================================
