unit TestCase1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  AG.Logs{$IFDEF MSWINDOWS}, Windows{$ENDIF};

type
  TTestCase1 = class(TTestCase)
  published
    procedure TestHookUp;
  end;

implementation

procedure Test(s: string);
begin
  Write(s);
end;

procedure TTestCase1.TestHookUp;
var
  MultiLog: TAGLog;
  Stream: TStream;
  s: TBytes;
begin
  MultiLog := TAGMultiLog.Create(nil);
  (MultiLog as TAGMultiLog).Logs.Add(TAGNullLog.Create());
  (MultiLog as TAGMultiLog).Logs.Add(TAGDiskLog.Create('test.log'));
  (MultiLog as TAGMultiLog).Logs.Add(TAGRamLog.Create());
  {$IFDEF MSWINDOWS}
    (MultiLog as TAGMultiLog).Logs.Add(TAGCommandLineLog.Create(GetStdHandle(STD_OUTPUT_HANDLE)));
  {$ENDIF}
  Stream := nil;
  try
    Stream := TFileStream.Create('test2.log', fmOpenRead + fmShareDenyNone);
    SetLength(s, Stream.Size);
    Stream.Read(s[0], Stream.Size);
  except
    SetLength(s, 0);
  end;
  FreeAndNil(Stream);
  Stream := TFileStream.Create('test2.log', fmCreate + fmOpenReadWrite +
    fmShareDenyWrite);
  Stream.Write(s[0], Length(s));
  (MultiLog as TAGMultiLog).Logs.Add(TAGStreamLog.Create(Stream));
  SetLength(s, 0);
  (MultiLog as TAGMultiLog).Logs.Add(TAGCallBackLog.Create(@Test));
  MultiLog.Write('Str Test');
  MultiLog.Write('Str+Object Test', self);
  FreeAndNil(MultiLog);
end;



initialization

  RegisterTest(TTestCase1);
end.
