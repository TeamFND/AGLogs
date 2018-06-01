unit AG.Logs;

interface

//{$UNDEF MSWINDOWS}

uses
  {$IFDEF MSWINDOWS}{$IFDEF FPC}Windows{$ELSE}Winapi.Windows{$ENDIF},{$ENDIF}
  {$IFDEF FPC}FGL{$ELSE}System.Generics.Collections{$ENDIF},
  {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF},
  {$IFDEF FPC}Classes{$ELSE}System.Classes{$ENDIF},
  {$IFDEF FPC}DateUtils{$ELSE}System.DateUtils{$ENDIF}
  {$IF defined(MSWINDOWS) and not defined(FPC)},
    {$IFDEF FPC}SyncObjs{$ELSE}System.SyncObjs{$ENDIF}
  {$ENDIF}
  {$IFNDEF MSWINDOWS}{$IFNDEF FPC},System.IOUtils{$ENDIF}{$ENDIF};

type
  TAGLog=class abstract
    strict protected
      OneTabStr:string;
      tabs:cardinal;
      tabstr:string;
      constructor Create();
      procedure TabRegen();
      procedure SetTabText(const s:string);virtual;
    const
      CBaseTab='--------------------------';  
    public
      class function SizeableWordtoStr(i:word;size:int8):string;static;inline;
      class function GenerateLogString(const s:string;o:TObject=nil):string;static;inline;
      procedure Tab();virtual;
      procedure UnTab();virtual;
      procedure Write(const Text:string;o:TObject=nil);overload;virtual;abstract;
      destructor Destroy();override;
      property TabText:string read OneTabStr write SetTabText;
  end;

  TAGRamLog=class(TAGLog)
    public
      buf:String;
      constructor Create();
      procedure Write(const Text:string;o:TObject=nil);overload;override;
  end;

  TAGDiskLog=class(TAGLog)
    strict protected
      {$IF defined(MSWINDOWS) and not defined(FPC)} 
      buf1:String;
      onbuf:boolean;
      LogHandle,ThreadHandle:NativeUInt;
      ThreadID:cardinal;
      Lock:TCriticalSection;
      WantTerminate:Boolean;
      {$ELSE}         
      Stream:TStream;
      {$ENDIF}
    public
      constructor Create(const FileName:String);overload;
      {$IF defined(MSWINDOWS) and not defined(FPC)}
      procedure Init();stdcall;
      {$ENDIF}
      procedure Write(const Text:string;o:TObject=nil);overload;override;
      destructor Destroy();overload;override;
  end;

  TAGNullLog=class(TAGLog)
    public
      constructor Create();overload;
      procedure Write(const Text:string;o:TObject=nil);overload;override;
  end;

  {$IFDEF MSWINDOWS}
  TAGCommandLineLog=class(TAGLog)
    strict protected
      CommandLine:THandle;
    public
      constructor Create(Handele:THandle);overload;
      procedure Write(const Text:string;o:TObject=nil);overload;override;
      destructor Destroy();overload;override;
  end;
  {$ENDIF}

  TAGStreamLog=class(TAGLog)
    strict protected
      stream:TStream;
    public
      constructor Create(Astream:TStream);overload;
      procedure Write(const Text:string;o:TObject=nil);overload;override;
  end;

  TAGCallBackLog=class(TAGLog)
    strict protected type
      TCallBack={$IFNDEF FPC}reference to{$ENDIF}procedure(s:string);
      var
        CallBack:TCallBack;
    public
      constructor Create(ACallBack:TCallBack);overload;
      procedure Write(const Text:string;o:TObject=nil);overload;override;
  end;

  TAGMultiLog=class(TAGLog)
    strict protected
      procedure SetTabText(const s:string);override;
    public
      type
        TLogsList={$IFDEF FPC}specialize TFPGList<TAGLog>{$ELSE}TList<TAGLog>{$ENDIF};
      var
        Logs:TLogsList;
      constructor Create(Default:TLogsList);overload;
      procedure Write(const Text:string;o:TObject=nil);overload;override;
      procedure Tab();override;
      procedure UnTab();override;
      destructor Destroy();overload;override;
  end;

const
  CharSize=SizeOf(char);//{$IFDEF FPC}1{$ELSE}2{$ENDIF};
  DefOneTabStr='  ';
  
Implementation

constructor TAGLog.Create();
begin
Self.Write(CBaseTab+'Logging init-'+CBaseTab);
TabRegen;
OneTabStr:=DefOneTabStr;
end;

class function TAGLog.SizeableWordtoStr(i:word;size:int8):string;
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

class function TAGLog.GenerateLogString(const  s:string;o:TObject=nil):string;
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
Result:='['+SizeableWordtoStr(DayOfTheMonth(D),2)+'.'+SizeableWordtoStr(MonthOfTheYear(D),2)+'.'+
  SizeableWordtoStr(YearOf(D),4)+' '+SizeableWordtoStr(HourOfTheDay(D),2)+':'+
  SizeableWordtoStr(MinuteOfTheHour(D),2)+':'+SizeableWordtoStr(SecondOfTheMinute(D),2)+'.'
  +SizeableWordtoStr(MilliSecondOfTheSecond(D),3)+'] '+Result+s+sLineBreak;
end;

procedure TAGLog.Tab();
begin
inc(tabs);
tabstr:=tabstr+'  ';
end;

procedure TAGLog.UnTab();
begin
if tabs=0 then
  Exit;
dec(tabs);
Delete(tabstr,1,2);
end;

procedure TAGLog.TabRegen();
var
  i:cardinal;
begin
tabstr:='';
for i:=1 to tabs do
  tabstr:=tabstr+OneTabStr;
end;

procedure TAGLog.SetTabText(const s:string);
begin
OneTabStr:=s;
TabRegen;
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

procedure TAGRamLog.Write(const Text:string;o:TObject=nil);
begin
buf:=buf+GenerateLogString(tabstr+Text,o);
end;

constructor TAGDiskLog.Create(const FileName:String);
{$IF defined(MSWINDOWS) and not defined(FPC)}
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
      Stream:=TFileStream.Create('test2.log',fmOpenRead+fmShareDenyNone);
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

{$IF defined(MSWINDOWS) and not defined(FPC)}
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

procedure TAGDiskLog.Write(const Text:string;o:TObject=nil);
{$IF defined(MSWINDOWS) and not defined(FPC)}
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
{$IF defined(MSWINDOWS) and not defined(FPC)}
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

procedure TAGNullLog.Write(const Text:string;o:TObject=nil);
begin
end;

{TAGCommandLineLog}

{$IFDEF MSWINDOWS}
constructor TAGCommandLineLog.Create(Handele:THandle);
begin
CommandLine:=Handele;
inherited Create;
end;

procedure TAGCommandLineLog.Write(const Text:string;o:TObject=nil);
var
  p:PChar;
  temptext:string;
  a,b:cardinal;   
begin
temptext:=GenerateLogString(tabstr+text,o);
p:=addr(temptext[1]);
a:=length(temptext);
while a<>0 do
begin
  b:=0;
  {$IFDEF FPC}WriteConsoleA(CommandLine,p,a,b,nil);{$ELSE}WriteConsoleW(CommandLine,p,a,b,nil);{$ENDIF}
  inc(p,b);
  dec(a,b);
end;
end;

destructor TAGCommandLineLog.Destroy();
begin
inherited;
if CommandLine<>GetStdHandle(STD_OUTPUT_HANDLE) then
CloseHandle(CommandLine);
end;
{$ENDIF}

{TAGStreamLog}

constructor TAGStreamLog.Create(Astream:TStream);
begin
stream:=Astream;
inherited Create;
end;

procedure TAGStreamLog.Write(const Text:string;o:TObject=nil);
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

procedure TAGCallBackLog.Write(const Text:string;o:TObject=nil);
begin
CallBack(GenerateLogString(Text,o));
end;

{TAGMultiLog}

procedure TAGMultiLog.SetTabText(const s:string);
var
  i:TAGLog;
begin
for i in Logs do
  i.TabText:=s;
end;

constructor TAGMultiLog.Create(Default:TLogsList);
begin
//inherited Create;
if Default<>nil then
  Logs:=Default
else
  Logs:=TLogsList.Create;
end;

procedure TAGMultiLog.Write(const Text:string;o:TObject=nil);
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
