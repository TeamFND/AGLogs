unit AG.Logs;

interface

{$IFDEF FPC}
  {$UNDEF MSWINDOWS}
{$ENDIF}

uses
  {$IFDEF MSWINDOWS}{$IFDEF FPC}Windows{$ELSE}Winapi.Windows{$ENDIF},{$ENDIF}
  {$IFDEF FPC}FGL{$ELSE}System.Generics.Collections{$ENDIF},
  {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF},
  {$IFDEF FPC}Classes{$ELSE}System.Classes{$ENDIF},
  {$IFDEF FPC}DateUtils{$ELSE}System.DateUtils{$ENDIF},
  {$IFDEF FPC}SyncObjs{$ELSE}System.SyncObjs{$ENDIF}
  {$IFNDEF MSWINDOWS}{$IFNDEF FPC},System.IOUtils{$ENDIF}{$ENDIF};

type
  TAGLog=class abstract
    strict protected
      tabs:cardinal;
      tabstr:string;
      constructor Create();
    const
      CBaseTab='--------------------------';  
    public
      class function SisebleWordtoStr(i:word;size:int8):string;static;inline;
      class function GenerateLogString(s:string;o:TObject=nil):string;static;inline;
      procedure Tab();virtual;
      procedure UnTab();virtual;
      procedure Write(Text:string;o:TObject=nil);overload;virtual;abstract;
      destructor Destroy();override;
  end;

  TAGRamLog=class(TAGLog)
    public
      buf:WideString;
      constructor Create();overload;
      procedure Write(Text:string;o:TObject=nil);overload;override;
  end;

  TAGDiskLog=class(TAGLog)
    strict protected
      {$IFNDEF MSWINDOWS}
      Stream:TFileStream;//TStream;
      {$ELSE}
      buf1:WideString;
      onbuf:boolean;
      LogHandle,ThreadHandle:NativeUInt;
      ThreadID:cardinal;
      Lock:TCriticalSection;
      WantTerminate:Boolean;
      {$ENDIF}
    public
      constructor Create(FileName:WideString);overload;
      {$IFDEF MSWINDOWS}
      procedure Init();stdcall;
      {$ENDIF}
      procedure Write(Text:string;o:TObject=nil);overload;override;
      destructor Destroy();overload;override;
  end;

  TAGNullLog=class(TAGLog)
    public
      constructor Create();overload;
      procedure Write(Text:string;o:TObject=nil);overload;override;
  end;

  {$IFDEF MSWINDOWS}
  TAGCommandLineLog=class(TAGLog)
    strict protected
      CommandLine:THandle;
    public
      constructor Create(Handele:THandle);overload;
      procedure Write(Text:string;o:TObject=nil);overload;override;
      destructor Destroy();overload;override;
  end;
  {$ENDIF}

  TAGStreamLog=class(TAGLog)
    strict protected
      stream:TStream;
    public
      constructor Create(Astream:TStream);overload;
      procedure Write(Text:string;o:TObject=nil);overload;override;
  end;

  TAGCallBackLog=class(TAGLog)
    strict protected type
      TCallBack={$IFNDEF FPC}reference to{$ENDIF}procedure(s:string);
      var
        CallBack:TCallBack;
    public
      constructor Create(ACallBack:TCallBack);overload;
      procedure Write(Text:string;o:TObject=nil);overload;override;
  end;

  TAGMultiLog=class(TAGLog)
    public
      type
        TLogsList={$IFDEF FPC}specialize TFPGList<TAGLog>{$ELSE}TList<TAGLog>{$ENDIF};
      var
        Logs:TLogsList;
      constructor Create(Default:TLogsList);overload;
      procedure Write(Text:string;o:TObject=nil);overload;override;
      procedure Tab();override;
      procedure UnTab();override;
      destructor Destroy();overload;override;
  end;

const
  CharSize=SizeOf(char);//{$IFDEF FPC}1{$ELSE}2{$ENDIF};
  
Implementation

constructor TAGLog.Create();
begin
Self.Write(CBaseTab+'Logging init-'+CBaseTab);
end;

class function TAGLog.SisebleWordtoStr(i:word;size:int8):string;
begin
  Result:=IntToStr(i);
  size:=size-Length(Result);
  case size of
  0:Result:=Result;
  1:Result:='0'+Result;
  2:Result:='00'+Result;
  3:Result:='000'+Result;
  4:Result:='0000'+Result;
  end;
end;

class function TAGLog.GenerateLogString(s:string;o:TObject=nil):string;
var
  D:TDateTime;
begin
D:=Time;
if o<>nil then
  {$IFDEF FPC}
    Result:=o.ClassName+'['+IntToStr(o.GetHashCode)+']:'
  {$ELSE}
    Result:=o.QualifiedClassName+'['+IntToStr(o.GetHashCode)+']:'
  {$ENDIF}
else
  Result:='';
Result:='['+Siseblewordtostr(DayOfTheMonth(D),2)+'.'+Siseblewordtostr(MonthOfTheYear(D),2)+'.'+
  Siseblewordtostr(YearOf(D),4)+' '+Siseblewordtostr(HourOfTheDay(D),2)+':'+
  Siseblewordtostr(MinuteOfTheHour(D),2)+':'+Siseblewordtostr(SecondOfTheMinute(D),2)+'.'
  +Siseblewordtostr(MilliSecondOfTheSecond(D),3)+'] '+Result+s+sLineBreak;
end;

procedure TAGLog.Tab();
begin
inc(tabs);
tabstr:=tabstr+'  ';
end;

procedure TAGLog.UnTab();
begin
dec(tabs);
Delete(tabstr,1,2);
end;

destructor TAGLog.Destroy();
begin
Self.Write(CBaseTab+'Logging ended'+CBaseTab);
inherited;
end;

constructor TAGRamLog.Create();
begin
buf:='';
tabs:=0;
tabstr:='';
inherited Create;
end;

procedure TAGRamLog.Write(Text:string;o:TObject=nil);
begin
buf:=buf+GenerateLogString(tabstr+Text,o);
end;

constructor TAGDiskLog.Create(FileName:WideString);
{$IFDEF MSWINDOWS}
begin
  Lock:=TCriticalSection.Create;
  WantTerminate:=False;
  tabs:=0;
  tabstr:='';
  buf1:='';
  LogHandle:=CreateFileW(Pwidechar(FileName),GENERIC_WRITE,0,nil,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
  SetFilePointer(LogHandle,0,nil,FILE_END);
  ThreadHandle:=CreateThread(nil,0,{$IFDEF FPC}Self.MethodAddress('Init'){$ELSE}addr(TAGDiskLog.Init){$ENDIF},self,0,ThreadID);
{$ELSE}   
var
  s:TBytes;
begin
  {$IFDEF FPC}
    Stream:=nil;
    try
      Stream:=TFileStream.Create('test2.log',fmOpenRead);
      SetLength(s,Stream.Size);
      Stream.Read(s[0],Stream.Size);
    except
      SetLength(s,0);
    end;
    FreeAndNil(Stream);
  {$ELSE}
    try
      s:=TFile.ReadAllBytes(FileName);
    except
      s:=TBytes.Create();
    end;
  {$ENDIF}
  Stream:=TFileStream.Create(FileName,fmCreate+fmOpenReadWrite+fmShareDenyWrite);
  Stream.WriteBuffer(s[0],length(s));
  SetLength(s,0);
{$ENDIF}
inherited Create;
end;

{$IFDEF MSWINDOWS}
procedure TAGDiskLog.Init();stdcall;
var
  n:cardinal;
  buf:PChar;
begin
buf:='';
while Lock<>nil do
begin
  Lock.Enter;
  if buf<>'' then
    WriteFile(LogHandle,buf^,CharSize*n,n,nil);
  n:=Length(buf1);
  buf:=PChar(Copy(buf1,0,n));
  buf1:='';
  Lock.Leave;
  if WantTerminate then
  begin
    Sleep(0);
    Lock.Enter;
    if buf<>'' then
      WriteFile(LogHandle,buf^,CharSize*n,n,nil);
    n:=Length(buf1);
    buf:=PChar(Copy(buf1,0,n));
    buf1:='';
    Lock.Leave;
    WantTerminate:=False;
    exit;
  end;
  sleep(0);
end;
end;
{$ENDIF}

procedure TAGDiskLog.Write(Text:string;o:TObject=nil);
{$IFDEF MSWINDOWS}
begin
Lock.Enter;
buf1:=buf1+GenerateLogString(tabstr+text,o);
Lock.Leave;
{$ELSE}
var
  s:string;
begin
s:=GenerateLogString(tabstr+text,o);
  {$IFDEF FPC}
    Stream.Write(PChar(s)^,Length(s)*CharSize);
  {$ELSE}
    Stream.WriteData(PChar(s),Length(s)*CharSize);
  {$ENDIF}
{$ENDIF}
end;

destructor TAGDiskLog.Destroy();
begin
inherited;
{$IFDEF MSWINDOWS}
WantTerminate:=True;
While WantTerminate do
  sleep(0);
FreeAndNil(Lock);
TerminateThread(ThreadID,0);
CloseHandle(ThreadHandle);
CloseHandle(LogHandle);
{$ELSE}
FreeAndNil(Stream);
{$ENDIF}
end;

constructor TAGNullLog.Create();
begin
inherited;
end;

procedure TAGNullLog.Write(Text:string;o:TObject=nil);
begin
end;

{TAGCommandLineLog}

{$IFDEF MSWINDOWS}
constructor TAGCommandLineLog.Create(Handele:THandle);
begin
CommandLine:=Handele;
inherited Create;
end;

procedure TAGCommandLineLog.Write(Text:string;o:TObject=nil);
var
  p:PWideChar;
  a,b:cardinal;   
begin
Text:=GenerateLogString(tabstr+text,o);
p:=addr(Text[1]);
a:=length(Text);
while a<>0 do
begin
  b:=0;
  WriteConsoleW(CommandLine,p,a,b,nil);
  inc(p,b);
  dec(a,b);
end;
end;

destructor TAGCommandLineLog.Destroy();
begin
inherited;
CloseHandle(CommandLine);
end;
{$ENDIF}

{TAGStreamLog}

constructor TAGStreamLog.Create(Astream:TStream);
begin
stream:=Astream;
inherited Create;
end;

procedure TAGStreamLog.Write(Text:string;o:TObject=nil);
var
  s:string;
begin
s:=GenerateLogString(Text,o);
stream.Write(PChar(s)^,CharSize*length(s));
end;

{TAGCallBackLog}

constructor TAGCallBackLog.Create(ACallBack:TCallBack);
begin
CallBack:=ACallBack;
inherited Create;
end;

procedure TAGCallBackLog.Write(Text:string;o:TObject=nil);
begin
CallBack(GenerateLogString(Text,o));
end;

{TAGMultiLog}

constructor TAGMultiLog.Create(Default:TLogsList);
begin
//inherited Create;
if Default<>nil then
  Logs:=Default
else
  Logs:=TLogsList.Create;
end;

procedure TAGMultiLog.Write(Text:string;o:TObject=nil);
var
  i:TAGLog;
begin
for i in Logs do
  i.Write(Text,o);
end;

procedure TAGMultiLog.Tab();
var
  i:TAGLog;
begin
for i in Logs do
  i.Tab();
end;

procedure TAGMultiLog.UnTab();
var
  i:TAGLog;
begin
for i in Logs do
  i.UnTab();
end;

destructor TAGMultiLog.Destroy();
var
  i:TAGLog;
begin
for i in Logs do
  i.Free();
FreeAndNil(Logs);
//inherited;
end;

initialization
finalization
end.
