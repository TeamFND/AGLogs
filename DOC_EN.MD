﻿
# Description of AG.Logs library

## TAGLog

It is abstract class for using in any parts of code.
  
### public metods & propertys

+ #### class function GenerateLogString(const s:string;o:TObject=nil):string;static;

	Function for add time and object information (if o is not nil) to string

+ #### procedure Indent();

	Procedure for add ident to all next strings.

+ #### procedure UnIndent();

	Procedure for remove ident from all next strings.

+ #### procedure Write(const Text:string;o:TObject=nil);

	Write string in log.

+ #### property IndentText:string;

	String what using as indent symbol in log string. Default is DefOneTabStr const(two spaces).

********************************************
## TAGRamLog

Write log in RAM buffer.

### public metods & propertys

+ #### buf:String;

	Buffer when you can find log.

********************************************
## TAGDiskLog

File log.

### public metods & propertys

+ #### constructor Create(const FileName:String);

	Use to create log from file name. If file not exist if will created.

********************************************
## TAGNullLog

Use if you don't need log, but don't want del logging from code.

********************************************
## TAGCommandLineLog

Write log to command line.

### public metods & propertys

+ #### constructor Create(Handele:THandle);

	Use to create log from winapi handle. Use as:

	`Log:=TAGCommandLineLog.Create(GetStdHandle(STD_OUTPUT_HANDLE));`

********************************************
## TAGStreamLog

Write log to pascal stream.

### public metods & propertys

+ #### constructor Create(Astream:TStream);

	Use to create log from pascal stream.

********************************************
## TAGCallBackLog

Write log to callback.

### public metods & propertys
      
+ #### TCallBack

	Type. In delphi it is anonimus procedure, in free pascal - standart procedure. Declaration:

	`TCallBack={$IFNDEF FPC}reference to{$ENDIF}procedure(s:string);`

+ #### constructor Create(ACallBack:TCallBack);

	Use to create log from callback.

********************************************
## TAGMultiLog

Write all to other logs.

### public metods & propertys
      
+ #### TLogsList

	Type for list of logs. In delphi it is `System.Generics.Collections.TList`, in free pascal - `FGL.TFPGList`. Declaration:

	`TLogsList={$IFDEF FPC}specialize TFPGList<TAGLog>{$ELSE}TList<TAGLog>{$ENDIF}`

+ #### constructor Create(ALogs:TLogsList);

	Use to create log from TLogsList. If ALogs is nil.




