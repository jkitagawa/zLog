unit UzLogExtension;

{ zLogから外部のプログラムを呼び出すための切り口＜案＞ }
{ このファイル丸ごとカスタマイズすれば良い }
{ exampleは一般的なDLL呼び出しのサンプル }

{
  別件でUExceptionDialog.pasでの設定
  「プロジェクト」－「JCL Debug expert」－「Generate .jdbg files」－「Enabled for this project」を選択
  「プロジェクト」－「JCL Debug expert」－「Insert JDBG data into the binary」－「Enabled for this project」を選択
}

interface

uses
  Windows, SysUtils, Classes, Forms, UzLogQSO;

type
  TzLogEvent = ( evAddQSO = 0, evModifyQSO, evDeleteQSO );

// zLog本体から呼び出される処理
procedure zLogInitialize();
procedure zLogContestInit(strContestName: string);
procedure zLogContestEvent(event: TzLogEvent; aQSO: TQSO);
procedure zLogContestTerm();
procedure zLogTerminate();

implementation

var
  zLogContestInitialized: Boolean;  // コンテスト初期化完了フラグ

// example
// extension.dll内の↓の関数を呼び出す例 文字列はSHIFT-JIS
// void _stdcall zLogExtensionProcName(int event, LPCSTR pszCallsign, QSODATA *pqsorec);

(*
typedf struct _QSODATA {
  double Time;
  char CallSign[13];
  char NrSent[31];
  char NrRcvd[31];
  WORD RSTSent;
  WORD RSTRcvd;
  int  Serial;
  BYTE Mode;
  BYTE Band;
  BYTE Power;
  char Multi1[31];
  char Multi2[31];
  BOOL NewMulti1;
  BOOL NewMulti2;
  BYTE Points:
  char Operator[15];
  char Memo[65];
  BOOL CQ;
  BOOL Dupe
  BYTE Reserve;
  BYTE TX;
  int  Power2;
  int  Reserve2;
  int  Reserve3;
} QSODATA;
*)

type
  PTQSOData = ^TQSOData;
  TExtensionProc = procedure(event: Integer; pszCallsign: PAnsiChar; pqsorec: PTQSOData); stdcall;

var
  hExtensionDLL: THandle;
  pfnExtensionProc: TExtensionProc;

// zLogの起動
procedure zLogInitialize();
var
   strExtensionDLL: string;
begin
   {$IFDEF DEBUG}
   OutputDebugString(PChar('zLogInitialize()'));
   {$ENDIF}

   // example
   strExtensionDLL := ExtractFilePath(Application.ExeName) + 'zlog_extension.dll';
   if FileExists(strExtensionDLL) = False then begin
      Exit;
   end;

   hExtensionDLL := LoadLibrary(PChar(strExtensionDLL));
   if hExtensionDLL = 0 then begin
      Exit;
   end;

   @pfnExtensionProc := GetProcAddress(hExtensionDLL, LPCSTR('zLogExtensionProcName'));
end;

// コンテストの初期化完了
procedure zLogContestInit(strContestName: string);
begin
   {$IFDEF DEBUG}
   OutputDebugString(PChar('zLogContestInit(''' + strContestName + ''')'));
   {$ENDIF}
   zLogContestInitialized := True;
end;

// 交信データの追加、変更、削除
procedure zLogContestEvent(event: TzLogEvent; aQSO: TQSO);
var
   qsorec: TQSOData;
begin
   if zLogContestInitialized = False then begin
      Exit;
   end;

   {$IFDEF DEBUG}
   OutputDebugString(PChar('zLogEventProc(' + IntToStr(Integer(event)) + ',''' + aQSO.Callsign + ''')'));
   {$ENDIF}

   // example
   if Assigned(pfnExtensionProc) then begin
      qsorec := aQSO.FileRecord;
      pfnExtensionProc(Integer(event), PAnsiChar(AnsiString(aQSO.Callsign)), @qsorec);
   end;
end;

// コンテストの終了
procedure zLogContestTerm();
begin
   {$IFDEF DEBUG}
   OutputDebugString(PChar('zLogContestTerm()'));
   {$ENDIF}
   zLogContestInitialized := False;
end;

// zLogの終了
procedure zLogTerminate();
begin
   {$IFDEF DEBUG}
   OutputDebugString(PChar('zLogTerminate()'));
   {$ENDIF}

   // example
   if hExtensionDLL <> 0 then begin
      FreeLibrary(hExtensionDLL);
   end;
end;

initialization
  zLogContestInitialized := False;

  // example
  hExtensionDLL := 0;
  pfnExtensionProc := nil;

finalization

end.
