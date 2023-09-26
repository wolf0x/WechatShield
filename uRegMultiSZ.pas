unit uRegMultiSZ;

interface

uses
Windows, SysUtils, Classes, Registry;

type
  {$IF CompilerVersion >=22}
  TChars = System.TArray<Char>;
  {$ELSE}
  TChars = array of Char;
  TBytes = array of Byte;
  {$IFEND}

  TRegistryMultiSZ = class(TRegistry)
  Public
    function WriteMultiSZ(Const ValueName: string; TS: TStrings): Boolean;
  end;

implementation

Function TRegistryMultiSZ.WriteMultiSZ(const ValueName: string; TS: TStrings): Boolean;
var
  I, Error: Integer;
  aLine: string;
begin
  aLine := '';
  for I := 0 to TS.Count - 1 do
  begin
    aLine := aLine+TS[I] + #0;
  end;
  aLine := aLine + #0;
  Error := RegSetValueEx(CurrentKey, PChar(ValueName), 0, REG_MULTI_SZ, PChar(aLine), Length(aLine)*Sizeof(Char));
  Result := Error = ERROR_SUCCESS;
  if not Result then
    Windows.OutputDebugString(PChar(Format('WriteMultiSZ.error=%d, %s', [Error, SysUtils.SysErrorMessage(Error)])));
  end;

end.
