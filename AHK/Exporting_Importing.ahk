#Requires AutoHotkey v2.0
#SingleInstance Force

#Include _JXON.ahk

LogEnabled := false

global MES_Win := "ahk_exe Sajet MES.exe"

Main()

Main()
{
    jobs := LoadJobs()

    Log("========== START ==========")
    Log("Total Jobs = " jobs.Length)

    MsgBox "讀取完成"
    if !WinActive("ahk_exe Sajet MES.exe")
        return

    for job in jobs
    {
        try
        {
            InputSN(job["SN"])
            Sleep 50

            Log(
                job["SN"]
                " SUCCESS"
            )
        }
        catch Error as err
        {
            Log(
                job["SN"]
                " FAILED : "
                err.Message
            )
        }
    }

    Log("========== END ==========")

}

LoadJobs()
{
    file := A_ScriptDir "\MES_Jobs.json"

    if !FileExist(file)
        throw Error("JSON不存在")

    jsonText := FileRead(file, "UTF-8")

    return Jxon_Load(&jsonText)
}

InputSN(sn) {

    global MES_Win

    ctrl := Find_Wait_Control(
        MES_Win,
        "WindowsForms10.EDIT.app.0.",
        "_r21_ad11"
    )

    if !ctrl
        throw Error("找不到SN欄位")

    SetText_Retry sn, ctrl, MES_Win

    Sleep 50

    Send "{Enter}"

}

Find_Wait_Control(win, patterns*)
{
    startTime := A_TickCount

    while (A_TickCount - startTime < 3000)
    {
        for ctrl in WinGetControls(win)
        {
            found := true

            for pattern in patterns
            {
                if !InStr(ctrl, pattern)
                {
                    found := false
                    break
                }
            }

            if found
                return ctrl
        }

        Sleep 50
    }

    MsgBox ("WaitControl Timeout: " . StrJoin(patterns, ", "))
}

StrJoin(arr, sep := ", ")
{
    txt := ""

    for item in arr
    {
        if txt != ""
            txt .= sep

        txt .= item
    }

    return txt
}

SetText_Retry(value, ctrl, winTitle, retryCount := 3)
{
    Loop retryCount
    {
        ControlFocus(ctrl, winTitle)

        Sleep 10

        ControlSetText(value, ctrl, winTitle)

        Sleep 10

        try currentText := ControlGetText(
            ctrl,
            winTitle
        )
        catch
            currentText := ""

        if (Trim(currentText) = Trim(value))
            return true

        Sleep 100
    }

    return false
}

Log(text)
{
    global LogEnabled

    if !LogEnabled
        return

    logFile := A_ScriptDir "\MES_Log.txt"

    FileAppend(
        FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        " | "
        text
        "`n",
        logFile,
        "UTF-8"
    )
}