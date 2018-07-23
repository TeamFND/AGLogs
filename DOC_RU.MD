﻿
# Описание of AG.Logs library

## TAGLog = class abstract

Это абстрактный класс для использования в любых местах кода.
  
### Публичные методы и свойства

+ #### class function GenerateLogString(const s:string;o:TObject=nil):string;static;

	Функция для добавления времени и информации об объекте (если o не nil) в строку.

+ #### procedure Indent();

	Процедура для добавления отступа ко всем следующим строкам.

+ #### procedure UnIndent();

	Процедура для удаления отступа из всех следующих строк.

+ #### procedure Write(const Text:string;o:TObject=nil);

	Запись строки в лог.

+ #### property IndentText:string;

	Строка, которая используется как символ отступа в логах. Значение по умолчанию рано константе DefOneTabStr(два пробела).

********************************************
## TAGRamLog = class(TAGLog)

Пишет лог в бувер в опереативной памяти.

### Публичные методы и свойства

+ #### buf:String;

	Буфер куда ведётся логирование.

********************************************
## TAGDiskLog = class(TAGLog)

Файловый лог.

### Публичные методы и свойства

+ #### constructor Create(const FileName:String);

	Используйте чтобы создать лог по имени вайла. If file not exist if will created.

********************************************
## TAGNullLog = class(TAGLog)

Не делает ничего.

Используйте если вы не нуждатесь в логе, но не хотоите удалять логироание из кода.

********************************************
## TAGCommandLineLog = class(TAGLog)

Пишет лог в командную строку.

### Публичные методы и свойства

+ #### constructor Create();

        Используйте чтобы создать лог в основную коммандную сроку.   

+ #### constructor Create(Handele:THandle);

	Используйте чтобы создать лог по winapi handle'у (Только для Windows). Пример использования:

	`Log:=TAGCommandLineLog.Create(GetStdHandle(STD_OUTPUT_HANDLE));`

********************************************
## TAGStreamLog = class(TAGLog)

Пишел лог в поток паскаля (TStream).

### Публичные методы и свойства

+ #### constructor Create(Astream:TStream);

	Используйте чтобы создать лог из потока паскаля (TStream).

********************************************
## TAGCallBackLog = class(TAGLog)

Пишел лог в callback-процедуру (TStream).

### Публичные методы и свойства
      
+ #### TCallBack

	Тип данных. В delphi это анонимная процедура, во free pascal'е - обычная процедура. Объявление:

	`TCallBack={$IFNDEF FPC}reference to{$ENDIF}procedure(s:string);`

+ #### constructor Create(ACallBack:TCallBack);

	Используйте чтобы создать лог из callback'а.

********************************************
## TAGMultiLog = class(TAGLog)

Пишет несколько логов.

### Публичные методы и свойства

+ #### TLogsList

	Тип для списка логов. В delphi это `System.Generics.Collections.TList`, во free pascal'е - `FGL.TFPGList`. Объявление:

	`TLogsList={$IFDEF FPC}specialize TFPGList<TAGLog>{$ELSE}TList<TAGLog>{$ENDIF}`

+ #### constructor Create(ALogs:TLogsList);

	Используйте чтобы создать лог из TLogsList'a. Если ALogs равен nil, будет использоваться пустой список.