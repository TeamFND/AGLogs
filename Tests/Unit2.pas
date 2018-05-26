unit Unit2;

interface
uses
  DUnitX.TestFramework,AG.Logs,System.Classes,System.IOUtils,System.SysUtils,Winapi.Windows;

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
  MultiLog:TAGLog;
  Stream:TStream;
  s:string;
begin
MultiLog:=TAGMultiLog.Create(nil);
(MultiLog as TAGMultiLog).Logs.Add(TAGNullLog.Create());
(MultiLog as TAGMultiLog).Logs.Add(TAGDiskLog.Create('test.log'));
(MultiLog as TAGMultiLog).Logs.Add(TAGRamLog.Create());
//(MultiLog as TAGMultiLog).Logs.Add(TAGCommandLineLog.Create(GetStdHandle()));
s:=TFile.ReadAllText('test2.log');
Stream:=TFileStream.Create('test2.log',fmCreate+fmOpenReadWrite+fmShareDenyWrite);
Stream.Write(PWidechar(s)^,2*length(s));
(MultiLog as TAGMultiLog).Logs.Add(TAGStreamLog.Create(Stream));
//(MultiLog as TAGMultiLog).Logs.Add(TAGCallBackLog.Create());
MultiLog.Write('aaaaaaaaaaa',self);
FreeAndNil(MultiLog);
end;

initialization
  TDUnitX.RegisterTestFixture(TMyTestObject);
end.
