program WeChatShield;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  ShellAPI, Windows, SysUtils, Shlobj, Registry, ActiveX, Classes, System.Types,
  IOUtils,
  uRegMultiSZ in 'uRegMultiSZ.pas';

const
  RestrictedDirectory: array[0..7] of string = (
    '%localAppData%\Temp\Rar*\',
    '%localAppData%\Temp\*.zip\',
    '%localAppData%\Temp\7z*\',
    '%localAppData%\Temp\wz*\',
    '%localAppData%\Temp\360zip*\*\',
    '%localAppData%\Temp\HZ*\',
    '%localAppData%\Temp\KuaiZip\*\',
    '%localAppData%\Temp\k52*\'
  );

  ExecutableTypes: array[0..10] of string = (
    'BAT', 'CMD', 'COM', 'CPL', 'EXE', 'HTA', 'LNK', 'MSI', 'PIF', 'SCR', 'CHM'
  );

var
  F1: Bool;
  ExecStrings: TStringList;

Function IsUserAnAdmin(): BOOL; external shell32;

Function GetAppDataPath(const variableName: string): string;
var
  AppDataPath: array[0..MAX_PATH] of Char;
begin
  // Get the value of the %APPDATA% environment variable
  if GetEnvironmentVariable(PChar(variableName), AppDataPath, SizeOf(AppDataPath)) > 0 then
    Result := IncludeTrailingPathDelimiter(AppDataPath)
  else
    Result := '';
end;

Function ReadWeChatFilePath: string;
var
  IniContent: TStringList;
  FileName: string;
  WechatPath: string;
  UserProfiles: TStringDynArray;
  UserProfile: string;
  WechatConfig: string;
begin
  Result := 'Nil';
  try
    UserProfiles := TDirectory.GetDirectories('C:\Users');
    for UserProfile in UserProfiles do
    begin
      if (UserProfile <> 'C:\Users\All Users') AND (UserProfile <> 'C:\Users\Default User') AND (UserProfile <> 'C:\Users\Public') AND (UserProfile <> 'C:\Users\Default') then
        begin
        //AppData\Roaming\Tencent\WeChat\All Users\config
          FileName := UserProfile + '\AppData\Roaming\Tencent\WeChat\All Users\config\3ebffe94.ini';
          //Writeln('User Profile Folder: ' + UserProfile);
          if FileExists(FileName) then
          begin
            IniContent := TStringList.Create;
            try
            // Load the full content of the INI file into the TStringList
              IniContent.LoadFromFile(FileName,TEncoding.UTF8);
              WechatConfig := StringReplace(IniContent.Text, sLineBreak, '', [rfReplaceAll]);
              If WechatConfig = 'MyDocument:' then
                WechatPath :=  UserProfile + '\Documents\WeChat Files\'
              else
                WechatPath := IncludeTrailingPathDelimiter(WechatConfig) + 'WeChat Files\';
              ExecStrings.Add(WechatPath);
              Writeln('WeChat Folder: ' + WechatPath);
              Result := 'Located';
            finally
              IniContent.Free; // Free the TStringList object to release resources
            end;
          end
        end;
      end;
        //Writeln('User Profile Folder: ' + UserProfile);
  except
    on E: Exception do
      Writeln('An error occurred: ', E.Message);
  end;
end;

procedure AddValueToRegistry();
const
  cKey = 'SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers';
var
  Registry: TRegistryMultiSZ;
  MyList: TStrings;
  I: Integer;
begin
  Registry := TRegistryMultiSZ.Create;
  Registry.RootKey := HKEY_LOCAL_MACHINE;
  Registry.OpenKey(cKey, false);
  try
    MyList := TStringList.Create();
    for I:=Low(ExecutableTypes) to High(ExecutableTypes) do
      MyList.Add(ExecutableTypes[I]);
    Registry.WriteMultiSz('ExecutableTypes', MyList);
  finally
    MyList.Free;
  end;
  Registry.Free;
end;

procedure CreateSaferRegistryKeys;
var
  Reg: TRegistry;
  PathGUID: TGUID;
  I: Integer;
//  ExecStrings: TStringList;
  WeChat: String;
  WxWork: String;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;

    // Delete the existing "safer" key if it exists
    Reg.DeleteKey('SOFTWARE\Policies\Microsoft\Windows\safer');

    // Create new "safer" key and its subkeys
    if Reg.OpenKey('SOFTWARE\Policies\Microsoft\Windows\safer', True) then
    begin
      Reg.OpenKey('codeidentifiers', True);
            // Set the properties of "codeidentifiers"
      Reg.WriteInteger('authenticodeenabled', 0);
      Reg.WriteInteger('DefaultLevel', 262144);
      Reg.WriteInteger('TransparentEnabled', 1);
      Reg.WriteInteger('PolicyScope', 0);

      Reg.OpenKey('0', True);
      Reg.OpenKey('Paths', True);

      ExecStrings := TStringList.Create;
      try
        for I := 0 to Length(RestrictedDirectory) - 1 do
        begin
          ExecStrings.Add(RestrictedDirectory[I]);
        end;

        WeChat:=ReadWeChatFilePath();
        If WeChat <> 'Nil' then F1 := True;

        for I := 0 to ExecStrings.Count - 1 do
        begin
          if Reg.OpenKey('\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\0\Paths', True) then
          begin
            CreateGUID(PathGUID); // Use CreateGUID instead of CoCreateGUID
            Reg.OpenKey(GUIDToString(PathGUID), True);
            Reg.WriteInteger('SaferFlags', 0);
            Reg.WriteExpandString('ItemData', ExecStrings[I]);
          end;
        end;
      finally
        ExecStrings.Free;
      end;
      AddValueToRegistry();
      //Writeln('���������ã�ͨ�������������Ч��δ��Ч���������ԣ�')
    end;
  finally
    Reg.Free;
  end;
end;

procedure StartFunction;
begin
  CreateSaferRegistryKeys();

  if F1 then
    Writeln('΢�ŵ��԰���������ã�ͨ�������������Ч��δ��Ч���������ԣ�')
  else
    Writeln('δʶ��΢�ŵ��԰��ļ��洢·����΢���������δ���ã�δ��Ч���������ԣ�')
  // Implement your start logic here
end;

procedure StopFunction;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    // Delete the existing "safer" key if it exists
    Reg.DeleteKey('SOFTWARE\Policies\Microsoft\Windows\safer');
    Reg.DeleteKey('SYSTEM\CurrentControlSet\Control\Srp\Gp');
  finally
    Reg.Free;
  end;
  Writeln('������ͣ�ã�ͨ�������������Ч��δ��Ч���������ԣ�');
  // Implement your stop logic here
end;

procedure ShowHelp;
begin
  Writeln('ʹ�÷���:');
  Writeln('  ConsoleApp.exe start  // ����΢�ű�����');
  Writeln('  ConsoleApp.exe stop   // �ر�΢�ű�����');
end;

begin
  try
    if IsUserAnAdmin() then
    begin
      if ParamCount = 1 then
      begin
        if SameText(ParamStr(1), 'start') then
          StartFunction
        else if SameText(ParamStr(1), 'stop') then
          StopFunction
        else
          ShowHelp;
      end
      else
        ShowHelp;
    end
    else
      Writeln('��ʾ��δ�������ԱȨ�ޣ��޷����У�');
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
end.

