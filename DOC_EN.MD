﻿
# Description of AG.Logs library

## TAGLog = class abstract

It is abstract class for using in any parts of code.
  
### public metods & propertys

+ #### class function GenerateLogString(const s:string;o:TObject=nil):string;static;

	Function for add time and object information (if o is not nil) to string.

+ #### procedure Indent();

	Procedure for add indent to all next strings.

+ #### procedure UnIndent();

	Procedure for remove indent from all next strings.

+ #### procedure Write(const Text:string;o:TObject=nil);

	Procedure for writing string in log.

+ #### property IndentText:string;

	String what using as indent symbol in logs. Default value is DefOneTabStr const(two spaces).

********************************************
## TAGRamLog = class(TAGLog)

Write log in RAM buffer.

### public metods & propertys

+ #### buf:String;

	Buffer when you can find log.

********************************************
## TAGDiskLog = class(TAGLog)

File log.

### public metods & propertys

+ #### constructor Create(const FileName:String);

	Use to create log from file name. If file not exist if will created.

********************************************
## TAGNullLog = class(TAGLog)

Doesn't do anything.

Use if you don't need log, but don't want del logging from code.

********************************************
## TAGCommandLineLog = class(TAGLog)

Write log to command line.

### public metods & propertys

+ #### constructor Create();

	Use to create log to default commandline.

+ #### constructor Create(Handele:THandle);

	Use to create log from winapi handle (Windows only). Use as:

	`Log:=TAGCommandLineLog.Create(GetStdHandle(STD_OUTPUT_HANDLE));`

********************************************
## TAGStreamLog = class(TAGLog)

Write log to pascal stream (TStream).

### public metods & propertys

+ #### constructor Create(Astream:TStream);

	Use to create log from pascal stream (TStream).

********************************************
## TAGCallBackLog = class(TAGLog)

Write log to callback.

### public metods & propertys
      
+ #### TCallBack

	Type. In delphi it is anonimus procedure, in free pascal - standart procedure. Declaration:

	`TCallBack={$IFNDEF FPC}reference to{$ENDIF}procedure(s:string);`

+ #### constructor Create(ACallBack:TCallBack);

	Use to create log from callback.

********************************************
## TAGMultiLog = class(TAGLog)

Writes several logs.

### public metods & propertys
      
+ #### TLogsList

	Type for list of logs. In delphi it is `System.Generics.Collections.TList`, in free pascal - `FGL.TFPGList`. Declaration:

	`TLogsList={$IFDEF FPC}specialize TFPGList<TAGLog>{$ELSE}TList<TAGLog>{$ENDIF}`

+ #### constructor Create(ALogs:TLogsList);

	Use to create log from TLogsList. If ALogs is nil will used empty list.