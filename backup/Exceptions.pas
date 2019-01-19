program Exceptions;

{$codepage utf8}

uses
  Crt,
  Classes,
  SysUtils,
  HTTPDefs,
  fpHTTP,
  fpWeb,
  fphttpclient,
  fpjson,
  jsonparser,
  httpprotocol;

type
  TResponse = record
    StatusCode: integer;
    Body: TJSONData;
  end;

var
  GameCode, OrgKey: string;
  Teams: TJSONArray;
  Team: TJSONData;
  IsAuthenticated: boolean;
  i: integer;
  TeamTable: array of integer;

  function QueryAPI(Method, Path: string; State: integer): TResponse;

  var
    HTTP: TFPHTTPClient;
    SS: TStringStream;

  begin
    try
      try
        HTTP := TFPHttpClient.Create(nil);
        SS := TStringStream.Create('');

        HTTP.AddHeader('Authorization', 'JWT ' + OrgKey);
        HTTP.AddHeader('Content-Type', 'application/json');
        if State <> 0 then
        HTTP.RequestBody:=TStringStream.Create('{"state":' + IntToStr(State)+ '}');

        HTTP.HTTPMethod(Method, 'https://game-mock.herokuapp.com/games/' +
          GameCode + Path, SS, [200, 201, 400, 401, 404, 500, 505]);

        //HTTP.RequestHeaders[3]

        Result.StatusCode := HTTP.ResponseStatusCode;
        Result.Body := GetJSON(SS.Datastring);
      except
        on E: Exception do
          WriteLn(E.Message);
      end;
    finally
      SS.Free;
      HTTP.Free;
    end;
  end;

  function AuthenticationCheck(): boolean;

  var
    Response: TResponse;

  begin
    Write('Enter gamecode: ');
    Readln(GameCode);
    GameCode := 'bgi63c';

    Write('Enter organizer key: ');
    Readln(OrgKey);
    OrgKey := 'bti34tbri8t34rtdbiq34tvdri6qb3t4vrdtiu4qv';

    Response := QueryAPI('GET', '/teams', 0);
    case Response.StatusCode of
      200:
      begin
        WriteLn('Success');
        Teams := TJSONArray(Response.Body);
        Result := True;
      end;
      400:
      begin
        WriteLn('Zadána špatná strategie');
        //unallowed status - strategie kterou tým nemůže
        Result := False;
      end;
      401:
      begin
        WriteLn('Špatný klíč organizátora');
        //UNAUTHORIZED
        Result := False;
      end;
      404:
      begin
        WriteLn('Špatné číslo týmu/ špatný kód hry');
        //šppatná adresa in general
        Result := False;
      end;
      500:
      begin
        WriteLn('Chyba serveru - pracujeme na opravení');
        //internal server error
        Result := False;
      end;
    end;

  end;

  procedure PrintMoves(Moves: TJSONData);
  var
    Move: TJSONData;
  begin
    WriteLn('Možné pohyby:');
    for i := 0 to Moves.Count - 1 do
    begin
      Move := Moves.FindPath('[' + i.ToString() + ']');
      WriteLn('    ' + IntToStr(Move.FindPath('id').AsQWord) + ') ' + Move.FindPath('name').AsString);
    end;

  end;

  procedure PrintTeam(Team: TJSONData);
  var
    Number, StateRecord, Name: string;
  begin
    Number := IntToStr(Team.FindPath('number').AsQWord);
    Name := Team.FindPath('name').AsString;
//    StateRecord := Team.FindPath('stateRecord').AsString;
    WriteLn(Number + '. ' + Name);
//    WriteLn(StateRecord);
    PrintMoves(Team.FindPath('possibleMoves'));
  end;

  procedure ReverseMove(Team: TJSONData);
  var
    Number: string;
    Response: TResponse;
  begin
    Number := Team.FindPath('number').AsString;
    Response := QueryAPI('DELETE', '/teams/' + Number + '/state', 0);
    if Response.StatusCode <> 200 then
      WriteLn('POZOR!: Vrácení pohybu se nezdařilo.')
    else
      PrintTeam(Response.Body);
  end;

  procedure CheckMoveId(Team: TJSONData; MoveId: integer);
  var
    Moves : TJSONData;
    Possible : boolean;
  begin
    Possible := false;
    Moves := Team.FindPath('possibleMoves');
    for i := 0 to Moves.Count - 1 do
    begin
      if Moves.FindPath('[' + i.ToString() + '].id').AsInteger = MoveId then
        Possible := true;
    end;
    if not Possible then
      Raise EConvertError.Create ('POZOR!: Neplatné číslo pohybu');
  end;

  procedure MoveTeam(Team: TJSONData; Move: string);
  var
    Number: string;
    Response: TResponse;
    MoveId: integer;
  begin
    Number := Team.FindPath('id').AsString;
    try
      MoveId := StrToInt(Move);
      CheckMoveId(Team, MoveId);
      Response := QueryAPI('POST', '/teams/' + Number + '/state', MoveId);
      if Response.StatusCode <> 201 then
        WriteLn('POZOR!: Zadání pohybu se nezdařilo.')
      else
        PrintTeam(Response.Body);
    except
      on E: EConvertError do
        Writeln('POZOR!: Neplatné číslo pohybu');
    end;

  end;

  function TeamNumberTranslate(TeamNumber: integer): integer;
  begin
    Result := -1;
    for i := 0 to Length(TeamTable) do
    begin
      if TeamTable[i] = TeamNumber then
      begin
        Result := i + 1;
        Exit();
      end;
    end;
  end;

  procedure ManageMoveInput(Team: TJSONData);
  var
    MoveInput: string;
  begin
    while True do
    begin
      ReadLn();
      Write('Zadej číslo pohybu: ');
      ReadLn(MoveInput);
      MoveInput := Upcase(Trim(MoveInput));
      case MoveInput of
        '':
          Exit;
        'R':
          ReverseMove(Team);
        else
          MoveTeam(Team, MoveInput);
      end;
    end;
  end;

  procedure ManageInput(Teams: TJSONArray);
  var
    TeamNumber: integer;
    TeamResponse: TResponse;
    MoveInput: string;
  begin
    while True do
    begin

      Write('Zadej číslo týmu: ');
      Read(TeamNumber);

      TeamResponse := QueryAPI('GET', '/teams/' + IntToStr(TeamNumberTranslate(TeamNumber)), 0);
      if TeamResponse.StatusCode <> 200 then
      begin
        WriteLn('Neznámý tým');
        Continue;
      end;
      PrintTeam(TeamResponse.Body);
      ManageMoveInput(TeamResponse.Body);
    end;
  end;

begin
  IsAuthenticated := False;
  while not IsAuthenticated do
    IsAuthenticated := AuthenticationCheck();

  SetLength(TeamTable, Teams.Count);

  for i := 0 to Teams.Count - 1 do
  begin
    Team := Teams.FindPath('[' + i.ToString() + ']');
    WriteLn(Team.FindPath('id').AsString + ' = ' + Team.FindPath('number').AsString);
    TeamTable[i] := Team.FindPath('number').AsInteger;
  end;

  ManageInput(Teams);

 // Writeln(IntToStr(TeamNumberTranslate(TeamNumber)));

 // WriteLn(QueryAPI('GET', '/teams/' + IntToStr(TeamNumberTranslate(TeamNumber))).Body.FindPath('name').AsString);

  Readln;
  Readln;
end.


 {S := HTTP.ResponseHeaders[3];
         Delete(S,1,14);
         if Pos('application/json',S)=1 then
            begin
               GetJSON(Result).FindPath('type').AsString
            end;

            }
