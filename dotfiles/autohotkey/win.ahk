#Requires AutoHotkey v2.0
#SingleInstance force
SetCapsLockState("AlwaysOff")

global watchCursorEnabled := false

global globalMouseX := 0, globalMouseY := 0
global lastGlobalMouseX := 0, lastGlobalMouseY := 0

global tipGui := Gui(, "Custom Tooltip")  
tipGui.SetFont("s10 cWhite", "Cascadia Mono")
tipGui.Opt("+AlwaysOnTop +ToolWindow -Caption +Border +OwnDialogs")
tipGui.BackColor := "Black"

global tipText := tipGui.Add("Text", "xm ym w800 h120", "")
tipText.SetFont("s10 cWhite", "Cascadia Mono")

SetTimer WatchCursor, 150, 0 ; Start the timer

; Windows API function to get ABSOLUTE global coordinates
MouseGetAbsPos(&x, &y) {
  pt := Buffer(8)  ; Allocate an 8-byte buffer for POINT struct (X and Y)
  DllCall("GetCursorPos", "Ptr", pt)  ; Call Windows API to get absolute cursor position
  x := NumGet(pt, 0, "Int")  ; Extract X coordinate (first 4 bytes)
  y := NumGet(pt, 4, "Int")  ; Extract Y coordinate (next 4 bytes)
}

CustomToolTip(text, x := 10, y := 10) {
  global tipGui, tipText
  if text = "" {
    tipGui.Hide()
    return
  }
  tipText.Text := text
  tipGui.Show("NoActivate AutoSize x" x " y" y)
}

WatchCursor() {
  global tipGui
  global watchCursorEnabled
  global globalMouseX, globalMouseY
  global lastGlobalMouseX, lastGlobalMouseY
  static lastId := "", lastX := "", lastY := ""

  if !watchCursorEnabled {
    CustomToolTip("")  ; Hide tooltip when disabled
    tipGui.Hide()
    return
  }

  ; Get window-relative mouse position
  MouseGetPos &localX, &localY, &id, &control

  ; Get absolute mouse position (global across all monitors)
  MouseGetAbsPos(&globalMouseX, &globalMouseY)

  ; Avoid redundant updates to reduce stutter
  if (id = lastId && localX = lastX && localY = lastY) {
    return
  }

  if (lastGlobalMouseX = globalMouseX && lastGlobalMouseY = globalMouseY) {
    return
  }

  lastId := id
  lastX := localX, lastY := localY
  lastGlobalMouseX := globalMouseX, lastGlobalMouseY := globalMouseY

  CustomToolTip(
    "window_title     : " WinGetTitle(id) "`n"
    "ahk_id           : " id "`n"
    "ahk_class        : " WinGetClass(id) "`n"
    "Control          : " control "`n"
    "Local mouse pos  : " localX ", " localY "`n"
    "Global mouse pos : " globalMouseX ", " globalMouseY "`n",
    10, 10  ; Fixed tooltip position
  )
}

PositionAndResize(winTitle, posX, posY, sizeX, sizeY) {
  hwnd := WinExist(winTitle)  ; Get the window handle (HWND)
  if !hwnd {
      MsgBox "Error: Window not found!"
      return
  }

  ; Move and resize the window
  DllCall("MoveWindow", "Ptr", hwnd, "Int", posX, "Int", posY, "Int", sizeX, "Int", sizeY, "Int", true)
}

CapsLock & c:: {
  global watchCursorEnabled
  global tipGui
  watchCursorEnabled := !watchCursorEnabled
  if watchCursorEnabled {
    SetTimer WatchCursor, 120  ; Start the timer
  } else {
    SetTimer WatchCursor, 0    ; Stop the timer
    tipGui.Hide()
  }
}

CapsLock & Enter:: {
  if WinExist("PowerShell 7") {
    if GetKeyState("Shift", "P") {
      ; If Shift is pressed, we completely restart the terminal
      WinClose("PowerShell 7")
      Loop 50 {
        Sleep 50
        if !WinExist("PowerShell 7") {
          break
        }
      }
      Run "wt.exe"
      Loop {
        Sleep 50
        if WinExist("PowerShell 7") {
          PositionAndResize("PowerShell 7", 1930, 10, 1900, 1060)
          break
        }
      }
    } else {
      ; If Shift is not pressed, we just bring the terminal to the front in the correct position
      PositionAndResize("PowerShell 7", 1930, 10, 1900, 1060)
      WinActivate("PowerShell 7")
    }
  } else {
    Run "wt.exe"
    Loop {
      Sleep 50
      if WinExist("PowerShell 7") {
        PositionAndResize("PowerShell 7", 1930, 10, 1900, 1060)
        break
      }
    }
  }
}

#Enter:: {
  Run "wt.exe"
}

::=dt:: ; Timestamp with =dt
{
  now := FormatTime(, "yyyy-MM-dd HH:mm:ss")
  Send now
}

::ccc:: ; Triple backticks block with ccc
{
  SendText "``````"
  Send "{Enter 2}"
  SendText "``````"
  Send "{Up}"
}

;; ┌─────────────────────────────────────────────────────────────────────────┐
;; │ Quick strings                                                           │
;; └─────────────────────────────────────────────────────────────────────────┘
:*?b0:dash;:: ; `&ndash;` won't produce `&ndasö`
{
    ;; do nothing
}
:*?b0:length;:: ; `foo.length;` won't produce `foo.lengtö`
{
    ;; do nothing
}
:*?:h'::ä
:*?:h;::ö
:*?:;...::…
:*?:;ae::≈
:*?:;ao::å
:*?:;b::•
:*?:;copy::©
:*?:;da::↓
:*?:;deg::°
:*?:;dis::ಠ_ಠ
:*?:;es::☆
:*?:;eur::€
:*?:;gbp::£
:*?:;fs::★
:*?:;half::½
:*?:;la::←
:*?:;lenny::( ͡° ͜ʖ ͡°)
:*?:;md::—
:*?:;mid::·
:*?:;nb::  ;; non-breaking space
:*?:;nd::–
:*?:;ne::≠
:*?:;pm::±
:*?:;ra::→
:*?:;reg::®
:*?:;shrug::¯\(ツ)/¯
:*?:;sup0::⁰
:*?:;sup1::¹
:*?:;sup2::²
:*?:;sup3::³
:*?:;sup4::⁴
:*?:;sup5::⁵
:*?:;sup6::⁶
:*?:;sup7::⁷
:*?:;sup8::⁸
:*?:;sup9::⁹
:*?:;tm::™
:*?:;ua::↑
:*?:;x::×
;; ───────────────────────────────────────────────────────────────────────────
