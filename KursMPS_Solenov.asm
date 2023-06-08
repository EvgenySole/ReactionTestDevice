.386
RomSize    EQU   4096

DigOutPort = 0FEh            ; Порт вывода кода символа
IndSlctPort = 0FDh           ; Порт выбора семисегментного индикатора
ModeSlctPort = 0FBh          ; Порт вывода текущего режима

InButtonPort1 = 0FEh         ; Порт считывания клавиш 1
InButtonPort2 = 0FDh         ; Порт считывания клавиш 2

SizeOfElemResMass = 3        ; Размер одного элемента массива результатов

TimeStart = 500h             ; Время ожидания 1 секунды
TimeMS = 06                  ; Время ожидания 1 миллисекунды

IntTable   SEGMENT use16 AT 0
IntTable   ENDS

Data       SEGMENT use16 AT 40h
           DigDS      db 10 dup(?)
           TablDS     db 10 dup(?)
           ReactTime  dw ?
           ReactTimeOld dw ?
           RandomNum  dw ?
           ReadyImageDS db 3 dup(?)
           ErrorImageDS db 3 dup(?)
           StartImageDS db 3 dup(?)
           ResMassDS    db 150 dup(?)
           ResMassSortDS db 150 dup(?)
           NumOfReact db ?
           NumOfReact3 dw ?
           NumOfRes   dw ?
           Buttons    dw ?
           ButtonsCheck dw ?
           InputNum   db ?
           NumOfMode  db ?
           InPort1Old db ?
           InPort2Old db ?
           NextByteFl db ?
           IsStartFl  db ?
           IsEndFl    db ?
           IsIncNumReact db ?
           RandGenFl db ?
           DelayEndFl db ?
           DelayMSEndFl db ?
           TimeStartDS dw ?
           TimeMSDS   db ?
           IsRandomTime db ?
           IsStartTest db ?
           IsSortMass  db ?
           SortVar    dw ?
           IsInitStart db ?
           ErrorFlag  db ?
Data       ENDS

Stk        SEGMENT use16 AT 2000h
           dw    16 dup (?)
StkTop     Label Word
Stk        ENDS

InitData   SEGMENT use16
InitDataStart:
InitDataEnd:
InitData   ENDS

Code       SEGMENT use16
           ASSUME cs:Code,ds:Data,es:Data
           
           ReadyImage db 60h, 7Ch, 5Dh    ; Массив отображения готовности "Rdy"
           ErrorImage db 73h, 60h, 60h    ; Массив отображения ошибки "Err"
           StartImage db 40h, 40h, 40h    ; Массив отображения начала "---"
           
           ; Таблица преобразования
           Tabl db 0C0h, 0F3h, 89h, 0A1h, 0B2h, 0A4h, 84h, 0F1h, 80h, 0A0h
           
Init       PROC  Near
           lea   si, Tabl                 ; Подготовка таблицы преобразования
           lea   di, TablDS               ; Пересылка в сегмент данных
           mov   cx, size TablDS         
Init1:     mov   al, cs:[si]
           not   al
           mov   ds:[di], al
           inc   si
           inc   di
           loop  Init1
           
           mov   ax, 0                    ; Подготовка массива результатов
           lea   di, ResMassDS            ; Обнуление всех байтов
           mov   cx, size ResMassDS
Init2:     mov   [di], al
           inc   di
           loop  Init2
           
           mov   ax, 0                    ; Подготовка отсортированного массива результатов
           lea   di, ResMassSortDS        ; Обнуление всех байтов
           mov   cx, size ResMassSortDS
Init3:     mov   [di], al
           inc   di
           loop  Init3
           
           lea   si, ReadyImage           ; Подготовка массива отображения готовности
           lea   di, ReadyImageDS         ; Пересылка в сегмент данных
           mov   cx, size ReadyImageDS
Init4:     mov   al, cs:[si]
           mov   [di], al
           inc   si
           inc   di
           loop  Init4
           
           lea   si, ErrorImage           ; Подготовка массива отображения ошибки
           lea   di, ErrorImageDS         ; Пересылка в сегмент данных
           mov   cx, size ErrorImageDS
Init5:     mov   al, cs:[si]
           mov   [di], al
           inc   si
           inc   di
           loop  Init5
           
           lea   si, StartImage           ; Подготовка массива отображения начала
           lea   di, StartImageDS         ; Пересылка в сегмент данных
           mov   cx, size StartImageDS
Init6:     mov   al, cs:[si]
           mov   [di], al
           inc   si
           inc   di
           loop  Init6
           
           mov   IsStartFl, 0             ; Инициализация флага начала
           mov   IsEndFl, 0               ; Инициализация флага окончания
           mov   ErrorFlag, 0             ; Инициализация флага ошибки
           mov   ReactTime, 0             ; Инициализация времени реакции
           mov   ReactTimeOld, 0          ; Инициализация прошлого времени реакции
           mov   NumOfMode, 1             ; Инициализация номера режима
           mov   NumOfReact, 0            ; Инициализация номера испытания для отображения
           mov   NumOfReact3, 0           ; Инициализация номера испытания 
           mov   NumOfRes, 0              ; Инициализация номера результата
           mov   Buttons, 0               ; Инициализация образа передних фронтов клавиш
           mov   ButtonsCheck, 0          ; Инициализация образа зажатых клавиш
           mov   TimeStartDS, TimeStart   ; Инициализация времени ожидания 1 секунду
           mov   TimeMSDS, TimeMS         ; Инициализация времени ожидания 1 миллисекунду
           
           mov   InPort1Old, 0
           mov   InPort2Old, 0
           mov   DelayEndFl, 0FFh
           mov   DelayMSEndFl, 0FFh
           mov   NextByteFl, 0
           mov   IsStartTest, 0           ; Инициализация вспомогательных переменных
           mov   IsIncNumReact, 0
           mov   IsSortMass, 0
           mov   IsInitStart, 0FFh
           mov   IsRandomTime, 0
           RET
Init       ENDP   


DrebDelete1 PROC  NEAR
DrebReset1: mov   ah, al
           mov   cx, 50
DrebLoop1:  in    al, InButtonPort1       ; Удаление дребезга для 1 порта клавиш 
           not   al                    
           cmp   al, ah                   
           jnz   DrebReset1
           loop  DrebLoop1
           mov   al, ah
           RET
DrebDelete1 ENDP  


DrebDelete2 PROC  NEAR
DrebReset2: mov   ah, al
           mov   cx, 50
DrebLoop2:  in    al, InButtonPort2       ; Удаление дребезга для 2 порта клавиш 
           not   al                    
           cmp   al, ah                   
           jnz   DrebReset2
           loop  DrebLoop2
           mov   al, ah
           RET
DrebDelete2 ENDP  


ReadButtons   PROC  NEAR
           in    al, InButtonPort1
           not   al
           call  DrebDelete1              ; Удаление дребезга младшего байта
           mov   byte ptr ButtonsCheck, al
                                          ; Сохранение младшего байта для проверки на ошибку
           mov   bl, al
           xor   bl, InPort1Old           ; Выделение переднего фронта младшего байта
           mov   InPort1Old, al         
           and   al, bl
           mov   dl, al
           in    al, InButtonPort2
           not   al
           call  DrebDelete2              ; Удаление дребезга старшего байта
           mov   byte ptr ButtonsCheck+1, al
                                          ; Сохранение старшего байта для проверки на ошибку
           mov   bl, al
           xor   bl, InPort2Old           ; Выделение переднего фронта старшего байта
           mov   InPort2Old, al         
           and   al, bl
           mov   dh, al
           mov   Buttons, dx              ; Сохранение образа фронтов клавиш

ReadButtonsEnd:           
           RET
ReadButtons   ENDP


ErrorCheck PROC NEAR
           mov   ErrorFlag, 0
           mov   bl, 0
           mov   dx, ButtonsCheck         ; Загрузка образа нажатых клавиш
CheckLoop: 
           test  dx, 0FFFFh               ; Проверка на флаг знака
           js    ReadError                ; Если флаг знака активен, то инкремент накопителя
           jmp   NextBit
ReadError: 
           inc   bl
NextBit:   shl   dx, 1                    ; Сдвиг влево для появления бита в разряде знака
           jnz   CheckLoop    
           cmp   bl, 1                    ; Если нажато больше 1 клавиши, то взводится флаг ошибки 
           jbe   ErrorCheckEnd
           mov   ErrorFlag, 0FFh

ErrorCheckEnd:
           RET
ErrorCheck ENDP   


StartControl  PROC  NEAR
           cmp   ErrorFlag, 0FFh          ; Если ошибка, то выход
           jz    StartControlEnd
           cmp   Buttons, 1000h           ; Проверка на бит клавиши Старт
           jnz   StartControlEnd 
SC1:       cmp   IsInitStart, 0FFh
           jz    SC3 
SC2:       cmp   IsIncNumReact, 0FFh      ; Если испытание завершилось, 
           jnz   SC4                      ; то инкрементировать номер испытания
           mov   al, NumOfReact              
           add   al, 1                    ; Инкремент номера испытания
           daa
           mov   NumOfReact, al
           add   NumOfReact3, SizeOfElemResMass
           mov   IsIncNumReact, 0
           mov   IsRandomTime, 0FFh       ; Разрешение на генерацию случайного времени
SC3:       mov   ax, ReactTime            ; Сохранение прошлого времени реакции
           mov   ReactTimeOld, ax
           mov   ReactTime, 0             ; Обнуление текущего времени реакции
SC4:       not   IsStartFl                ; Инвертирование флага начала
           mov   RandGenFl, 0FFh          ; Разрешение на генерацию случайного числа
           mov   IsEndFl, 0               ; Сброс флага окончания испытания
           mov   IsStartTest, 0FFh        ; Взвод флага начала измерения реакции
           mov   DelayEndFl, 0            ; Сброс флага окончания задержки перед испытанием
           mov   IsInitStart, 0           ; Сброс флага первого испытания
           cmp   IsStartFl, 0             ; Если флаг начала испытания неактивен, то
           jnz   StartControlEnd
           mov   IsEndFl, 0FFh            ; Взвод флага окончания испытания
           mov   DelayEndFl, 0FFh         ; Взвод флага окончания задержки
StartControlEnd:
           RET
StartControl  ENDP


ModeControl   PROC  NEAR
           cmp   IsStartFl, 0FFh            ; Если идет испытание или ошибка, то выход
           jz    ModeControlEnd
           cmp   ErrorFlag, 0FFh
           jz    ModeControlEnd
           cmp   Buttons, 2000h             ; Проверка на бит клавиши Режим
           jnz   ModeControlEnd
           shl   NumOfMode, 1               ; Сдвиг влево
           cmp   NumOfMode, 4
           jnz   MC1
           mov   NumOfRes, 0
MC1:       cmp   NumOfMode, 4               
           jbe   ModeControlEnd
           mov   NumOfMode, 1               ; Если сдвиг был 3 раза, то сброс на значение 1
ModeControlEnd:
           RET
ModeControl   ENDP


ResultsControl PROC  NEAR
           cmp   ErrorFlag, 0FFh            ; Если идет испытание или ошибка, то выход
           jz    ResultsControlEnd
           cmp   Buttons, 4000h             ; Проверка на бит клавиши Вверх
           jnz   DownButton         
           mov   ax, NumOfRes
           add   ax, SizeOfElemResMass      ; Добавление к адресу результата 3 пока
           cmp   ax, NumOfReact3            ; не будет равно или больше количества испытаний
           jb    RC1
           mov   ax, 0                      ; Иначе обнуление
RC1:       mov   NumOfRes, ax  
DownButton:
           cmp   Buttons, 8000h             ; Проверка на бит клавиши Вверх
           jnz   ResultsControlEnd  
           mov   ax, NumOfRes
           sub   ax, SizeOfElemResMass      ; Вычитание из адреса результата 3 пока
           cmp   ax, NumOfReact3            ; не будет равно или больше количества испытаний
           jb    RC2
           mov   ax, NumOfReact3; 297       ; Иначе присвоение адреса последнего элемента
           cmp   NumOfReact, 0
           jz    RC2
           sub   ax, 3                      ; Перемещение на начало последнего элемента
RC2:       mov   NumOfRes, ax
ResultsControlEnd:  
           RET
ResultsControl ENDP


DelayMS   PROC  NEAR                        ; Задержка 1 миллисекунда
           sub   TimeMSDS, 1                ; Вычитание из переменной времени
           mov   DelayMSEndFl, 0
           cmp   TimeMSDS, 0                ; Выход если не равно нулю
           jnz   DelayMSEndM
           mov   DelayMSEndFl, 0FFh         ; Иначе взвод флага окончания задержки
           mov   TimeMSDS, TimeMS           ; Восстановление переменной миллисекунды
DelayMSEndM: 
           RET
DelayMS   ENDP


InitRandom PROC NEAR
           cmp   IsInitStart, 0             ; Если первое испытание прошло, то выход
           jz    EndInitRandom
           call  DelayMS                    ; Задержка 1 миллисекунда
           cmp   DelayMSEndFl, 0
           jz    EndInitRandom
           mov   DelayMSEndFl, 0FFh         ; Если задержка окончена, 
           lea   si, ReactTime              ; то подотовка к генерации случайного числа и времени
           mov   al, [si]
           add   al, 1                      ; Инкремент переменной случайного времени
           daa
           mov   [si], al
           mov   al, [si+1]                 ; Добавление переноса и десятичная коррекция
           adc   al, 0
           daa
           mov   [si+1], al
           mov   ax, ReactTime
           mov   ReactTimeOld, ax           ; Сохранение в прошлое время реакции
           mov   RandGenFl, 0FFh            ; Разрешение на генерацию случайного числа и времени 
EndInitRandom:
           RET
InitRandom ENDP


GenerateRand PROC NEAR
           cmp   RandGenFl, 0FFh            ; Если не разрешена генерация, то выход
           jnz   GenRandEnd
           mov   ax, ReactTimeOld           ; Загрузка прошлого времени реакции
           mov   ah, 0
           mov   bh, 2
           mul   bh                         ; Умножение на 2 прошлого времени реакции
           mov   bx, ax
           mov   ax, ReactTimeOld           ; Загрузка прошлого времени реакции
           mov   ah, 0
           cmp   IsRandomTime, 0            ; Если разрешена генерация случайного времени, 
           jz    GenRand1
           add   TimeStartDS, ax            ; то добавление умноженного на 2 прошлого времени реакции
           mov   IsRandomTime, 0
GenRand1:  mov   bl, 12
           div   bl                         ; Деление младшего байта прошлого времени на 12
           sub   al, 0  
           daa                              ; Десятичная коррекция
           mov   ah, 0
           cmp   al, 12h
           jbe   GenRand2                   ; Если больше 12, то дополнительное деление на 2
           mov   bl, 2
           div   bl
           sub   al, 0                      
           daa                              ; Десятичная коррекция
GenRand2:                        
           cmp   ax, 0
           jnz   GenRand3                   ; Если равно 0, то присвоение 3
           mov   ax, 3
GenRand3:  mov   RandomNum, ax
           mov   RandGenFl, 0               ; Запрет на генерацию случайного числа       
GenRandEnd:           
           RET
GenerateRand ENDP


ReadNumbers PROC NEAR
           cmp   ErrorFlag, 0FFh            ; Если ошибка, то выход
           jz    ReadNumbersEnd
           cmp   IsStartTest, 0             ; Если счетчик реакции не разрешен, то выход
           jz    ReadNumbersEnd
           cmp   IsEndFl, 0FFh              ; Если испытание окончено, то выход
           jz    ReadNumbersEnd
           mov   dx, Buttons
           and   dx, 0FFFh                  ; Применение маски для устранения
           mov   ax, 0                      ; от тетрады управляющих клавиш
           cmp   dx, 0
           jz    ReadNumbersEnd             ; Если не нажата ни одна клавиша, то выход     
ReadNum:   shr   dx, 1
           add   al, 1
           daa                              ; Преобразование в позиционный код
           cmp   dx, 0
           jz    ReadNumEnd
           loop  ReadNum   
ReadNumEnd:
           cmp   ax, RandomNum
           jnz   ReadNumbersEnd             ; Если нажата правильная клавиша,
           mov   IsEndFl, 0FFh              ; то взвод флага окончания испытания
           mov   IsStartTest, 0             ; и разрешение на инкремент номера испытания
           mov   IsIncNumReact, 0FFh
ReadNumbersEnd:
           RET
ReadNumbers ENDP


ReactTest  PROC  NEAR
           cmp   IsStartTest, 0             ; Если счетчик реакции не разрешен, то выход
           jz    ReactTestEnd
           cmp   IsEndFl, 0FFh              ; Если испытание окончено, то выход
           jz    ReactTestEnd
           cmp   DelayEndFl, 0              ; Если задержка не окончена, то выход
           jz    ReactTestEnd
           cmp   ReactTime, 9990h           ; Фиксирование максимального значения реакции на 9999h
           jb    ReactTestInc
           mov   ReactTime, 9999h
           jmp   ReactTestEnd   
ReactTestInc:
           call  DelayMS                    ; Задержка 1 миллисекунда
           cmp   DelayMSEndFl, 0            ; Если задержка не окончена, то выход
           jz    ReactTestEnd
           mov   DelayMSEndFl, 0FFh         ; Взвод флага окончания задержки
           lea   si, ReactTime
           mov   al, [si]
           add   al, 9; 76
           daa                              ; Добавление к текущему времени реакции и корректировка
           mov   [si], al
           mov   al, [si+1]
           adc   al, 0
           daa
           mov   [si+1], al
ReactTestEnd: 
           RET
ReactTest  ENDP


WriteCurRes PROC NEAR
           cmp   IsIncNumReact, 0FFh        ; Если не разрешен инкремент номера реакции, то выход
           jnz   WCREnd
           lea   di, ResMassDS
           lea   si, ReactTime
           mov   ah, 0
           mov   ax, NumOfReact3
           mov   bx, ax
           mov   al, NumOfReact
           mov   [di+bx], al                ; Загрузка в первый байт элемента номера реакции
           inc   bx
           mov   al, [si+1]
           mov   [di+bx], al                ; Загрузка во второй байт элемента старшего байта времени реакции
           inc   bx
           mov   al, [si]
           mov   [di+bx], al                ; Загрузка в третий байт элемента младшего байта времени реакции
           mov   IsSortMass, 0FFh           ; Взвод флага разрешения копирования и сортировки массива
WCREnd:           
           RET
WriteCurRes ENDP


CopySortMass PROC NEAR
           cmp   IsSortMass, 0               ; Если флаг разрешения сортировки не активен, то выход
           jz    CopySortEnd
           
           lea   si, ResMassDS
           lea   di, ResMassSortDS
           mov   ch, 0
           mov   cx, NumOfReact3
           inc   cx
           
CopySort1: mov   al, [si]
           mov   [di], al                   ; Копирование массива в сортированный массив
           inc   si
           inc   di
           loop  CopySort1
           cmp   NumOfReact, 2
           jb    CopySortEnd
           mov   ax, NumOfReact3
           mov   bl, SizeOfElemResMass 
           div   bl  
           mov   cl, al
           dec   cx
           mov   bx, 0
Sorting:                                    ; Сортировка массива методом "Пузырек"
           push  cx
           lea   si, ResMassSortDS
Change:
           mov   al, [si+2]
           mov   ah, [si+1]
           mov   dl, [si+5]
           mov   dh, [si+4]
           cmp   ax, dx
           jbe   NoChange   
           mov   bl, [si+2]
           mov   bh, [si+1]
           mov   SortVar, bx  
           mov   bl, [si+5]
           mov   bh, [si+4]
           mov   [si+2], bl
           mov   [si+1], bh 
           mov   bx, SortVar 
           mov   [si+5], bl
           mov   [si+4], bh 
           mov   bl, [si]
           mov   al, bl
           mov   bl, [si+3]
           mov   [si], bl
           mov   [si+3], al                 
NoChange:
           add   si, 3
           loop  Change
           pop   cx
           loop  Sorting                    ; Окончание сортировки массива  
CopySortEnd:
           RET
CopySortMass ENDP

           
DispMode   PROC  NEAR
           mov   al, NumOfMode              ; Вывод унитарного кода на индикаторы режимов
           out   ModeSlctPort, al    
           RET
DispMode   ENDP


DispMassResults PROC NEAR  
           cmp   NumOfMode, 1               ; Если режим Испытание, то выход
           jz    DNOREnd
           mov   ah, 20h                    ; Начальный индикатор выбираем 6
           mov   bh, 0
           mov   cx, 6                      ; Счетчик цикла на количество индикаторов

           lea   si, ErrorImageDS           ; Загрузка массива индикации ошибки
           cmp   ErrorFlag, 0FFh            ; Если ошибка, то переход к выводу массива ошибки
           jz    Error1
           
           mov   di, NumOfRes               ; Загрузка смещения адреса выбранного результата
           lea   si, ResMassSortDS
           cmp   NumOfMode, 4               ; Если режим = 4, загрузка сортированного массива
           jz    SortedMass                 ; Если режим = 2, загрузка обычного массива
           lea   si, ResMassDS
SortedMass:
           mov   NextByteFl, 0              
DNOR1:     mov   al, ah
           not   al
           out   IndSlctPort, al
           mov   bx, di
           mov   al, [si+bx]                ; Загрузка очередного байта
           cmp   NextByteFl, 0
           jz    DNOR2
           inc   di                         ; Модификация адреса
           and   al, 0Fh                    ; Выделение младшей тетрады  
           jmp   DNOR3
DNOR2:     shr   al, 4                      ; Выделение старшей тетрады
DNOR3:     lea   bx, TablDS                 ; Загрузка таблицы преобразований
           xlat                             ; Преобразование цифры в код
           out   DigOutPort, al             ; Вывод кода цифры
           mov   al, 0FFh
           out   IndSlctPort, al            ; Выключение индикатора
           not   al
           out   DigOutPort, al    
           shr   ah, 1                      ; Сдвиг на следующий индикатор
           not   NextByteFl                 ; Инвертирование флага выбора тетрады
           loop  DNOR1
           jmp   DNOREnd
Error1:    mov   al, ah                     ; Вывод индикации об ошибке
           not   al                         ; на индикаторы 4, 3, 2
           out   IndSlctPort, al
           cmp   cx, 4
           ja    NextDig
           mov   al, [si]   
           inc   si                 
           out   DigOutPort, al
           mov   al, 0FFh
           out   IndSlctPort, al
           not   al
           out   DigOutPort, al    
NextDig:   shr   ah, 1   
           cmp   cx, 2
           jz    DNOREnd
           loop  Error1
DNOREnd:   
           RET  
DispMassResults ENDP
        
        
DelaySec   PROC  NEAR
           cmp   DelayEndFl, 0FFh           ; Если задержка уже прошла, то выход
           jz    DelayEndM
           sub   TimeStartDS, 1             ; Декремент из времени ожидания секунды
           mov   DelayEndFl, 0
           jnz   DelayEndM                  ; Если не равно нулю, то выход
           mov   DelayEndFl, 0FFh           ; Взвод флагов окончания и начала счетчика реакции
           mov   IsStartTest, 0FFh
           mov   TimeStartDS, TimeStart     ; Восстановление времени ожидания секунды
DelayEndM: 
           RET
DelaySec   ENDP   
           

DispReactTest PROC  NEAR
           cmp   NumOfMode, 1
           jnz   DRTEnd
           call  DelaySec                   ; Задержка 1 секунда перед выводом случайного числа          
           mov   ah, 20h                    ; Начальный индикатор выбираем 6
           mov   al, 0
           mov   bh, 0
           mov   dl, NumOfReact             ; Загрузка отображения номера реакции
           add   al, dl
           daa
           mov   dl, al
           mov   NextByteFl, 0
           mov   cx, 6                      ; Счетчик цикла на количество индикаторов
           lea   si, StartImageDS           ; Загрузка массива отображения начала испытания
           cmp   DelayEndFl, 0              ; Если задержка не заончилась, то переход к выводу
           jz    DRT1
           lea   si, ErrorImageDS           ; Загрузка массива отображения ошибки
           cmp   ErrorFlag, 0FFh            ; Если ошибка есть, то то переход к выводу
           jz    DRT1
           cmp   IsStartFl, 0FFh            ; Если испытание началось, то переход к выводу случайного
           jz    DispRandDig   
           lea   si, ReadyImageDS           ; Загрузка массива отображения готовности
DRT1:      mov   al, ah
           not   al
           out   IndSlctPort, al            ; Выбор индикатора
           cmp   ErrorFlag, 0
           jz    NumReactM1                 ; Если ошибки нет, то вывод номера реакции
           cmp   cx, 4
           ja    NextDig1
NumReactM1:
           cmp   cx, 5
           jb    ReadyIm
           mov   al, dl 
           cmp   NextByteFl, 0              ; Проверка выбора тетрады
           jz    DRT2
           and   al, 0Fh                    ; Выделение младшей тетрады
           jmp   NumReactM    
DRT2:      shr   al, 4                      ; Выделение старшей тетрады
           jmp   NumReactM      
ReadyIm:   mov   al, [si]
           inc   si
           jmp   ReadyIm2                   ; Вывод массива отображения начала, готовности или ошибки    
NumReactM: lea   bx, TablDS                 ; Загрузка таблицы преобразования
           xlat                             ; Преобразование цифр в коды
ReadyIm2:  out   DigOutPort, al             ; Вывод кода символа
           mov   al, 0FFh
           out   IndSlctPort, al            ; Выключение индикатора
           not   al
           out   DigOutPort, al    
NextDig1:  shr   ah, 1                      ; Сдвиг бита на следующий нидикатор
           not   NextByteFl                 ; Инвертирвание выбора выделения тетрады
           cmp   cx, 2
           jz    DRTEnd
           loop  DRT1
           jmp   DRTEnd        
DispRandDig:     
           lea   si, RandomNum+1            ; Загрузка случайного числа
           cmp   IsEndFl, 0          
           jz    DRT4                
           lea   si, ReactTime+1            ; Если испытание закончилось, то загрузка времени реакции              
DRT4:      mov   al, ah
           not   al
           out   IndSlctPort, al            ; Выбор индикатора
           cmp   cx, 4
           ja    DRT5
RandomNum1: 
           mov   dl, [si]                   ; Загрузка байта случайного числа или времени реакции
           cmp   NextByteFl, 0
           jz    DRT5
           dec   si                         ; Модификация адреса
DRT5:      mov   al, dl                     ; Загрузка номера испытания, а потом случайного или реакции
           cmp   NextByteFl, 0
           jz    DRT6
           and   al, 0Fh                    ; Выделение младшей тетрады
           jmp   DRT7 
DRT6:      shr   al, 4                      ; Выделение старшей тетрады               
DRT7:      lea   bx, TablDS                 ; Загрузка таблицы преобразования
           xlat                             ; Преобразование цифр в коды
           out   DigOutPort, al             ; Вывод кода символа
           mov   al, 0FFh
           out   IndSlctPort, al            ; Выключение индикатора
           not   al
           out   DigOutPort, al    
           shr   ah, 1                      ; Сдвиг бита на следующий нидикатор
           not   NextByteFl                 ; Инвертирвание выбора выделения тетрады
           loop  DRT4     
DRTEnd:    
           RET
DispReactTest ENDP 
    
           
Start:
           mov   ax, Data                   ; Системная подготовка
           mov   ds, ax
           mov   es, ax
           mov   ax, Stk
           mov   ss, ax
           lea   sp, StkTop
           call  Init                       ; Функциональная подготовка
MainLoop:  call  ReadButtons                ; Считывание клавиш
           call  ErrorCheck                 ; Проверка на ошибку ввода
           call  StartControl               ; Обработка кнопки старт
           call  ModeControl                ; Обработка кнопки режим
           call  ResultsControl             ; Обработка кнопок просмотра результатов
           call  InitRandom                 ; Начальная генерация случайного числа и времени
           call  GenerateRand               ; Генерация случайного числа и времени
           call  ReadNumbers                ; Обработка клавиш с номером
           call  ReactTest                  ; Расчет времени реакции
           call  WriteCurRes                ; Сохранение текущего результата
           call  CopySortMass               ; Копирование и сортировка массива
           call  DispMode                   ; Вывод режима на индикаторы
           call  DispMassResults            ; Вывод результата на дисплей
           call  DispReactTest              ; Вывод испытания на дисплей
           jmp   MainLoop       

           org   RomSize-16-((InitDataEnd-InitDataStart+15) AND 0FFF0h)
           ASSUME cs:NOTHING
           jmp   Far Ptr Start
Code       ENDS
END		Start
