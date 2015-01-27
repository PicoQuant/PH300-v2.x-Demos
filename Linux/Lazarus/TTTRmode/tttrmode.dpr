{
  PicoHarp 300  PHLIB v2.3  Usage Demo with Lazarus
  tested with Lazarus 0.9.26 on Linux 

  Demo access to PicoHarp 300 hardware via PHLIB.
  The program performs a TTTR measurement based on hardcoded settings.
  The resulting event data is stored in a binary output file.

  Michael Wahl, PicoQuant GmbH, April 2009

  Note: This is a console application (i.e. run in terminal window)
  Note v2.x: This is now a multidevice library, new functions for open/close.

  important: Linux: in Compiler Options under Linking in the field Options
  you must enter /lib/libgcc_s.so.1 and tick the box "Pass options..." 
}

program tttrmode;
//{$apptype console}      //only for Delphi

uses
  SysUtils;

const
  {constants taken from PHDEFIN.H and ERRCODES.H}
  LIBVERSION='2.3';
  LIB='libph300.so';      //the only difference from Windows, symlink to phlib.so

  MAXDEVNUM=8;
  HISTCHAN=65536;         // number of histogram channels
  TTREADMAX=131072;       // 128K event records
  RANGES=8;

  FLAG_OVERFLOW=$0040;
  FLAG_FIFOFULL=$0003;

  ZCMIN=0;                //mV
  ZCMAX=20;               //mV
  DISCRMIN=0;             //mV
  DISCRMAX=800;           //mV

  OFFSETMIN=0;            //ps
  OFFSETMAX=1000000000;   //ps
  ACQTMIN=1;              //ms
  ACQTMAX=36000000;       //ms  (10*60*60*1000ms = 10h)

  ERROR_DEVICE_OPEN_FAIL=-1;

type
  Pshort = ^word;
  Plong = ^longword;

label
  stoptttr,ex,cncl;

var
  outf:file;
  i:integer;
  ret:integer;
  found:integer=0;
  dev:array[0..MAXDEVNUM-1] of integer;
  LIB_Version:array[0..7] of char;
  HW_Serial:array[0..7] of char;
  HW_Model:array[0..15] of char;
  HW_Version:array[0..7] of char;
  Errorstring:array[0..40] of char;
  Range:integer=0;   //you can change this (meaningless in T2 mode)
  Offset:integer=0;  //normally no need to change this
  Tacq:integer=10000;        //you can change this, unit is millisec
  SyncDivider:integer=1;    //you can change this
  CFDZeroCross0:integer=10; //you can change this
  CFDLevel0:integer=50; //you can change this
  CFDZeroCross1:integer=10; //you can change this
  CFDLevel1:integer=50; //you can change this
  blocksz:integer=32768; //up to TTREADMAX in steps of 512
  NoWritten,
  Resolution,
  Countrate0,
  Countrate1,
  flags,
  FiFoWasFull,CTCDone,Progress:integer;

  buffer: array[0..TTREADMAX-1] of cardinal;

{the following are the functions exported by PHLIB}

function PH_GetLibraryVersion(LIB_Version:pchar):integer;
  stdcall; external LIB;
function PH_GetErrorString(errstring:pchar; errcode:integer):integer;
  stdcall; external LIB;

function PH_OpenDevice(devidx:integer; serial:pchar):integer; 
  stdcall; external LIB;
function PH_CloseDevice(devidx:integer):integer;  
  stdcall; external LIB;
function PH_Initialize(devidx:integer; mode:integer):integer;
  stdcall; external LIB;

function PH_GetHardwareVersion(devidx:integer; model:pchar; vers:pchar):integer;
  stdcall; external LIB;
function PH_GetSerialNumber(devidx:integer; serial:pchar):integer;
  stdcall; external LIB;
function PH_GetBaseResolution(devidx:integer):integer;
  stdcall; external LIB;

function PH_Calibrate(devidx:integer):integer;
  stdcall; external LIB;
function PH_SetSyncDiv(devidx:integer; divd:integer):integer;
  stdcall; external LIB;
function PH_SetCFDLevel(devidx:integer; channel, value:integer):integer;
  stdcall; external LIB;
function PH_SetCFDZeroCross(devidx:integer; channel, value:integer):integer;
  stdcall; external LIB;

function PH_SetStopOverflow(devidx:integer; stop_ovfl, stopcount:integer):integer;
  stdcall; external LIB;
function PH_SetRange(devidx:integer; range:integer):integer;
  stdcall; external LIB;
function PH_SetOffset(devidx:integer; offset:integer):integer;
  stdcall; external LIB;

function PH_ClearHistMem(devidx:integer; block:integer):integer;
  stdcall; external LIB;
function PH_StartMeas(devidx:integer; tacq:integer):integer;
  stdcall; external LIB;
function PH_StopMeas(devidx:integer):integer;
  stdcall; external LIB;
function PH_CTCStatus(devidx:integer):integer;
  stdcall; external LIB;

function PH_GetBlock(devidx:integer; chcount:Plong; block:longint):integer;
  stdcall; external LIB;
function PH_GetResolution(devidx:integer):integer;
  stdcall; external LIB;
function PH_GetCountRate(devidx:integer; channel:integer):integer;
  stdcall; external LIB;
function PH_GetFlags(devidx:integer):integer;
  stdcall; external LIB;
function PH_GetElapsedMeasTime(devidx:integer):integer;
  stdcall; external LIB;

function PH_GetWarnings(devidx:integer):integer; //new since v.2.3
  stdcall; external LIB;
function PH_GetWarningsText(devidx:integer; text:pchar; warnings:integer):integer; //new since v.2.3
  stdcall; external LIB;

//for routing:
function PH_GetRouterVersion(devidx:integer; model:pchar; version:pchar):integer;  
  stdcall; external LIB;
function PH_GetRoutingChannels(devidx:integer):integer;
  stdcall; external LIB;
function PH_EnableRouting(devidx:integer; enable:integer):integer;
  stdcall; external LIB;
function PH_SetPHR800Input(devidx:integer; channel:integer; level:integer; edge:integer):integer;  
  stdcall; external LIB;
function PH_SetPHR800CFD(devidx:integer; channel:integer; dscrlevel:integer; zerocross:integer):integer; 
  stdcall; external LIB;

//for TT modes
function PH_TTReadData(devidx:integer; buffer:Plong; count:cardinal):integer;
  stdcall; external LIB;


begin
  writeln;
  writeln('PicoHarp 300 PHLib  TTTR Mode Demo              PicoQuant GmbH, 2009');
  writeln('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  PH_GetLibraryVersion(LIB_Version);
  writeln('PHLIB version is '+LIB_Version);
  if trim(LIB_Version)<>trim(LIBVERSION)
  then
    writeln('Warning: The application was built for version '+LIBVERSION);

  assign(outf,'tttrmode.out');
  {$I-}
  rewrite(outf,4);
  {$I+}
  if IOResult <> 0 then
  begin
    writeln('cannot open output file');
    goto cncl;
  end;

  writeln;
  writeln('Range No         : ',Range);
  writeln('Offset           : ',Offset);
  writeln('AcquisitionTime  : ',Tacq);
  writeln('SyncDivider      : ',SyncDivider);
  writeln('CFDZeroCross0    : ',CFDZeroCross0);
  writeln('CFDLevel0        : ',CFDLevel0);
  writeln('CFDZeroCross1    : ',CFDZeroCross1);
  writeln('CFDLevel1        : ',CFDLevel1);

  writeln;
  writeln('Searching for PicoHarp devices...');
  writeln('Devidx     Status');

  for i:=0 to MAXDEVNUM-1 do
  begin
    ret := PH_OpenDevice(i, HW_Serial);
    if ret=0 then //Grab any PicoHarp we can open
      begin
        writeln('  ',i,'        S/N ',HW_Serial);
        dev[found] := i; //keep index to devices we want to use
        inc(found);
      end
    else
      begin
        if ret=ERROR_DEVICE_OPEN_FAIL then
          writeln('  ',i,'        no device')
        else
          begin
            PH_GetErrorString(Errorstring, ret);
            writeln('  ',i,'        ', Errorstring);
          end
      end
  end;

  //in this demo we will use the first PicoHarp device we found, i.e. dev[0]
  //you could also check for a specific serial number, so that you always know
  //which physical device you are talking to.

  if found<1 then
  begin
    writeln('No device available.');
    goto ex;
  end;

  writeln('Using device ',dev[0]);
  writeln('Initializing the device...');

  ret:=PH_Initialize(dev[0],2); //2=T2Mode, 3=T3Mode
  if ret<0
  then
    begin
      writeln('PH init error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_GetHardwareVersion(dev[0],HW_Model,HW_Version); (*this is only for information*)
  if ret<0
  then
    begin
      writeln('PH_GetHardwareVersion error ',ret,'. Aborted.');
      goto ex;
    end
  else
    writeln('Found Model ',HW_Model,' Version ',HW_Version);

  writeln('Calibrating...');
  ret:=PH_Calibrate(dev[0]);
  if ret<0
  then
    begin
      writeln('Calibration Error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_SetSyncDiv(dev[0],SyncDivider);
  if ret<0
  then
    begin
      writeln('PH_SetSyncDiv error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_SetCFDLevel(dev[0],0,CFDLevel0);
  if ret<0
  then
    begin
      writeln('PH_SetCFDLevel error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_SetCFDZeroCross(dev[0],0,CFDZeroCross0);
  if ret<0
  then
    begin
      writeln('PH_SetCFDZeroCross error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_SetCFDLevel(dev[0],1,CFDLevel1);
  if ret<0
  then
    begin
      writeln('PH_SetCFDLevel error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_SetCFDZeroCross(dev[0],1,CFDZeroCross1);
  if ret<0
  then
    begin
      writeln('PH_SetCFDZeroCross error ',ret,'. Aborted.');
      goto ex;
    end;

  ret:=PH_SetRange(dev[0],Range);
  if ret<0
  then
    begin
      writeln('PH_SetRange error ',ret,'. Aborted.');
      goto ex;
    end;

  Offset:=PH_SetOffset(dev[0],Offset);
  if ret<0
  then
    begin
      writeln('PH_SetOffset error ',ret,'. Aborted.');
      goto ex;
    end;

  Resolution:=PH_GetResolution(dev[0]);

  //Note: after Init or SetSyncDiv you must allow 100 ms for valid new count rate readings
  sleep(200);
  Countrate0:=PH_GetCountRate(dev[0],0);
  Countrate1:=PH_GetCountRate(dev[0],1);

  writeln('Resolution=',Resolution,
         ' Countrate0=',Countrate0,
         ' Countrate1=',Countrate1);

  Progress:=0;
  write('Progress:',Progress:9);

  ret:=PH_StartMeas(dev[0],Tacq);
  if ret<0
  then
    begin
      writeln;
      writeln('Error in StartMeas. Aborted.');
      goto ex;
    end;

  while true do
    begin
      flags:=PH_GetFlags(dev[0]);
      FiFoWasFull:=flags and FLAG_FIFOFULL;

      if FiFoWasFull<>0
      then
        begin
          writeln;
          writeln('FiFo Overrun!');
          goto stoptttr;
        end;

      ret:=PH_TTReadData(dev[0],@buffer[0],blocksz);       //may return less!
      if ret<0
      then
        begin
          writeln;
          writeln('ReadData error ',ret);
          goto stoptttr;
        end;

     if ret>0
     then
       begin
         blockwrite(outf,buffer[0],ret,nowritten);
         if ret<>nowritten
         then
           begin
             writeln;
             writeln('file write error');
             goto stoptttr;
           end;
         Progress:=Progress+ret;
         write(#8#8#8#8#8#8#8#8#8,Progress:9);
       end
     else
       begin
         CTCDone:=PH_CTCStatus(dev[0]);
         if CTCDone<>0
         then
           begin
             writeln;
             writeln('Done');
             goto stoptttr;
           end;
       end;

      //Countrate0:=PH_GetCountRate(dev[0],0); //can be called here if needed
      //Countrate1:=PH_GetCountRate(dev[0],1); //can be called here if needed
    end;

stoptttr:

 PH_StopMeas(dev[0]);

ex:

  for i:=0 to MAXDEVNUM-1 do //no harm closing all
    PH_CloseDevice(i);

  closefile(outf);
cncl:
  writeln;
  writeln('press RETURN to exit');
  readln;
end.
