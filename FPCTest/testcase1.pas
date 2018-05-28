unit TestCase1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, AG.Logs;

type

  TTestCase1= class(TTestCase)
  published
    procedure TestHookUp;
  end;

implementation

procedure TTestCase1.TestHookUp;
var
  MultiLog:TAGLog;
  Stream:TStream;
  s:TBytes;
begin
MultiLog:=TAGMultiLog.Create(nil);
(MultiLog as TAGMultiLog).Logs.Add(TAGNullLog.Create());
(MultiLog as TAGMultiLog).Logs.Add(TAGDiskLog.Create('test.log'));
(MultiLog as TAGMultiLog).Logs.Add(TAGRamLog.Create());
{$IFNDEF MSWINDOWS}(MultiLog as TAGMultiLog).Logs.Add(TAGCommandLineLog.Create(GetStdHandle(STD_OUTPUT_HANDLE))){$ENDIF};
try
  //s:=TFile.ReadAllBytes('test2.log');
except
  //s:=TBytes.Create();
end;
Stream:=TFileStream.Create('test2.log',fmCreate+fmOpenReadWrite+fmShareDenyWrite);
Stream.WriteBuffer(s,length(s));
(MultiLog as TAGMultiLog).Logs.Add(TAGStreamLog.Create(Stream));
{(MultiLog as TAGMultiLog).Logs.Add(TAGCallBackLog.Create(procedure(s:string)
                                                         begin
                                                         Self.WriteLn(s);
                                                         end));}
MultiLog.Write('Str Test');
MultiLog.Write('Str+Object Test',self);
FreeAndNil(MultiLog);
end;



initialization

  RegisterTest(TTestCase1);
end.

