#Requires AutoHotkey v2.0
#SingleInstance force
SetCapsLockState("AlwaysOff")

; ────────────────────────────────────────────────────────────────────────────
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")

if !hVirtualDesktopAccessor {
  MsgBox "Failed to load VirtualDesktopAccessor.dll"
  ExitApp
}

if !GetDesktopCountProc {
  MsgBox "Failed to get pointer to GetDesktopCount"
  ExitApp
}


GetDesktopCount() {
  global GetDesktopCountProc
  count := DllCall(GetDesktopCountProc, "CDECL int")
  return count
}

MoveCurrentWindowToDesktop(number) {
  global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
  activeHwnd := WinGetID("A")
  DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", number, "Int")
  DllCall(GoToDesktopNumberProc, "Int", number, "Int")
}

GoToPrevDesktop() {
  global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
  current := DllCall(GetCurrentDesktopNumberProc, "Int")
  last_desktop := GetDesktopCount() - 1
  ; If current desktop is 0, go to last desktop
  if (current = 0) {
    MoveOrGotoDesktopNumber(last_desktop)
  } else {
    MoveOrGotoDesktopNumber(current - 1)
  }
  return
}

GoToNextDesktop() {
  global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
  current := DllCall(GetCurrentDesktopNumberProc, "Int")
  last_desktop := GetDesktopCount() - 1
  ; If current desktop is last, go to first desktop
  if (current = last_desktop) {
    MoveOrGotoDesktopNumber(0)
  } else {
    MoveOrGotoDesktopNumber(current + 1)
  }
  return
}

GoToDesktopNumber(num) {
  global GoToDesktopNumberProc
  DllCall(GoToDesktopNumberProc, "Int", num, "Int")
  return
}

MoveOrGotoDesktopNumber(num) {
  ; If user is holding down Mouse left button, move the current window also
  if (GetKeyState("LButton")) {
    MoveCurrentWindowToDesktop(num)
  } else {
    GoToDesktopNumber(num)
  }
  return
}

GetDesktopName(num) {
  global GetDesktopNameProc
  utf8_buffer := Buffer(1024, 0)
  ran := DllCall(GetDesktopNameProc, "Int", num, "Ptr", utf8_buffer, "Ptr", utf8_buffer.Size, "Int")
  name := StrGet(utf8_buffer, 1024, "UTF-8")
  return name
}

SetDesktopName(num, name) {
  global SetDesktopNameProc
  OutputDebug(name)
  name_utf8 := Buffer(1024, 0)
  StrPut(name, name_utf8, "UTF-8")
  ran := DllCall(SetDesktopNameProc, "Int", num, "Ptr", name_utf8, "Int")
  return ran
}

CreateDesktop() {
  global CreateDesktopProc
  ran := DllCall(CreateDesktopProc, "Int")
  return ran
}

RemoveDesktop(remove_desktop_number, fallback_desktop_number) {
  global RemoveDesktopProc
  ran := DllCall(RemoveDesktopProc, "Int", remove_desktop_number, "Int", fallback_desktop_number, "Int")
  return ran
}

GetWindowUnderCursor() {
  MouseGetPos(, , &winId)
  return winId
}

MoveWindowUnderCursorToDesktop(desktopNumber) {
  global MoveWindowToDesktopNumberProc
  hwnd := GetWindowUnderCursor()
  if !hwnd {
    MsgBox "No window under cursor"
    return
  }
  DllCall(MoveWindowToDesktopNumberProc, "Ptr", hwnd, "Int", desktopNumber, "CDECL int")
}
; ────────────────────────────────────────────────────────────────────────────

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

  local windowPosX, windowPosY, windowWidth, windowHeight

  if !watchCursorEnabled {
    CustomToolTip("")  ; Hide tooltip when disabled
    tipGui.Hide()
    return
  }

  ; Get window-relative mouse position
  MouseGetPos &localX, &localY, &id, &control
  ; Get absolute mouse position (global across all monitors)
  MouseGetAbsPos(&globalMouseX, &globalMouseY)
  ; Get the window's position and size
  WinGetPos(&windowPosX, &windowPosY, &windowWidth, &windowHeight, id)

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
    "Window position  : " windowPosX ", " windowPosY "`n"
    "Window size      : " windowWidth ", " windowHeight "`n"
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
      WinClose("PowerShell 7")
      loop 50 {
        Sleep 50
        if !WinExist("PowerShell 7") {
          break
        }
      }
      Run "wt.exe"
      loop {
        Sleep 50
        if WinExist("PowerShell 7") {
          PositionAndResize("PowerShell 7", 3546, 11, 1570, 1395)
          break
        }
      }
    } else {
      PositionAndResize("PowerShell 7", 3546, 11, 1570, 1395)
      WinActivate("PowerShell 7")
    }
  } else {
    Run "wt.exe"
    loop {
      Sleep 50
      if WinExist("PowerShell 7") {
        PositionAndResize("PowerShell 7", 3546, 11, 1570, 1395)
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

; create 4 virtual desktops if they still don't exist
if (GetDesktopCount() < 4) {
  Loop 4 {
    if (A_Index > GetDesktopCount()) {
      MsgBox "Current desktop count: " GetDesktopCount() "`nCreating desktop " A_Index
      CreateDesktop()
    }
  }
}

#1::GoToDesktopNumber(0)
#2::GoToDesktopNumber(1)
#3::GoToDesktopNumber(2)
#4::GoToDesktopNumber(3)

#+1::MoveWindowUnderCursorToDesktop(0)
#+2::MoveWindowUnderCursorToDesktop(1)
#+3::MoveWindowUnderCursorToDesktop(2)
#+4::MoveWindowUnderCursorToDesktop(3)

; print desktop count with Win + 5 for testing purposes
#5::
{
  count := GetDesktopCount()
  MsgBox "Desktop count: " count
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

:*?:;eur::€
:*?:;gbp::£
:*?:;tm::™
:*?:;shrug::¯\(ツ)/¯
:*?:;lenny::( ͡° ͜ʖ ͡°)
:*?:;reg::®

; :*?:h'::ä
; :*?:h;::ö
; :*?:;...::…
; :*?:;ae::≈
; :*?:;ao::å
; :*?:;b::•
; :*?:;copy::©
; :*?:;da::↓
; :*?:;deg::°
; :*?:;dis::ಠ_ಠ
; :*?:;es::☆
; :*?:;fs::★
; :*?:;half::½
; :*?:;la::←
; :*?:;md::—
; :*?:;mid::·
; :*?:;nb::  ;; non-breaking space
; :*?:;nd::–
; :*?:;ne::≠
; :*?:;pm::±
; :*?:;ra::→
; :*?:;sup0::⁰
; :*?:;sup1::¹
; :*?:;sup2::²
; :*?:;sup3::³
; :*?:;sup4::⁴
; :*?:;sup5::⁵
; :*?:;sup6::⁶
; :*?:;sup7::⁷
; :*?:;sup8::⁸
; :*?:;sup9::⁹
; :*?:;ua::↑
; :*?:;x::×

;; ───────────────────────────────────────────────────────────────────────────
