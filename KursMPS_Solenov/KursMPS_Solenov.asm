.386
RomSize    EQU   4096

DigOutPort = 0FEh            ; ���� �뢮�� ���� ᨬ����
IndSlctPort = 0FDh           ; ���� �롮� ᥬ�ᥣ���⭮�� ��������
ModeSlctPort = 0FBh          ; ���� �뢮�� ⥪�饣� ०���

InButtonPort1 = 0FEh         ; ���� ���뢠��� ������ 1
InButtonPort2 = 0FDh         ; ���� ���뢠��� ������ 2

SizeOfElemResMass = 3        ; ������ ������ ����� ���ᨢ� १���⮢

TimeStart = 500h             ; �६� �������� 1 ᥪ㭤�
TimeMS = 06                  ; �६� �������� 1 �����ᥪ㭤�

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
           
           ReadyImage db 60h, 7Ch, 5Dh    ; ���ᨢ �⮡ࠦ���� ��⮢���� "Rdy"
           ErrorImage db 73h, 60h, 60h    ; ���ᨢ �⮡ࠦ���� �訡�� "Err"
           StartImage db 40h, 40h, 40h    ; ���ᨢ �⮡ࠦ���� ��砫� "---"
           
           ; ������ �८�ࠧ������
           Tabl db 0C0h, 0F3h, 89h, 0A1h, 0B2h, 0A4h, 84h, 0F1h, 80h, 0A0h
           
Init       PROC  Near
           lea   si, Tabl                 ; �����⮢�� ⠡���� �८�ࠧ������
           lea   di, TablDS               ; ����뫪� � ᥣ���� ������
           mov   cx, size TablDS         
Init1:     mov   al, cs:[si]
           not   al
           mov   ds:[di], al
           inc   si
           inc   di
           loop  Init1
           
           mov   ax, 0                    ; �����⮢�� ���ᨢ� १���⮢
           lea   di, ResMassDS            ; ���㫥��� ��� ���⮢
           mov   cx, size ResMassDS
Init2:     mov   [di], al
           inc   di
           loop  Init2
           
           mov   ax, 0                    ; �����⮢�� �����஢������ ���ᨢ� १���⮢
           lea   di, ResMassSortDS        ; ���㫥��� ��� ���⮢
           mov   cx, size ResMassSortDS
Init3:     mov   [di], al
           inc   di
           loop  Init3
           
           lea   si, ReadyImage           ; �����⮢�� ���ᨢ� �⮡ࠦ���� ��⮢����
           lea   di, ReadyImageDS         ; ����뫪� � ᥣ���� ������
           mov   cx, size ReadyImageDS
Init4:     mov   al, cs:[si]
           mov   [di], al
           inc   si
           inc   di
           loop  Init4
           
           lea   si, ErrorImage           ; �����⮢�� ���ᨢ� �⮡ࠦ���� �訡��
           lea   di, ErrorImageDS         ; ����뫪� � ᥣ���� ������
           mov   cx, size ErrorImageDS
Init5:     mov   al, cs:[si]
           mov   [di], al
           inc   si
           inc   di
           loop  Init5
           
           lea   si, StartImage           ; �����⮢�� ���ᨢ� �⮡ࠦ���� ��砫�
           lea   di, StartImageDS         ; ����뫪� � ᥣ���� ������
           mov   cx, size StartImageDS
Init6:     mov   al, cs:[si]
           mov   [di], al
           inc   si
           inc   di
           loop  Init6
           
           mov   IsStartFl, 0             ; ���樠������ 䫠�� ��砫�
           mov   IsEndFl, 0               ; ���樠������ 䫠�� ����砭��
           mov   ErrorFlag, 0             ; ���樠������ 䫠�� �訡��
           mov   ReactTime, 0             ; ���樠������ �६��� ॠ�樨
           mov   ReactTimeOld, 0          ; ���樠������ ��諮�� �६��� ॠ�樨
           mov   NumOfMode, 1             ; ���樠������ ����� ०���
           mov   NumOfReact, 0            ; ���樠������ ����� ���⠭�� ��� �⮡ࠦ����
           mov   NumOfReact3, 0           ; ���樠������ ����� ���⠭�� 
           mov   NumOfRes, 0              ; ���樠������ ����� १����
           mov   Buttons, 0               ; ���樠������ ��ࠧ� ��।��� �஭⮢ ������
           mov   ButtonsCheck, 0          ; ���樠������ ��ࠧ� ������� ������
           mov   TimeStartDS, TimeStart   ; ���樠������ �६��� �������� 1 ᥪ㭤�
           mov   TimeMSDS, TimeMS         ; ���樠������ �६��� �������� 1 �����ᥪ㭤�
           
           mov   InPort1Old, 0
           mov   InPort2Old, 0
           mov   DelayEndFl, 0FFh
           mov   DelayMSEndFl, 0FFh
           mov   NextByteFl, 0
           mov   IsStartTest, 0           ; ���樠������ �ᯮ����⥫��� ��६�����
           mov   IsIncNumReact, 0
           mov   IsSortMass, 0
           mov   IsInitStart, 0FFh
           mov   IsRandomTime, 0
           RET
Init       ENDP   


DrebDelete1 PROC  NEAR
DrebReset1: mov   ah, al
           mov   cx, 50
DrebLoop1:  in    al, InButtonPort1       ; �������� �ॡ���� ��� 1 ���� ������ 
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
DrebLoop2:  in    al, InButtonPort2       ; �������� �ॡ���� ��� 2 ���� ������ 
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
           call  DrebDelete1              ; �������� �ॡ���� ����襣� ����
           mov   byte ptr ButtonsCheck, al
                                          ; ���࠭���� ����襣� ���� ��� �஢�ન �� �訡��
           mov   bl, al
           xor   bl, InPort1Old           ; �뤥����� ��।���� �஭� ����襣� ����
           mov   InPort1Old, al         
           and   al, bl
           mov   dl, al
           in    al, InButtonPort2
           not   al
           call  DrebDelete2              ; �������� �ॡ���� ���襣� ����
           mov   byte ptr ButtonsCheck+1, al
                                          ; ���࠭���� ���襣� ���� ��� �஢�ન �� �訡��
           mov   bl, al
           xor   bl, InPort2Old           ; �뤥����� ��।���� �஭� ���襣� ����
           mov   InPort2Old, al         
           and   al, bl
           mov   dh, al
           mov   Buttons, dx              ; ���࠭���� ��ࠧ� �஭⮢ ������

ReadButtonsEnd:           
           RET
ReadButtons   ENDP


ErrorCheck PROC NEAR
           mov   ErrorFlag, 0
           mov   bl, 0
           mov   dx, ButtonsCheck         ; ����㧪� ��ࠧ� ������� ������
CheckLoop: 
           test  dx, 0FFFFh               ; �஢�ઠ �� 䫠� �����
           js    ReadError                ; �᫨ 䫠� ����� ��⨢��, � ���६��� ������⥫�
           jmp   NextBit
ReadError: 
           inc   bl
NextBit:   shl   dx, 1                    ; ����� ����� ��� ������ ��� � ࠧ�拉 �����
           jnz   CheckLoop    
           cmp   bl, 1                    ; �᫨ ����� ����� 1 ������, � ��������� 䫠� �訡�� 
           jbe   ErrorCheckEnd
           mov   ErrorFlag, 0FFh

ErrorCheckEnd:
           RET
ErrorCheck ENDP   


StartControl  PROC  NEAR
           cmp   ErrorFlag, 0FFh          ; �᫨ �訡��, � ��室
           jz    StartControlEnd
           cmp   Buttons, 1000h           ; �஢�ઠ �� ��� ������ ����
           jnz   StartControlEnd 
SC1:       cmp   IsInitStart, 0FFh
           jz    SC3 
SC2:       cmp   IsIncNumReact, 0FFh      ; �᫨ ���⠭�� �����訫���, 
           jnz   SC4                      ; � ���६���஢��� ����� ���⠭��
           mov   al, NumOfReact              
           add   al, 1                    ; ���६��� ����� ���⠭��
           daa
           mov   NumOfReact, al
           add   NumOfReact3, SizeOfElemResMass
           mov   IsIncNumReact, 0
           mov   IsRandomTime, 0FFh       ; ����襭�� �� ������� ��砩���� �६���
SC3:       mov   ax, ReactTime            ; ���࠭���� ��諮�� �६��� ॠ�樨
           mov   ReactTimeOld, ax
           mov   ReactTime, 0             ; ���㫥��� ⥪�饣� �६��� ॠ�樨
SC4:       not   IsStartFl                ; ������஢���� 䫠�� ��砫�
           mov   RandGenFl, 0FFh          ; ����襭�� �� ������� ��砩���� �᫠
           mov   IsEndFl, 0               ; ���� 䫠�� ����砭�� ���⠭��
           mov   IsStartTest, 0FFh        ; ����� 䫠�� ��砫� ����७�� ॠ�樨
           mov   DelayEndFl, 0            ; ���� 䫠�� ����砭�� ����প� ��। ���⠭���
           mov   IsInitStart, 0           ; ���� 䫠�� ��ࢮ�� ���⠭��
           cmp   IsStartFl, 0             ; �᫨ 䫠� ��砫� ���⠭�� ����⨢��, �
           jnz   StartControlEnd
           mov   IsEndFl, 0FFh            ; ����� 䫠�� ����砭�� ���⠭��
           mov   DelayEndFl, 0FFh         ; ����� 䫠�� ����砭�� ����প�
StartControlEnd:
           RET
StartControl  ENDP


ModeControl   PROC  NEAR
           cmp   IsStartFl, 0FFh            ; �᫨ ���� ���⠭�� ��� �訡��, � ��室
           jz    ModeControlEnd
           cmp   ErrorFlag, 0FFh
           jz    ModeControlEnd
           cmp   Buttons, 2000h             ; �஢�ઠ �� ��� ������ �����
           jnz   ModeControlEnd
           shl   NumOfMode, 1               ; ����� �����
           cmp   NumOfMode, 4
           jnz   MC1
           mov   NumOfRes, 0
MC1:       cmp   NumOfMode, 4               
           jbe   ModeControlEnd
           mov   NumOfMode, 1               ; �᫨ ᤢ�� �� 3 ࠧ�, � ��� �� ���祭�� 1
ModeControlEnd:
           RET
ModeControl   ENDP


ResultsControl PROC  NEAR
           cmp   ErrorFlag, 0FFh            ; �᫨ ���� ���⠭�� ��� �訡��, � ��室
           jz    ResultsControlEnd
           cmp   Buttons, 4000h             ; �஢�ઠ �� ��� ������ �����
           jnz   DownButton         
           mov   ax, NumOfRes
           add   ax, SizeOfElemResMass      ; ���������� � ����� १���� 3 ����
           cmp   ax, NumOfReact3            ; �� �㤥� ࠢ�� ��� ����� ������⢠ ���⠭��
           jb    RC1
           mov   ax, 0                      ; ���� ���㫥���
RC1:       mov   NumOfRes, ax  
DownButton:
           cmp   Buttons, 8000h             ; �஢�ઠ �� ��� ������ �����
           jnz   ResultsControlEnd  
           mov   ax, NumOfRes
           sub   ax, SizeOfElemResMass      ; ���⠭�� �� ���� १���� 3 ����
           cmp   ax, NumOfReact3            ; �� �㤥� ࠢ�� ��� ����� ������⢠ ���⠭��
           jb    RC2
           mov   ax, NumOfReact3; 297       ; ���� ��᢮���� ���� ��᫥����� �����
           cmp   NumOfReact, 0
           jz    RC2
           sub   ax, 3                      ; ��६�饭�� �� ��砫� ��᫥����� �����
RC2:       mov   NumOfRes, ax
ResultsControlEnd:  
           RET
ResultsControl ENDP


DelayMS   PROC  NEAR                        ; ����প� 1 �����ᥪ㭤�
           sub   TimeMSDS, 1                ; ���⠭�� �� ��६����� �६���
           mov   DelayMSEndFl, 0
           cmp   TimeMSDS, 0                ; ��室 �᫨ �� ࠢ�� ���
           jnz   DelayMSEndM
           mov   DelayMSEndFl, 0FFh         ; ���� ����� 䫠�� ����砭�� ����প�
           mov   TimeMSDS, TimeMS           ; ����⠭������� ��६����� �����ᥪ㭤�
DelayMSEndM: 
           RET
DelayMS   ENDP


InitRandom PROC NEAR
           cmp   IsInitStart, 0             ; �᫨ ��ࢮ� ���⠭�� ��諮, � ��室
           jz    EndInitRandom
           call  DelayMS                    ; ����প� 1 �����ᥪ㭤�
           cmp   DelayMSEndFl, 0
           jz    EndInitRandom
           mov   DelayMSEndFl, 0FFh         ; �᫨ ����প� ����祭�, 
           lea   si, ReactTime              ; � ����⮢�� � �����樨 ��砩���� �᫠ � �६���
           mov   al, [si]
           add   al, 1                      ; ���६��� ��६����� ��砩���� �६���
           daa
           mov   [si], al
           mov   al, [si+1]                 ; ���������� ��७�� � �����筠� ���४��
           adc   al, 0
           daa
           mov   [si+1], al
           mov   ax, ReactTime
           mov   ReactTimeOld, ax           ; ���࠭���� � ��諮� �६� ॠ�樨
           mov   RandGenFl, 0FFh            ; ����襭�� �� ������� ��砩���� �᫠ � �६��� 
EndInitRandom:
           RET
InitRandom ENDP


GenerateRand PROC NEAR
           cmp   RandGenFl, 0FFh            ; �᫨ �� ࠧ�襭� �������, � ��室
           jnz   GenRandEnd
           mov   ax, ReactTimeOld           ; ����㧪� ��諮�� �६��� ॠ�樨
           mov   ah, 0
           mov   bh, 2
           mul   bh                         ; ��������� �� 2 ��諮�� �६��� ॠ�樨
           mov   bx, ax
           mov   ax, ReactTimeOld           ; ����㧪� ��諮�� �६��� ॠ�樨
           mov   ah, 0
           cmp   IsRandomTime, 0            ; �᫨ ࠧ�襭� ������� ��砩���� �६���, 
           jz    GenRand1
           add   TimeStartDS, ax            ; � ���������� 㬭�������� �� 2 ��諮�� �६��� ॠ�樨
           mov   IsRandomTime, 0
GenRand1:  mov   bl, 12
           div   bl                         ; ������� ����襣� ���� ��諮�� �६��� �� 12
           sub   al, 0  
           daa                              ; �����筠� ���४��
           mov   ah, 0
           cmp   al, 12h
           jbe   GenRand2                   ; �᫨ ����� 12, � �������⥫쭮� ������� �� 2
           mov   bl, 2
           div   bl
           sub   al, 0                      
           daa                              ; �����筠� ���४��
GenRand2:                        
           cmp   ax, 0
           jnz   GenRand3                   ; �᫨ ࠢ�� 0, � ��᢮���� 3
           mov   ax, 3
GenRand3:  mov   RandomNum, ax
           mov   RandGenFl, 0               ; ����� �� ������� ��砩���� �᫠       
GenRandEnd:           
           RET
GenerateRand ENDP


ReadNumbers PROC NEAR
           cmp   ErrorFlag, 0FFh            ; �᫨ �訡��, � ��室
           jz    ReadNumbersEnd
           cmp   IsStartTest, 0             ; �᫨ ���稪 ॠ�樨 �� ࠧ�襭, � ��室
           jz    ReadNumbersEnd
           cmp   IsEndFl, 0FFh              ; �᫨ ���⠭�� ����祭�, � ��室
           jz    ReadNumbersEnd
           mov   dx, Buttons
           and   dx, 0FFFh                  ; �ਬ������ ��᪨ ��� ���࠭����
           mov   ax, 0                      ; �� ��ࠤ� �ࠢ����� ������
           cmp   dx, 0
           jz    ReadNumbersEnd             ; �᫨ �� ����� �� ���� ������, � ��室     
ReadNum:   shr   dx, 1
           add   al, 1
           daa                              ; �८�ࠧ������ � ����樮��� ���
           cmp   dx, 0
           jz    ReadNumEnd
           loop  ReadNum   
ReadNumEnd:
           cmp   ax, RandomNum
           jnz   ReadNumbersEnd             ; �᫨ ����� �ࠢ��쭠� ������,
           mov   IsEndFl, 0FFh              ; � ����� 䫠�� ����砭�� ���⠭��
           mov   IsStartTest, 0             ; � ࠧ�襭�� �� ���६��� ����� ���⠭��
           mov   IsIncNumReact, 0FFh
ReadNumbersEnd:
           RET
ReadNumbers ENDP


ReactTest  PROC  NEAR
           cmp   IsStartTest, 0             ; �᫨ ���稪 ॠ�樨 �� ࠧ�襭, � ��室
           jz    ReactTestEnd
           cmp   IsEndFl, 0FFh              ; �᫨ ���⠭�� ����祭�, � ��室
           jz    ReactTestEnd
           cmp   DelayEndFl, 0              ; �᫨ ����প� �� ����祭�, � ��室
           jz    ReactTestEnd
           cmp   ReactTime, 9990h           ; ����஢���� ���ᨬ��쭮�� ���祭�� ॠ�樨 �� 9999h
           jb    ReactTestInc
           mov   ReactTime, 9999h
           jmp   ReactTestEnd   
ReactTestInc:
           call  DelayMS                    ; ����প� 1 �����ᥪ㭤�
           cmp   DelayMSEndFl, 0            ; �᫨ ����প� �� ����祭�, � ��室
           jz    ReactTestEnd
           mov   DelayMSEndFl, 0FFh         ; ����� 䫠�� ����砭�� ����প�
           lea   si, ReactTime
           mov   al, [si]
           add   al, 9; 76
           daa                              ; ���������� � ⥪�饬� �६��� ॠ�樨 � ���४�஢��
           mov   [si], al
           mov   al, [si+1]
           adc   al, 0
           daa
           mov   [si+1], al
ReactTestEnd: 
           RET
ReactTest  ENDP


WriteCurRes PROC NEAR
           cmp   IsIncNumReact, 0FFh        ; �᫨ �� ࠧ�襭 ���६��� ����� ॠ�樨, � ��室
           jnz   WCREnd
           lea   di, ResMassDS
           lea   si, ReactTime
           mov   ah, 0
           mov   ax, NumOfReact3
           mov   bx, ax
           mov   al, NumOfReact
           mov   [di+bx], al                ; ����㧪� � ���� ���� ����� ����� ॠ�樨
           inc   bx
           mov   al, [si+1]
           mov   [di+bx], al                ; ����㧪� �� ��ன ���� ����� ���襣� ���� �६��� ॠ�樨
           inc   bx
           mov   al, [si]
           mov   [di+bx], al                ; ����㧪� � ��⨩ ���� ����� ����襣� ���� �६��� ॠ�樨
           mov   IsSortMass, 0FFh           ; ����� 䫠�� ࠧ�襭�� ����஢���� � ���஢�� ���ᨢ�
WCREnd:           
           RET
WriteCurRes ENDP


CopySortMass PROC NEAR
           cmp   IsSortMass, 0               ; �᫨ 䫠� ࠧ�襭�� ���஢�� �� ��⨢��, � ��室
           jz    CopySortEnd
           
           lea   si, ResMassDS
           lea   di, ResMassSortDS
           mov   ch, 0
           mov   cx, NumOfReact3
           inc   cx
           
CopySort1: mov   al, [si]
           mov   [di], al                   ; ����஢���� ���ᨢ� � ���஢���� ���ᨢ
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
Sorting:                                    ; ����஢�� ���ᨢ� ��⮤�� "���४"
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
           loop  Sorting                    ; ����砭�� ���஢�� ���ᨢ�  
CopySortEnd:
           RET
CopySortMass ENDP

           
DispMode   PROC  NEAR
           mov   al, NumOfMode              ; �뢮� 㭨�୮�� ���� �� ��������� ०����
           out   ModeSlctPort, al    
           RET
DispMode   ENDP


DispMassResults PROC NEAR  
           cmp   NumOfMode, 1               ; �᫨ ०�� ���⠭��, � ��室
           jz    DNOREnd
           mov   ah, 20h                    ; ��砫�� �������� �롨ࠥ� 6
           mov   bh, 0
           mov   cx, 6                      ; ���稪 横�� �� ������⢮ �������஢

           lea   si, ErrorImageDS           ; ����㧪� ���ᨢ� ������樨 �訡��
           cmp   ErrorFlag, 0FFh            ; �᫨ �訡��, � ���室 � �뢮�� ���ᨢ� �訡��
           jz    Error1
           
           mov   di, NumOfRes               ; ����㧪� ᬥ饭�� ���� ��࠭���� १����
           lea   si, ResMassSortDS
           cmp   NumOfMode, 4               ; �᫨ ०�� = 4, ����㧪� ���஢������ ���ᨢ�
           jz    SortedMass                 ; �᫨ ०�� = 2, ����㧪� ���筮�� ���ᨢ�
           lea   si, ResMassDS
SortedMass:
           mov   NextByteFl, 0              
DNOR1:     mov   al, ah
           not   al
           out   IndSlctPort, al
           mov   bx, di
           mov   al, [si+bx]                ; ����㧪� ��।���� ����
           cmp   NextByteFl, 0
           jz    DNOR2
           inc   di                         ; ����䨪��� ����
           and   al, 0Fh                    ; �뤥����� ����襩 ��ࠤ�  
           jmp   DNOR3
DNOR2:     shr   al, 4                      ; �뤥����� ���襩 ��ࠤ�
DNOR3:     lea   bx, TablDS                 ; ����㧪� ⠡���� �८�ࠧ������
           xlat                             ; �८�ࠧ������ ���� � ���
           out   DigOutPort, al             ; �뢮� ���� ����
           mov   al, 0FFh
           out   IndSlctPort, al            ; �몫�祭�� ��������
           not   al
           out   DigOutPort, al    
           shr   ah, 1                      ; ����� �� ᫥���騩 ��������
           not   NextByteFl                 ; ������஢���� 䫠�� �롮� ��ࠤ�
           loop  DNOR1
           jmp   DNOREnd
Error1:    mov   al, ah                     ; �뢮� ������樨 �� �訡��
           not   al                         ; �� ��������� 4, 3, 2
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
           cmp   DelayEndFl, 0FFh           ; �᫨ ����প� 㦥 ��諠, � ��室
           jz    DelayEndM
           sub   TimeStartDS, 1             ; ���६��� �� �६��� �������� ᥪ㭤�
           mov   DelayEndFl, 0
           jnz   DelayEndM                  ; �᫨ �� ࠢ�� ���, � ��室
           mov   DelayEndFl, 0FFh           ; ����� 䫠��� ����砭�� � ��砫� ���稪� ॠ�樨
           mov   IsStartTest, 0FFh
           mov   TimeStartDS, TimeStart     ; ����⠭������� �६��� �������� ᥪ㭤�
DelayEndM: 
           RET
DelaySec   ENDP   
           

DispReactTest PROC  NEAR
           cmp   NumOfMode, 1
           jnz   DRTEnd
           call  DelaySec                   ; ����প� 1 ᥪ㭤� ��। �뢮��� ��砩���� �᫠          
           mov   ah, 20h                    ; ��砫�� �������� �롨ࠥ� 6
           mov   al, 0
           mov   bh, 0
           mov   dl, NumOfReact             ; ����㧪� �⮡ࠦ���� ����� ॠ�樨
           add   al, dl
           daa
           mov   dl, al
           mov   NextByteFl, 0
           mov   cx, 6                      ; ���稪 横�� �� ������⢮ �������஢
           lea   si, StartImageDS           ; ����㧪� ���ᨢ� �⮡ࠦ���� ��砫� ���⠭��
           cmp   DelayEndFl, 0              ; �᫨ ����প� �� ����稫���, � ���室 � �뢮��
           jz    DRT1
           lea   si, ErrorImageDS           ; ����㧪� ���ᨢ� �⮡ࠦ���� �訡��
           cmp   ErrorFlag, 0FFh            ; �᫨ �訡�� ����, � � ���室 � �뢮��
           jz    DRT1
           cmp   IsStartFl, 0FFh            ; �᫨ ���⠭�� ��砫���, � ���室 � �뢮�� ��砩����
           jz    DispRandDig   
           lea   si, ReadyImageDS           ; ����㧪� ���ᨢ� �⮡ࠦ���� ��⮢����
DRT1:      mov   al, ah
           not   al
           out   IndSlctPort, al            ; �롮� ��������
           cmp   ErrorFlag, 0
           jz    NumReactM1                 ; �᫨ �訡�� ���, � �뢮� ����� ॠ�樨
           cmp   cx, 4
           ja    NextDig1
NumReactM1:
           cmp   cx, 5
           jb    ReadyIm
           mov   al, dl 
           cmp   NextByteFl, 0              ; �஢�ઠ �롮� ��ࠤ�
           jz    DRT2
           and   al, 0Fh                    ; �뤥����� ����襩 ��ࠤ�
           jmp   NumReactM    
DRT2:      shr   al, 4                      ; �뤥����� ���襩 ��ࠤ�
           jmp   NumReactM      
ReadyIm:   mov   al, [si]
           inc   si
           jmp   ReadyIm2                   ; �뢮� ���ᨢ� �⮡ࠦ���� ��砫�, ��⮢���� ��� �訡��    
NumReactM: lea   bx, TablDS                 ; ����㧪� ⠡���� �८�ࠧ������
           xlat                             ; �८�ࠧ������ ��� � ����
ReadyIm2:  out   DigOutPort, al             ; �뢮� ���� ᨬ����
           mov   al, 0FFh
           out   IndSlctPort, al            ; �몫�祭�� ��������
           not   al
           out   DigOutPort, al    
NextDig1:  shr   ah, 1                      ; ����� ��� �� ᫥���騩 ��������
           not   NextByteFl                 ; ������ࢠ��� �롮� �뤥����� ��ࠤ�
           cmp   cx, 2
           jz    DRTEnd
           loop  DRT1
           jmp   DRTEnd        
DispRandDig:     
           lea   si, RandomNum+1            ; ����㧪� ��砩���� �᫠
           cmp   IsEndFl, 0          
           jz    DRT4                
           lea   si, ReactTime+1            ; �᫨ ���⠭�� �����稫���, � ����㧪� �६��� ॠ�樨              
DRT4:      mov   al, ah
           not   al
           out   IndSlctPort, al            ; �롮� ��������
           cmp   cx, 4
           ja    DRT5
RandomNum1: 
           mov   dl, [si]                   ; ����㧪� ���� ��砩���� �᫠ ��� �६��� ॠ�樨
           cmp   NextByteFl, 0
           jz    DRT5
           dec   si                         ; ����䨪��� ����
DRT5:      mov   al, dl                     ; ����㧪� ����� ���⠭��, � ��⮬ ��砩���� ��� ॠ�樨
           cmp   NextByteFl, 0
           jz    DRT6
           and   al, 0Fh                    ; �뤥����� ����襩 ��ࠤ�
           jmp   DRT7 
DRT6:      shr   al, 4                      ; �뤥����� ���襩 ��ࠤ�               
DRT7:      lea   bx, TablDS                 ; ����㧪� ⠡���� �८�ࠧ������
           xlat                             ; �८�ࠧ������ ��� � ����
           out   DigOutPort, al             ; �뢮� ���� ᨬ����
           mov   al, 0FFh
           out   IndSlctPort, al            ; �몫�祭�� ��������
           not   al
           out   DigOutPort, al    
           shr   ah, 1                      ; ����� ��� �� ᫥���騩 ��������
           not   NextByteFl                 ; ������ࢠ��� �롮� �뤥����� ��ࠤ�
           loop  DRT4     
DRTEnd:    
           RET
DispReactTest ENDP 
    
           
Start:
           mov   ax, Data                   ; ���⥬��� �����⮢��
           mov   ds, ax
           mov   es, ax
           mov   ax, Stk
           mov   ss, ax
           lea   sp, StkTop
           call  Init                       ; �㭪樮���쭠� �����⮢��
MainLoop:  call  ReadButtons                ; ���뢠��� ������
           call  ErrorCheck                 ; �஢�ઠ �� �訡�� �����
           call  StartControl               ; ��ࠡ�⪠ ������ ����
           call  ModeControl                ; ��ࠡ�⪠ ������ ०��
           call  ResultsControl             ; ��ࠡ�⪠ ������ ��ᬮ�� १���⮢
           call  InitRandom                 ; ��砫쭠� ������� ��砩���� �᫠ � �६���
           call  GenerateRand               ; ������� ��砩���� �᫠ � �६���
           call  ReadNumbers                ; ��ࠡ�⪠ ������ � ����஬
           call  ReactTest                  ; ����� �६��� ॠ�樨
           call  WriteCurRes                ; ���࠭���� ⥪�饣� १����
           call  CopySortMass               ; ����஢���� � ���஢�� ���ᨢ�
           call  DispMode                   ; �뢮� ०��� �� ���������
           call  DispMassResults            ; �뢮� १���� �� ��ᯫ��
           call  DispReactTest              ; �뢮� ���⠭�� �� ��ᯫ��
           jmp   MainLoop       

           org   RomSize-16-((InitDataEnd-InitDataStart+15) AND 0FFF0h)
           ASSUME cs:NOTHING
           jmp   Far Ptr Start
Code       ENDS
END		Start
