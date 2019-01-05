program TEST;

uses Crt, Classes, SysUtils, FileUtil, HTTPDefs, fpHTTP, fpWeb, fphttpclient, fpjson, jsonparser;

Var
  S, Key: String;
  HTTP: TFPHTTPClient;
  AuthOK: boolean;
  func: char;
  teamID, teamSTRATEGY,i: integer;

procedure AuthenticationCheck();
begin
   AuthOK := true;
   HTTP := TFPHttpClient.Create(Nil);
   try
     HTTP.AddHeader('Authentication', Key);
     S := HTTP.Get('https://game-mock.herokuapp.com/games/bgi63c/teams/1');
   except
   AuthOK := false;
   end;
   HTTP.Free
end;

procedure ChangeTeamStrategy();
begin
     Read(teamID);
     Read(teamSTRATEGY);
     HTTP := TFPHttpClient.Create(Nil);
     try
     HTTP.AddHeader('Authentication', Key);
     HTTP.AddHeader('Content-Type', 'application/json');
     HTTP.RequestBody:=TStringStream.Create('{'+
     '"team":{ "id": ' + IntToStr(teamID) + '},"position": ' + IntToStr(teamSTRATEGY) +
     '}');
     S := HTTP.Put('http://localhost:3000/change-strategy');
     finally
     HTTP.Free;
     end;
     Writeln('Team ' + (GetJSON(S).FindPath('teamID').AsString));
     Writeln('Strategy ' + (GetJSON(S).FindPath('teamSTRATEGY').AsString));
end;

procedure RevertTeamStrategy();
begin
          Read(teamID);
          HTTP := TFPHttpClient.Create(Nil);
          try
          HTTP.AddHeader('Authentication', Key);
          HTTP.AddHeader('Content-Type', 'application/json');
          HTTP.RequestBody:=TStringStream.Create('{'+
          '"team":{ "id": ' + IntToStr(teamID) + '}'+
          '}');
          S := HTTP.Put('http://localhost:3000/revert-change');
          finally
          HTTP.Free;
          end;
          Writeln('Team ' + (GetJSON(S).FindPath('teamID').AsString));
          Writeln('Strategy ' + (GetJSON(S).FindPath('teamSTRATEGY').AsString));
     end;

Procedure GetInfo();
     begin
          Read(teamID);
          HTTP := TFPHttpClient.Create(Nil);
          try
          HTTP.AddHeader('Authentication', Key);
          S := HTTP.Get('https://game-mock.herokuapp.com/games/bgi63c/teams/'+IntToStr(teamID));
          finally
          HTTP.Free;
          end;
        //Writeln(S);
          Writeln('Team ' + (GetJSON(S).FindPath('id').AsString));
          Writeln('Strategy ' + (GetJSON(S).FindPath('possibleMoves[0].id').AsString));
     end;

begin
while not AuthOK do
begin
Writeln('Enter key:');
Read(Key);
try
AuthenticationCheck();
except
Writeln('Error');
end;
end;
ClrScr;
Writeln('Success');

While true do
begin
Read(func);
//write (IntToStr(ord(func)));
if (Upcase(func)='I') or (Upcase(func)='R') or (Upcase(func)='S') or (Upcase(func)='E') then
begin
     if Upcase(func)='S' then ChangeTeamStrategy();

     if Upcase(func)='R' then RevertTeamStrategy();

     if Upcase(func)='I' then GetInfo();

     if Upcase(func)='E' then
     begin
       for i:=1 to 4 do
       begin
       Read(func);
       if (i=1) and (Upcase(func)<>'X') then
          begin Writeln('Unknown function');break; end;
       if (i=2) and (Upcase(func)<>'I') then
          begin Writeln('Unknown function');break; end;
       if (i=3) and (Upcase(func)<>'T') then
          begin Writeln('Unknown function');break; end;
       if i=4 then exit;
       end;
     end;
end

else if (ord(func)<>10) and (ord(func)<>13) then Writeln('Unknown function');
end;
Readln;Readln;
end.

