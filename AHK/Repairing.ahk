#Requires AutoHotkey v2.0
#SingleInstance Force

#Include _JXON.ahk

#include FindText.ahk
FindText(, , 0)

LogEnabled := false

SaveButton :=
    "|<>*181$82.zjzztzzzzzzzzzYynzbzzzzzzzzw0UC003sw3zs3bk01s00DbV7z0CDDybyDzwySTszwwUkTtzznttnXzlW00z00SDX7CDzaDyTsU1tz0wwTyEUnz7yDbw7nkTsW21sTlyTUCDkTXDk7VzDtwQNzUzAU7Sk03bXs7zVwm21z00CSDkzz7n987xzDtszXzwSAYbTrwzbXwDbltm21zTnyT0020Db887xkTwy0s81yQYbTr1znzzzzznzzzzzzzbzzzzzDzzzzzzyTzzzzts"

SaveButton_2 :=
    "|<>*182$89.yHvDyTzzzzzzzzzs10Q007ls7zk7Dzm01s00DbV7z0CDzbzHz7zyTDDwTyTz8A7yTzwySQszwTwE07s03lwMtlzwzsztzW07bw3nlztzV1byDwTDsDbUzlzW21sTlyTWCDkTXzbs3kzbwyCAzsTbz81rg00tsy1zsTDyEEDs01nly7zsyTwYUTrwzbXyDzlszt9CzjtzD7sTDXnzm21zTnyT0020DbzY43ysDyT0Q40zDz99rxkTwzzzzzwzzzzzzzzwzzzzztzU"

FNT2 :=
    "|<>*129$103.zyTsDU400DwQ1bzky0UA0MES0060C0k40VUE6080N00307UM20UE830A00U01U3EA100A41U600E00k1g60U0620k1U0800M0n30E0210M0s0400A0NVU8030UDs702007wAMk4010E600s10TX066M201U8300C0U01U33A101U41U030E00k1Uq0U1U20k01U800M0kD0E1U10M00k400A0M7U81U0UA0kk20060A1k41U0E7y7kTw03060M21zo"

FNT7 :=
    "|<>*161$106.00000000000000000000000000000000000000000000000000000zyTsDU400DwQ1bzrzU61U333k00k1k60k060M60M0P00307UM300k1UM1U0A00A0T1UA03061U600k00k1g60k0M0M60Q0300306MM301U1UM0w0A00A0NlUA0A061z0s0k00zlX60k0k0M601s30zX066M30701UM01kA00A0MNUA0M061U030k00k1Uq0k1U0M600A3003061s30A01UM00kA00A0M7UA0k061U660k00k1UC0k600M7yDkTw03060M30M0000000000000000002"


t1 := A_TickCount, Text := X := Y := ""

global MES_Win := "ahk_exe Sajet MES.exe"

Main()

Main()
{
    jobs := LoadJobs()

    Log("========== START ==========")
    Log("Total Jobs = " jobs.Length)

    MsgBox "讀取完成"

    for job in jobs
    {
        try
        {
            RepairOne(job)
            Sleep 500

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
    file := A_ScriptDir "\..\History\MES_Jobs.json"

    if !FileExist(file)
        throw Error("JSON不存在")

    jsonText := FileRead(file, "UTF-8")

    return Jxon_Load(&jsonText)
}

RepairOne(job)
{
    InputSN(
        job["SN"]
    )

    SetField("_ad15", job["FaultCode"])

    if (job["FaultCode"] != "CP6008" && job["FaultCode"] != "CP6001" && job["FaultCode"] !=
        "CP6045" && job["FaultCode"] != "CP6078") {
        SetField("_ad14", job["RespCode"])
        Sleep 200
    }

    if job["Location"] {
        SetField_Edit("Edit1", job["Location"])
        Sleep 500
    }


    SetField("_ad13", job["RepairCode"])
    Sleep 200

    SetRepairDesc(job)
    Sleep 200
    ; MsgBox "暫停"


    SaveMES(job)
}

SetField_Edit(suffix, value) {

    global MES_Win

    SetText_Retry value, suffix, MES_Win

    Sleep 300
    Send "{Enter}"
    Sleep 500
    Send "{UP}"
    Sleep 100

}

SetField(suffix, value)
{
    global MES_Win

    ctrl := Find_Wait_Control(
        MES_Win,
        "WindowsForms10.EDIT.app.0.",
        suffix
    )

    if !ctrl
        throw Error(
            "找不到控制項 "
            suffix
        )

    SetText_Retry value, ctrl, MES_Win

    Send "{Enter}"

    Sleep 200
}

InputSN(sn)
{
    global MES_Win

    ctrl := Find_Wait_Control(
        MES_Win,
        "WindowsForms10.EDIT.app.0.",
        "_ad11"
    )

    if !ctrl
        throw Error("找不到SN欄位")

    SetText_Retry sn, ctrl, MES_Win

    Sleep 100

    Send "{Enter}"

    Sleep 200

    ctrl := Find_Wait_Control(MES_Win, "WindowsForms10.BUTTON.app.0.", "_ad112")
    if !ctrl
        throw Error("找不到維修按鈕")

    ControlFocus ctrl, MES_Win
    ControlClick ctrl, MES_Win
}

SaveMES(job)
{
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")

    if (ok := FindText(&X, &Y, 353 - 3000, 81 - 3000, 353 + 3000, 81 + 3000, 0, 0,
        SaveButton))
    {
        FindText().Click(X, Y, "L")
    } else {
        MsgBox "找不到SaveButton"
    }

    if (job["RepairCode"] == "*CIPS-PE-004*") {
        ctrl := Find_Wait_Control(MES_Win, "WindowsForms10.BUTTON.app.0.", "_ad15")
        ControlFocus ctrl, MES_Win
        ControlClick ctrl, MES_Win
        ctrl := Find_Wait_Control(MES_Win, "Button1")
        Sleep 100
        ControlFocus ctrl, MES_Win
        ControlClick ctrl, MES_Win
        Sleep 100
        Send "{Enter}"
        Sleep 500
        WinActivate("Scrap SN")
        ctrl := Find_Wait_Control("Scrap SN", "WindowsForms10.EDIT.app.0.", "_ad11")
        SetText_Retry job["RootCause"], ctrl, MES_Win
        ; MsgBox ControlGetText(ctrl, "Scrap SN")
        if (ok := FindText(&X, &Y, 785 - 3000, 396 - 3000, 785 + 3000, 396 + 3000, 0, 0,
            SaveButton_2)) {
            MsgBox "找到SaveButton"
            FindText().Click(X, Y, "L")
        }
        else
            MsgBox "找不到SaveButton"
    } else {
        ctrl := Find_Wait_Control(MES_Win, "WindowsForms10.BUTTON.app.0.", "_ad16")
        ControlFocus ctrl, MES_Win
        ControlClick ctrl, MES_Win
        Sleep 800

        if (job["ReturnStation"] == "FNT2") {
            if (ok := FindText(&X, &Y, 587 - 3000, 343 - 3000, 587 + 3000, 343 + 3000, 0, 0, FNT2))
                FindText().Click(X, Y, "L")
            else
                MsgBox "找不到FNT2"
        } else if (job["ReturnStation"] == "FNT7") {
            if (ok := FindText(&X, &Y, 589 - 150000, 390 - 150000, 589 + 150000, 390 + 150000, 0, 0,
                FNT7))
                FindText().Click(X, Y, "L")
            else
                MsgBox "找不到FNT7"
        } else {
            MsgBox "ReturnStation錯誤"
        }


        ; MsgBox "完成"

        if (ok := FindText(&X, &Y, 568 - 3000, 216 - 3000, 568 + 3000, 216 + 3000, 0, 0,
            SaveButton_2))
            FindText().Click(X, Y, "L")
        else
            MsgBox "找不到SaveButton"
    }
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

SetRepairDesc(job)
{
    global MES_Win

    ctrl := Find_Wait_Control(
        MES_Win,
        "WindowsForms10.RichEdit20W.app.0.",
        "_ad11"
    )

    if !ctrl
        throw Error("找不到 RepairDesc")

    text := job["Layer"] "/" job["Location"] "/" job["Symptom"] ", " job["RootCause"] ", " job[
        "RepairAction"]

    if Trim(job["BoardNo"]) != ""
    {
        text .= ", " job["Layer"] " SN:" job["BoardNo"]
    }

    SetText_Retry text, ctrl, MES_Win

    Sleep 200
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

        Sleep 100
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

        Sleep 100

        ControlSetText(value, ctrl, winTitle)

        Sleep 100

        try currentText := ControlGetText(
            ctrl,
            winTitle
        )
        catch
            currentText := ""

        if (Trim(currentText) = Trim(value))
            return true

        Sleep 500
    }

    return false
}