unit Unit2;

interface

uses
  DUnitX.TestFramework, AG.Logs, System.Classes, System.IOUtils,
  System.SysUtils, Winapi.Windows;

type

  [TestFixture]
  TMyTestObject = class(TObject)
  public
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Atribute to supply parameters.
  end;

implementation

procedure TMyTestObject.Test1;
var
  MultiLog: TAGLog;
  Stream: TStream;
  s: TBytes;
begin
  MultiLog := TAGMultiLog.Create(nil);
  (MultiLog as TAGMultiLog).Logs.Add(TAGNullLog.Create());
  (MultiLog as TAGMultiLog).Logs.Add(TAGDiskLog.Create('test.log'));
  (MultiLog as TAGMultiLog).Logs.Add(TAGRamLog.Create());
{$IFNDEF MSWINDOWS}(MultiLog as TAGMultiLog).Logs.Add(TAGCommandLineLog.Create(GetStdHandle(STD_OUTPUT_HANDLE))){$ENDIF};
  try
    s := TFile.ReadAllBytes('test2.log');
  except
    s := TBytes.Create();
  end;
  Stream := TFileStream.Create('test2.log', fmCreate + fmOpenReadWrite +
    fmShareDenyWrite);
  Stream.WriteBuffer(s, length(s));
  (MultiLog as TAGMultiLog).Logs.Add(TAGStreamLog.Create(Stream));
  (MultiLog as TAGMultiLog)
    .Logs.Add(TAGCallBackLog.Create(procedure(s: string)
  begin Self.WriteLn(s); end)); { }
  MultiLog.Write('Str Test');
  MultiLog.Write('Str+Object Test', Self);
  FreeAndNil(MultiLog);
end;

initialization

TDUnitX.RegisterTestFixture(TMyTestObject);

end.
