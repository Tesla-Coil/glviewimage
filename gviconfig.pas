{
  Copyright 2009-2011 Michalis Kamburelis.

  This file is part of "glViewImage".

  "glViewImage" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "glViewImage" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "glViewImage"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  ----------------------------------------------------------------------------
}

{ User config file. }
unit GVIConfig;

interface

uses KambiUtils, KambiXMLConfig;

var
  { User config file.
    Will be created (and FileName set) in initialization,
    will be flushed and freed in finalization. }
  ConfigFile: TCastleConfig;

implementation

uses SysUtils, KambiFilesUtils;

{ initialization / finalization --------------------------------------------- }

{ Commented out (unused) for now:
  Note that this unit initializes OnGetApplicationName in initialization. }
(*
function MyGetApplicationName: string;
begin
  Result := 'glviewimage';
end;
*)

initialization
(*
  { This is needed because
    - I sometimes display ApplicationName for user, and under Windows
      ParamStr(0) is ugly uppercased.
    - ParamStr(0) is unsure for Unixes.
    - ParamStr(0) is useless for upx executables. }
  OnGetApplicationName := @MyGetApplicationName;
*)
  ConfigFile := TCastleConfig.Create(nil);
  ConfigFile.FileName := UserConfigFile('.conf');
finalization
  if ConfigFile <> nil then
  begin
    ConfigFile.Flush;
    FreeAndNil(ConfigFile);
  end;
end.
