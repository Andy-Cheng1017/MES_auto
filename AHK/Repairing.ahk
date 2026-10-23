#Requires AutoHotkey v2.0
#SingleInstance Force

#Include _JXON.ahk

#include FindText.ahk
FindText(, , 0)

LogEnabled := false

global MES_Win := "ahk_exe Sajet MES.exe"

Main()

Main() {
    global MES_Win

    jobs := LoadJobs()

    Log("========== START ==========")
    Log("Total Jobs = " jobs.Length)

    MsgBox "讀取完成"

    if !WinActive(MES_Win) {
        MsgBox "MES 視窗未作用中，已停止作業"
        return
    }

    for job in jobs {
        try
        {
            RepairOne(job)
            Sleep 500

            Log(
                job["SN"]
                " SUCCESS"
            )
        }
        catch Error as err {
            Log(
                job["SN"]
                " FAILED : "
                err.Message
            )
            MsgBox "作業失敗，批次已停止。請先確認 MES 中此筆資料狀態。`nSN: " job["SN"] "`n" err.Message
            break
        }
    }

    Log("========== END ==========")

}

LoadJobs() {
    file := A_ScriptDir "\..\History\MES_Jobs.json"

    if !FileExist(file)
        throw Error("JSON不存在")

    jsonText := FileRead(file, "UTF-8")

    return Jxon_Load(&jsonText)
}

RepairOne(job) {
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

SetField(suffix, value) {
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

InputSN(sn) {
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

SaveMES(job) {
    global MES_Win

    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")

    ClickImage("Save")

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
        if !WinWaitActive("Scrap SN", , 3)
            throw Error("等待報廢視窗 Scrap SN 逾時")

        ctrl := Find_Wait_Control("Scrap SN", "WindowsForms10.EDIT.app.0.", "_ad11")
        SetText_Retry job["RootCause"], ctrl, "Scrap SN"
        ClickImage("報廢儲存")
    } else {
        ctrl := Find_Wait_Control(MES_Win, "WindowsForms10.BUTTON.app.0.", "_ad16")
        ControlFocus ctrl, MES_Win
        ControlClick ctrl, MES_Win
        Sleep 800

        if (job["ReturnStation"] == "FNT2") {
            ClickImage("FNT2")
        } else if (job["ReturnStation"] == "FNT3") {
            MsgBox "選擇 FNT3"
            ClickImage("FNT3")
        } else if (job["ReturnStation"] == "FNT7") {
            ClickImage("FNT7")
        } else {
            throw Error("不支援的返站站別: " job["ReturnStation"])
        }

        ; MsgBox "完成"

        ClickImage("返站儲存")
    }
}

ClickImage(label, timeoutMs := 5000) {
    if label = "" || timeoutMs <= 0
        throw ValueError("圖片名稱不可為空，逾時時間必須大於零")
    hwnd := WinExist("A")
    if !hwnd
        throw Error("找不到作用中視窗: " label)
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    dpi := DllCall("GetDpiForWindow", "Ptr", hwnd, "UInt")
    display := ImageDisplaySettings(hwnd)
    context := "DisplayV2|" label "|" display
    key := "DisplayV2-" Format("{:08X}", DllCall("ntdll\RtlComputeCrc32", "UInt", 0,
        "Ptr", StrPtr(context), "UInt", StrLen(context) * 2, "UInt"))
    config := ImageSearchConfig()
    saved := IniRead(config, key, "Target", "")
    needsConfirmation := saved = ""
    candidates := []
    if saved != "" {
        candidates.Push(ParseImageTarget(saved, config, label))
    } else {
        if FileExist(config) {
            seen := Map()
            for section in StrSplit(IniRead(config), "`n", "`r") {
                if !RegExMatch(section, "^[0-9A-Fa-f]{8}$") || IniRead(config, section, "Label", "") != label
                    continue
                target := ParseImageTarget(IniRead(config, section, "Target", ""), config, label)
                if !seen.Has(target.pattern) {
                    candidates.Push(target)
                    seen[target.pattern] := true
                }
            }
        }
    }
    tryingLegacy := needsConfirmation && candidates.Length > 0
    if !candidates.Length
        candidates.Push(ParseImageTarget(CaptureImagePattern(label, hwnd), config, label, false))

    started := A_TickCount
    loop {
        if A_TickCount - started >= timeoutMs {
            if !tryingLegacy
                break
            Log(label " legacy images did not match; requesting capture")
            candidates := [ParseImageTarget(CaptureImagePattern(label, hwnd), config, label, false)]
            tryingLegacy := false
            started := A_TickCount
        }
        position := CheckImageWindow(hwnd, ww, wh, dpi, label, display)
        wx := position[1], wy := position[2]
        match := 0
        for candidate in candidates {
            pattern := candidate.pattern, cached := candidate.cached
            if cached is Array {
                cx := wx + cached[1], cy := wy + cached[2]
                radiusX := Ceil(cached[3] / 2) + 64
                radiusY := Ceil(cached[4] / 2) + 64
                left := Max(wx, cx - radiusX)
                top := Max(wy, cy - radiusY)
                right := Min(wx + ww - 1, cx + radiusX)
                bottom := Min(wy + wh - 1, cy + radiusY)
                if left < right && top < bottom
                    match := FindText(&x, &y, left, top, right, bottom, 0, 0, pattern, 1, 0)
            }
            if !match
                match := FindText(&x, &y, wx, wy, wx + ww - 1, wy + wh - 1, 0, 0, pattern, 1, 0)
            if match
                break
        }

        if match {
            entry := match[1]
            if needsConfirmation {
                FindText().RangeTip(entry.%1%, entry.%2%, entry.%3%, entry.%4%)
                try answer := MsgBox("已辨識到「" label "」，位置 (" x ", " y ")。`n"
                    "請確認紅框內是要點擊的目標。`n"
                    "圖片可能來自舊紀錄；按「確定」儲存至目前螢幕設定並點擊，取消則停止。",
                    "確認圖片設定", "OKCancel")
                finally FindText().RangeTip()
                if answer != "OK"
                    throw Error("已取消圖片確認: " label)
                WinActivate("ahk_id " hwnd)
                if !WinWaitActive("ahk_id " hwnd, , 3)
                    throw Error("無法返回目標視窗: " label)
                needsConfirmation := false
                tryingLegacy := false
                candidates := [{pattern: pattern, cached: cached}]
                ; The confirmation dialog covered the screen; recognize again before clicking.
                started := A_TickCount
                continue
            }

            value := pattern "`t" (x - wx) "," (y - wy) "," entry.%3% "," entry.%4%
            if saved != value {
                IniWrite(label, config, key, "Label")
                IniWrite(display, config, key, "Display")
                IniWrite(value, config, key, "Target")
            }
            position := CheckImageWindow(hwnd, ww, wh, dpi, label, display)
            if position[1] != wx || position[2] != wy
                throw Error("點擊前視窗位置已改變: " label)
            FindText().Click(x, y, "L")
            Log(label " searchMs=" (A_TickCount - started))
            return true
        }

        Sleep 200
    }

    throw Error("找不到 " label " 按鈕/畫面，等待 " timeoutMs " ms 後逾時")
}

ImageDisplaySettings(hwnd) {
    monitor := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")
    info := Buffer(40, 0)
    NumPut("UInt", info.Size, info)
    if !monitor || !DllCall("GetMonitorInfoW", "Ptr", monitor, "Ptr", info, "Int")
        throw OSError(, , "無法取得 MES 所在螢幕的設定")
    width := NumGet(info, 12, "Int") - NumGet(info, 4, "Int")
    height := NumGet(info, 16, "Int") - NumGet(info, 8, "Int")
    dpi := DllCall("GetDpiForWindow", "Ptr", hwnd, "UInt")
    if dpi = 0
        throw Error("無法取得 MES 視窗 DPI")
    return width "x" height "@" dpi
}

ParseImageTarget(value, config, label, hasPosition := true) {
    cached := ""
    if hasPosition {
        fields := StrSplit(value, "`t")
        if fields.Length != 2 || !RegExMatch(fields[2], "^-?\d+,-?\d+,[1-9]\d*,[1-9]\d*$")
            throw Error("圖片快取格式不正確，請刪除後重試: " config)
        pattern := fields[1], cached := StrSplit(fields[2], ",")
    } else {
        pattern := value
    }
    if !RegExMatch(pattern, "^\|<[^>|`t\r\n]*>[^$|`t\r\n]+\$[^|`t\r\n]+$")
        || !IsObject(FindText().PicInfo(pattern))
        throw Error("圖片資料不正確，請重新擷取: " label " / " config)
    return {pattern: pattern, cached: cached}
}

CaptureImagePattern(label, hwnd) {
    answer := MsgBox("尚未設定「" label "」的圖片。`n"
        "接著會啟動 FindText「抓圖」：`n"
        "1. 將滑鼠移到目標，選框會跟隨滑鼠。`n"
        "2. 用左／右方向鍵縮小／放大寬度，上／下方向鍵縮小／放大高度。`n"
        "3. 按一下 Ctrl 固定選框，將滑鼠移開，再按一下 Ctrl 完成抓圖。`n"
        "4. 選擇二值化方式（例如「灰度閾值」），按二值化。`n"
        "5. 按「確定」，程式會測試辨識並請你確認目標。`n"
        "不需複製程式碼；取消會停止本次作業。",
        "首次擷取圖片", "OKCancel")
    if answer != "OK"
        throw Error("已取消圖片擷取: " label)
    WinActivate("ahk_id " hwnd)
    if !WinWaitActive("ahk_id " hwnd, , 3)
        throw Error("無法返回目標視窗: " label)
    pattern := FindText().CapturePattern()
    if pattern = ""
        throw Error("未完成圖片擷取: " label)
    WinActivate("ahk_id " hwnd)
    if !WinWaitActive("ahk_id " hwnd, , 3)
        throw Error("無法返回目標視窗: " label)
    return pattern
}

CheckImageWindow(hwnd, width, height, dpi, label, display) {
    if !WinActive("ahk_id " hwnd)
        throw Error("辨識期間作用中視窗已改變: " label)
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    if w != width || h != height || DllCall("GetDpiForWindow", "Ptr", hwnd, "UInt") != dpi
        throw Error("辨識期間視窗尺寸或 DPI 已改變，請重試: " label)
    if ImageDisplaySettings(hwnd) != display
        throw Error("辨識期間螢幕設定已改變，請重試: " label)
    return [x, y]
}

ImageSearchConfig() {
    folder := A_ScriptDir "\..\Config\ImageSearch"
    DirCreate(folder)
    name := RegExReplace(A_ComputerName "-" A_UserName, '[<>:"/\\|?*]', "_")
    return folder "\" name ".ini"
}

Log(text) {
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

SetRepairDesc(job) {
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

    if Trim(job["BoardNo"]) != "" {
        text .= ", " job["Layer"] " SN:" job["BoardNo"]
    }

    SetText_Retry text, ctrl, MES_Win

    Sleep 200
}

Find_Wait_Control(win, patterns*) {
    startTime := A_TickCount

    while (A_TickCount - startTime < 3000) {
        try controls := WinGetControls(win)
        catch
            controls := []

        for ctrl in controls {
            found := true

            for pattern in patterns {
                if !InStr(ctrl, pattern) {
                    found := false
                    break
                }
            }

            if found
                return ctrl
        }

        Sleep 100
    }

    throw Error("等待控制項逾時: " win " / " StrJoin(patterns, ", "))
}
StrJoin(arr, sep := ", ") {
    txt := ""

    for item in arr {
        if txt != ""
            txt .= sep

        txt .= item
    }

    return txt
}

SetText_Retry(value, ctrl, winTitle, retryCount := 3) {
    lastError := ""

    loop retryCount {
        try
        {
            ControlFocus(ctrl, winTitle)
            Sleep 100
            ControlSetText(value, ctrl, winTitle)
            Sleep 100
            currentText := ControlGetText(ctrl, winTitle)

            if (Trim(currentText) = Trim(value))
                return true

            lastError := "讀回文字與預期不符"
        }
        catch Error as err
            lastError := err.Message

        Sleep 300
    }

    throw Error("無法設定控制項 " ctrl " (" winTitle ")，重試 " retryCount " 次。" lastError)
}
