#Requires AutoHotkey v2.0

; 每10秒檢查一次
SetTimer(CheckIdle, 10000)

CheckIdle() {

    ; 超過60秒沒操作
    if (A_TimeIdlePhysical > 60000) {

        ; 按一次 F24
        ; 幾乎沒有程式會用到
        SendInput("{F24}")

        ToolTip("Keep Alive: " FormatTime(, "HH:mm:ss"))

        SetTimer(() => ToolTip(), -1000)
    }
}