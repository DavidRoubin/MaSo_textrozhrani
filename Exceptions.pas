program Exceptions;

uses Crt, Classes, SysUtils, HTTPDefs, fpHTTP, fpWeb, fphttpclient, fpjson, jsonparser, httpprotocol;

Var
  S, Key: String;
  HTTP: TFPHTTPClient;
  AuthOK: boolean;
  func: integer;


procedure AuthenticationCheck();
begin
 //  HTTPError
   AuthOK := true;
   HTTP := TFPHttpClient.Create(Nil);
   try
      try
         HTTP.AddHeader('Authentication', Key);
         S := HTTP.Get('https://game-mock.herokuapp.com/games/bgi63c/teams/'+IntToStr(func));
      except
         on E : EHTTPClient do
         begin
            AuthOK := false;
            WriteLn(S);
            WriteLn(E.Message);
         end;
         on E : Exception do
         begin
            AuthOK := false;
            WriteLn(S);
            WriteLn(E.Message);
         end;
      end;
   finally
      HTTP.Free;
      if not AuthOK then
      begin
         Read(func);
         AuthenticationCheck();
      end;
   end;
end;

begin
  Read(func);

  AuthenticationCheck();

  WriteLn(S);

  Read(func);
  WriteLn(IntToStr(func));

  Readln; Readln;
end.

