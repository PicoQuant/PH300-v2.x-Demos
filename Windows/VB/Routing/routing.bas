Attribute VB_Name = "Module1"
'+==========================================================
'
'  ROUTING.bas
'  A simple demo how to use the PicoHarp 300 programming library
'  PHLIB.DLL v.2.3 from Visual Basic in a routing setup.
'  This requires a PHR 40x or PHR 800 router.
'  The program uses a text console for user input/output
'
'  Note v2.x: This is now a multi-device library. All functions
'  take a device index. New functions for Open and Close.
'
'  (c) Michael Wahl, PicoQuant GmbH, April 2009
'
'===========================================================

Option Explicit

'''''D E C L A R A T I O N S for Console access etc '''''''''

Private Declare Function AllocConsole Lib "kernel32" () As Long
Private Declare Function FreeConsole Lib "kernel32" () As Long
Private Declare Function GetStdHandle Lib "kernel32" _
(ByVal nStdHandle As Long) As Long

Private Declare Function ReadConsole Lib "kernel32" Alias _
"ReadConsoleA" (ByVal hConsoleInput As Long, _
ByVal lpbuffer As String, ByVal nNumberOfCharsToRead As Long, _
lpNumberOfCharsRead As Long, lpReserved As Integer) As Long

Private Declare Function WriteConsole Lib "kernel32" Alias _
"WriteConsoleA" (ByVal hConsoleOutput As Long, _
ByVal lpbuffer As String, ByVal nNumberOfCharsToWrite As Long, _
lpNumberOfCharsWritten As Long, lpReserved As Integer) As Long

Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)


'''''D E C L A R A T I O N S for PHLIB.DLL-access '''''''''''''

'extern int _stdcall PH_GetLibraryVersion(char* vers);
Private Declare Function PH_GetLibraryVersion Lib "phlib.dll" (ByVal vers As String) As Long

'extern int _stdcall PH_GetErrorString(char* errstring, int errcode);
Private Declare Function PH_GetErrorString Lib "phlib.dll" (ByVal errstring As String, ByVal errcode As Long) As Long

'extern int _stdcall PH_OpenDevice(int devidx, char* serial);
Private Declare Function PH_OpenDevice Lib "phlib.dll" (ByVal devidx As Long, ByVal serial As String) As Long

'extern int _stdcall PH_CloseDevice(int devidx);
Private Declare Function PH_CloseDevice Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_Initialize(int devidx, int mode);
Private Declare Function PH_Initialize Lib "phlib.dll" (ByVal devidx As Long, ByVal mode As Long) As Long

'--- functions below can only be used after Initialize ------

'extern int _stdcall PH_GetHardwareVersion(int devidx, char* vers);
Private Declare Function PH_GetHardwareVersion Lib "phlib.dll" (ByVal devidx As Long, ByVal model As String, ByVal vers As String) As Long

'extern int _stdcall PH_GetSerialNumber(int devidx, char* serial);
Private Declare Function PH_GetSerialNumber Lib "phlib.dll" (ByVal devidx As Long, ByVal serial As String) As Long

'extern int _stdcall PH_GetBaseResolution(int devidx);
Private Declare Function PH_GetBaseResolution Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_Calibrate(int devidx);
Private Declare Function PH_Calibrate Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_SetSyncDiv(int devidx, int div);
Private Declare Function PH_SetSyncDiv Lib "phlib.dll" (ByVal devidx As Long, ByVal div As Long) As Long

'extern int _stdcall PH_SetCFDLevel(int devidx, int channel, int value);
Private Declare Function PH_SetCFDLevel Lib "phlib.dll" (ByVal devidx As Long, ByVal channel As Long, ByVal value As Long) As Long

'extern int _stdcall PH_SetCFDZeroCross(int devidx, int channel, int value);
Private Declare Function PH_SetCFDZeroCross Lib "phlib.dll" (ByVal devidx As Long, ByVal channel As Long, ByVal value As Long) As Long

'extern int _stdcall PH_SetStopOverflow(int devidx, int stop_ovfl, int stopcount);
Private Declare Function PH_SetStopOverflow Lib "phlib.dll" (ByVal devidx As Long, ByVal stop_ovfl As Long, ByVal stopcount As Long) As Long

'extern int _stdcall PH_SetRange(int devidx, int range);
Private Declare Function PH_SetRange Lib "phlib.dll" (ByVal devidx As Long, ByVal range As Long) As Long

'extern int _stdcall PH_SetOffset(int devidx, int offset);
Private Declare Function PH_SetOffset Lib "phlib.dll" (ByVal devidx As Long, ByVal Offset As Long) As Long

'extern int _stdcall PH_ClearHistMem(int devidx, int block);
Private Declare Function PH_ClearHistMem Lib "phlib.dll" (ByVal devidx As Long, ByVal block As Long) As Long

'extern int _stdcall PH_StartMeas(int devidx, int tacq);
Private Declare Function PH_StartMeas Lib "phlib.dll" (ByVal devidx As Long, ByVal tacq As Long) As Long

'extern int _stdcall PH_StopMeas(int devidx, void);
Private Declare Function PH_StopMeas Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_CTCStatus(int devidx);
Private Declare Function PH_CTCStatus Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_GetBlock(int devidx, unsigned int *chcount, int block);
Private Declare Function PH_GetBlock Lib "phlib.dll" (ByVal devidx As Long, lpcounts As Long, ByVal block As Long) As Long

'extern int _stdcall PH_GetResolution(int devidx);
Private Declare Function PH_GetResolution Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_GetCountRate(int devidx, int channel);
Private Declare Function PH_GetCountRate Lib "phlib.dll" (ByVal devidx As Long, ByVal channel As Long) As Long

'extern int _stdcall PH_GetFlags(int devidx);
Private Declare Function PH_GetFlags Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_GetElapsedMeasTime(int devidx);
Private Declare Function PH_GetElapsedMeasTime Lib "phlib.dll" (ByVal devidx As Long) As Long


'for TT modes only
'extern int _stdcall PH_TTReadData(int devidx, unsigned int* buffer, unsigned int count);
Private Declare Function PH_TTReadData Lib "phlib.dll" (ByVal devidx As Long, buffer As Long, ByVal count As Long) As Long

'extern int _stdcall PH_TTSetMarkerEdges(int devidx, int me0, int me1, int me2, int me3);
Private Declare Function PH_TTSetMarkerEdges Lib "phlib.dll" (ByVal devidx As Long, ByVal me0 As Long, ByVal me1 As Long, ByVal me2 As Long, ByVal me3 As Long) As Long


'for Routing only
'extern int _stdcall PH_GetRouterVersion(int devidx, char* model, char* vers);
Private Declare Function PH_GetRouterVersion Lib "phlib.dll" (ByVal devidx As Long, ByVal model As String, ByVal vers As String) As Long

'extern int _stdcall PH_GetRoutingChannels(int devidx);
Private Declare Function PH_GetRoutingChannels Lib "phlib.dll" (ByVal devidx As Long) As Long

'extern int _stdcall PH_EnableRouting(int devidx, int enable);
Private Declare Function PH_EnableRouting Lib "phlib.dll" (ByVal devidx As Long, ByVal enable As Long) As Long

'extern int _stdcall PH_SetPHR800Input(int devidx, int channel, int level, int edge);  //new in v2.0
Private Declare Function PH_SetPHR800Input Lib "phlib.dll" (ByVal devidx As Long, ByVal channel As Long, ByVal level As Long, ByVal edge As Long) As Long

'extern int _stdcall PH_SetPHR800CFD(int devidx, int channel, int dscrlevel, int zerocross); //new in v2.0
Private Declare Function PH_SetPHR800CFD Lib "phlib.dll" (ByVal devidx As Long, ByVal channel As Long, ByVal dscrlevel As Long, ByVal zerocross As Long) As Long



''''C O N S T A N T S'''''''''''''''''''''''''''''''''''''

'PicoHarp DLL constants from phdefin.h and errorcodes.h
'please also use the other constants from phdefin.h to perform
'range checking on your function parameters!

Private Const LIB_VERSION = "2.3"

Private Const MAXDEVNUM = 8

Private Const HISTCHAN = 65536     ' number of histogram channels
Private Const TTREADMAX = 131072   ' 128K event records
Private Const RANGES = 8

Private Const MODE_HIST = 0
Private Const MODE_T2 = 2
Private Const MODE_T3 = 3

Private Const FLAG_OVERFLOW = &H40
Private Const FLAG_FIFOFULL = &H3

Private Const ZCMIN = 0                'mV
Private Const ZCMAX = 20               'mV
Private Const DISCRMIN = 0             'mV
Private Const DISCRMAX = 800           'mV

Private Const OFFSETMIN = 0            'ps
Private Const OFFSETMAX = 1000000000   'ps
Private Const ACQTMIN = 1              'ms
Private Const ACQTMAX = 360000000      'ms  (100*60*60*1000ms = 100h)

Private Const PHR800LVMIN = -1600      'mV
Private Const PHR800LVMAX = 2400       'mV

Private Const ERROR_DEVICE_OPEN_FAIL = -1

'I/O handlers for the console window.

Private Const STD_INPUT_HANDLE = -10&
Private Const STD_OUTPUT_HANDLE = -11&
Private Const STD_ERROR_HANDLE = -12&


'''''G L O B A L S'''''''''''''''''''''''''''''''''''

Private hConsoleIn As Long 'The console's input handle
Private hConsoleOut As Long 'The console's output handle
Private hConsoleErr As Long 'The console's error handle



'''''M A I N'''''''''''''''''''''''''''''''''''''''''

Private Sub Main()

Dim Dev(0 To MAXDEVNUM - 1) As Long
Dim Found As Long
Dim SyncDivider As Long
Dim RangeNo As Long
Dim Offset As Long
Dim AcquisitionTime As Long
Dim CFDLevel0 As Long
Dim CFDZeroCross0 As Long
Dim CFDLevel1 As Long
Dim CFDZeroCross1 As Long
Dim PHR800Level As Long
Dim PHR800Edge As Long
Dim PHR800CFDLevel As Long
Dim PHR800CFDZeroCross As Long
Dim Retcode As Long
Dim LibVersion As String * 8
Dim ErrorString As String * 40
Dim HardwareSerial As String * 8
Dim HardwareModel As String * 16
Dim HardwareVersion As String * 8
Dim Routermodel As String * 8
Dim Routerversion As String * 8
Dim BaseRes As Long
Dim Resolution As Long
Dim Countrate0 As Long
Dim Countrate1 As Long
Dim Flags As Long
Dim Waitloop As Long
Dim Integralcount As Long
Dim Counts(0 To HISTCHAN-1, 0 To 3) As Long
Dim i As Long
Dim j As Long

AllocConsole 'Create a console instance

'Get the console I/O handles

hConsoleIn = GetStdHandle(STD_INPUT_HANDLE)
hConsoleOut = GetStdHandle(STD_OUTPUT_HANDLE)
hConsoleErr = GetStdHandle(STD_ERROR_HANDLE)


ConsolePrint "PicoHarp 300 DLL Demo" & vbCrLf

Retcode = PH_GetLibraryVersion(LibVersion)
ConsolePrint "Library version = " & LibVersion & vbCrLf
If Left$(LibVersion, 3) <> LIB_VERSION Then
    ConsolePrint "Tis program version requires PHLib.dll version " & LIB_VERSION & vbCrLf
    GoTo Ex
End If

ConsolePrint "Searching for PicoHarp devices..." & vbCrLf
ConsolePrint "Devidx    Status" & vbCrLf

Found = 0
For i = 0 To MAXDEVNUM - 1
    Retcode = PH_OpenDevice(i, HardwareSerial)
    If Retcode = 0 Then ' Grab any PicoHarp we can open
        ConsolePrint "  " & i & "     S/N " & HardwareSerial & vbCrLf
        Dev(Found) = i  'keep index to devices we want to use
        Found = Found + 1
     Else
         If Retcode = ERROR_DEVICE_OPEN_FAIL Then
         ConsolePrint "  " & i & "     no device " & vbCrLf
         Else
             Retcode = PH_GetErrorString(ErrorString, Retcode)
             ConsolePrint "  " & i & "     " & ErrorString & vbCrLf
         End If
    End If
 Next i

'in this demo we will use the first PicoHarp device we found, i.e. dev(0)
'you could also check for a specific serial number, so that you always know
'which physical device you are talking to.

If Found < 1 Then
    ConsolePrint "No device available." & vbCrLf
    GoTo Ex
End If
ConsolePrint "Using device " & CStr(Dev(0)) & vbCrLf
ConsolePrint "Initializing the device " & vbCrLf

Retcode = PH_Initialize(Dev(0), MODE_HIST) 'standard histogramming mode
If Retcode < 0 Then
    ConsolePrint "PH_Initialize error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_GetHardwareVersion(Dev(0), HardwareModel, HardwareVersion)
ConsolePrint "Found Hardware Model " & HardwareModel & " Version " & HardwareVersion & vbCrLf

BaseRes = PH_GetBaseResolution(Dev(0))
ConsolePrint "Base Resolution = " & CStr(BaseRes) & " ps" & vbCrLf

'everything up to here doesn't need to be done again

ConsolePrint "Calibrating..." & vbCrLf
Retcode = PH_Calibrate(Dev(0))
If Retcode < 0 Then
    ConsolePrint "Calibration error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

'Set the measurement parameters (can be done again later)
'Change these numbers as you need

SyncDivider = 8         'see manual
RangeNo = 0             '0=BaseRes, 1=2*Baseres, 2=4*Baseres and so on
Offset = 0
CFDLevel0 = 50          'millivolts
CFDZeroCross0 = 10      'millivolts
CFDLevel1 = 50          'millivolts
CFDZeroCross1 = 10      'millivolts
PHR800Level = -200      'millivolts
PHR800Edge = 0          '0=falling, 1=rising
PHR800CFDLevel = 100    'millivolts
PHR800CFDZeroCross = 10 'millivolts

AcquisitionTime = 1000  'millisec


Retcode = PH_SetSyncDiv(Dev(0), SyncDivider)
If Retcode < 0 Then
    ConsolePrint "SetSyncDiv error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetCFDLevel(Dev(0), 0, CFDLevel0)
If Retcode < 0 Then
    ConsolePrint "SetCFDLevel error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetCFDZeroCross(Dev(0), 0, CFDZeroCross0)
If Retcode < 0 Then
    ConsolePrint "SetCFDZeroCross error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetCFDLevel(Dev(0), 1, CFDLevel1)
If Retcode < 0 Then
    ConsolePrint "SetCFDLevel error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetCFDZeroCross(Dev(0), 1, CFDZeroCross1)
If Retcode < 0 Then
    ConsolePrint "SetCFDZeroCross error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetStopOverflow(Dev(0), 1, 65535)
If Retcode < 0 Then
    ConsolePrint "SetStopOverflow error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetRange(Dev(0), RangeNo)
If Retcode < 0 Then
    ConsolePrint "SetRange error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_SetOffset(Dev(0), Offset)
If Retcode < 0 Then
    ConsolePrint "SetOffset error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

Retcode = PH_EnableRouting(Dev(0), 1) 'NEED THIS FOR ROUTING
If Retcode < 0 Then
    ConsolePrint "No router connected. Aborted." & vbCrLf
    GoTo Ex
End If

Retcode = PH_GetRoutingChannels(Dev(0))
If Retcode <> 4 Then
    ConsolePrint "Inappropriate number of routing channels. Aborted." & vbCrLf
    GoTo Ex
End If


Retcode = PH_GetRouterVersion(Dev(0), Routermodel, Routerversion)
If Retcode < 0 Then
    ConsolePrint "PH_GetRouterVersion failed. Aborted." & vbCrLf
    GoTo Ex
Else
    ConsolePrint "Found Router Model " & Routermodel & " Version " & Routerversion & vbCrLf
End If

If Left$(Routermodel, 7) = "PHR 800" Then
    For i = 0 To 3
        Retcode = PH_SetPHR800Input(Dev(0), i, PHR800Level, PHR800Edge)
        If Retcode < 0 Then 'All channels may not be installed, so be liberal here
            ConsolePrint "PH_SetPHR800Input (ch" & i & ") failed. Maybe not installed. & vbCrLf"
        End If
    Next i

    For i = 0 To 3
        Retcode = PH_SetPHR800CFD(Dev(0), i, PHR800CFDLevel, PHR800CFDZeroCross)
        If Retcode < 0 Then 'CFDs may not be installed, so be liberal here
            ConsolePrint "PH_SetPHR800CFD (ch" & i & ") failed. Maybe not installed. & vbCrLf"
        End If
    Next i
End If

Resolution = PH_GetResolution(Dev(0))
ConsolePrint "Resolution = " & CStr(Resolution) & " ns " & vbCrLf

'the measurement sequence starts here, the whole measurement sequence may be
'done again as often as you like

For i = 0 To 3
    Retcode = PH_ClearHistMem(Dev(0), i) 'clear all 4 blocks the routing uses
    If Retcode < 0 Then
        ConsolePrint "ClearHistMem error " & CStr(Retcode) & vbCrLf
        GoTo Ex
    End If
Next i

ConsolePrint "Press Enter to start measurement..." & vbCrLf
Call ConsoleRead

'measure the input rates e.g. for a panel meter
'this can be done again later, e.g. on a timer that updates the display
'note: after Init or SetSyncDiv you must allow 100 ms for valid new count rate readings
Sleep (200)
Countrate0 = PH_GetCountRate(Dev(0), 0)
Countrate1 = PH_GetCountRate(Dev(0), 1)
ConsolePrint "Rate0 = " & CStr(Countrate0) & vbCrLf
ConsolePrint "Rate1 = " & CStr(Countrate1) & vbCrLf
    
'the actual measurement starts here
    
Retcode = PH_StartMeas(Dev(0), AcquisitionTime)
If Retcode < 0 Then
    ConsolePrint "StartMeas error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If
     
ConsolePrint "Measuring for " & CStr(AcquisitionTime) & " milliseconds..." & vbCrLf

Waitloop = 0

While (PH_CTCStatus(Dev(0)) = 0) 'wait (or better: do something useful here or sleep)
    Waitloop = Waitloop + 1 'you could use a timeout limit here
Wend

Retcode = PH_StopMeas(Dev(0))
If Retcode < 0 Then
    ConsolePrint "StopMeas error " & CStr(Retcode) & vbCrLf
    GoTo Ex
End If

For i = 0 To 3 'fetch all 4 histograms
    Retcode = PH_GetBlock(Dev(0), Counts(1, i), i) 'must pass the first array element
        If Retcode < 0 Then
            ConsolePrint "GetBlock error " & CStr(Retcode) & vbCrLf
            GoTo Ex
        End If
    Integralcount = 0
    For j = 0 To HISTCHAN-1
        Integralcount = Integralcount + Counts(j, i)
    Next j
    ConsolePrint "Integralcount[" & CStr(i) & "] = " & CStr(Integralcount) & vbCrLf
Next i


Flags = PH_GetFlags(Dev(0))
If Flags < 0 Then
    ConsolePrint "GetFlags error " & CStr(Flags) & vbCrLf
    GoTo Ex
End If
If (Flags And FLAG_OVERFLOW) Then
    ConsolePrint " Overflow " & vbCrLf
End If

'the count data is now in the array Counts, you can put it to the screen or
'in a file or whatever you like
'you can then run another measurement sequence or let the user change the
'settings
'here we just put the data in a file

Open "ROUTING.OUT" For Output Shared As #1
For i = 0 To HISTCHAN-1
    Print #1, CStr(Counts(i, 0)) & " " & CStr(Counts(i, 1)) & " " & CStr(Counts(i, 2)) & " " & CStr(Counts(i, 3))
Next i
Close

Ex: 'End the program
For i = 0 To MAXDEVNUM - 1 'no harm to close all
    Retcode = PH_CloseDevice(i)
Next i

ConsolePrint "Press Enter to exit"
Call ConsoleRead
FreeConsole 'Destroy the console

End Sub



'''''F U N C T I O N S''''''''''''''''''''''''''''''''''
'F+F+++++++++++++++++++++++++++++++++++++++++++++++++++
'Function: ConsolePrint
'
'Summary: Prints the output of a string
'
'Args: String ConsolePrint
'The string to be printed to the console's output buffer.
'
'Returns: None
'
'-----------------------------------------------------

Private Sub ConsolePrint(szOut As String)

WriteConsole hConsoleOut, szOut, Len(szOut), vbNull, vbNull

End Sub


'F+F++++++++++++++++++++++++++++++++++++++++++++++++++++
'Function: ConsoleRead
'
'Summary: Gets a line of input from the user.
'
'Args: None
'
'Returns: String ConsoleRead
'The line of input from the user.
'---------------------------------------------------F-F

Private Function ConsoleRead() As String

Dim sUserInput As String * 256

Call ReadConsole(hConsoleIn, sUserInput, Len(sUserInput), vbNull, vbNull)

'Trim off the NULL charactors and the CRLF.

ConsoleRead = Left$(sUserInput, InStr(sUserInput, Chr$(0)) - 3)

End Function

