unit UnitGR;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type
  TProduction = record
    LeftSide: Char;
    Terminal: Char;   // #0 means epsilon production
    NextState: Char;  // #0 means terminal-only or epsilon
  end;

  TSearchNode = record
    State: Char;
    Position: Integer;
    Trace: string;
  end;

  TFormGR = class(TForm)
    BtnTest: TButton;
    EdWord: TEdit;
    LblGrammar: TLabel;
    LblOutputTitle: TLabel;
    LblResult: TLabel;
    LblWord: TLabel;
    MemoGrammar: TMemo;
    MemoTrace: TMemo;
    procedure BtnTestClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FProductions: array of TProduction;
    FStartSymbol: Char;
    procedure AddProduction(ALeft, ATerminal, ANext: Char);
    procedure ParseGrammar;
    function Recognize(const AWord: string; out ATrace: string): Boolean;
  public
  end;

var
  FormGR: TFormGR;

implementation

{$R *.lfm}

procedure TFormGR.AddProduction(ALeft, ATerminal, ANext: Char);
var
  N: Integer;
begin
  N := Length(FProductions);
  SetLength(FProductions, N + 1);
  FProductions[N].LeftSide := ALeft;
  FProductions[N].Terminal := ATerminal;
  FProductions[N].NextState := ANext;
end;

procedure TFormGR.ParseGrammar;
var
  I, J, K, P: Integer;
  Line, LeftText, RightText, Alternative: string;
  Symbols: string;
begin
  SetLength(FProductions, 0);
  FStartSymbol := #0;
  Symbols := '';
  for I := 0 to MemoGrammar.Lines.Count - 1 do
  begin
    Line := Trim(MemoGrammar.Lines[I]);
    if (Line = '') or (Copy(Line, 1, 1) = '#') then Continue;
    P := Pos('->', Line);
    if P = 0 then
      raise Exception.CreateFmt('Linha %d: use -> para separar a produção.', [I + 1]);
    LeftText := Trim(Copy(Line, 1, P - 1));
    RightText := Trim(Copy(Line, P + 2, MaxInt));
    if (Length(LeftText) <> 1) or not (LeftText[1] in ['A'..'Z']) then
      raise Exception.CreateFmt('Linha %d: o lado esquerdo deve ser uma letra maiúscula.', [I + 1]);
    if RightText = '' then
      raise Exception.CreateFmt('Linha %d: produção sem alternativas.', [I + 1]);
    if FStartSymbol = #0 then FStartSymbol := LeftText[1];
    if Pos(LeftText[1], Symbols) = 0 then Symbols := Symbols + LeftText[1];

    while RightText <> '' do
    begin
      J := Pos('|', RightText);
      if J = 0 then
      begin
        Alternative := Trim(RightText);
        RightText := '';
      end
      else
      begin
        Alternative := Trim(Copy(RightText, 1, J - 1));
        Delete(RightText, 1, J);
      end;
      K := Length(Alternative);
      if (Alternative = 'ε') or (LowerCase(Alternative) = 'eps') or
         (LowerCase(Alternative) = 'epsilon') then
        AddProduction(LeftText[1], #0, #0)
      else if (K = 1) and (Alternative[1] in ['a'..'z', '0'..'9']) then
        AddProduction(LeftText[1], Alternative[1], #0)
      else if (K = 2) and (Alternative[1] in ['a'..'z', '0'..'9']) and
              (Alternative[2] in ['A'..'Z']) then
        AddProduction(LeftText[1], Alternative[1], Alternative[2])
      else
        raise Exception.CreateFmt('Linha %d: alternativa "%s" inválida. Use aA, a ou ε.',
          [I + 1, Alternative]);
    end;
  end;
  if Length(FProductions) = 0 then
    raise Exception.Create('Informe ao menos uma produção.');
end;

function TFormGR.Recognize(const AWord: string; out ATrace: string): Boolean;
var
  Queue: array of TSearchNode;
  Seen: array[0..25] of array of Boolean;
  Head, Tail, I, J, PosNow, NewPos, Idx: Integer;
  Node, NewNode: TSearchNode;
  Target: string;
  Valid: Boolean;
begin
  Result := False;
  ATrace := '';
  // The queue explores configurations (nonterminal, input position).
  // Seen guarantees termination even for cyclic grammars.
  SetLength(Seen[0], Length(AWord) + 1);
  for I := 1 to 25 do SetLength(Seen[I], Length(AWord) + 1);
  for I := 0 to 25 do
    for J := 0 to Length(AWord) do Seen[I][J] := False;
  SetLength(Queue, 1);
  Queue[0].State := FStartSymbol;
  Queue[0].Position := 0;
  Queue[0].Trace := FStartSymbol;
  Seen[Ord(FStartSymbol) - Ord('A')][0] := True;
  Head := 0;
  Tail := 1;
  while Head < Tail do
  begin
    Node := Queue[Head];
    Inc(Head);
    PosNow := Node.Position;
    for I := 0 to High(FProductions) do
    begin
      if FProductions[I].LeftSide <> Node.State then Continue;
      if FProductions[I].Terminal = #0 then
      begin
        if PosNow = Length(AWord) then
        begin
          ATrace := Node.Trace + LineEnding + '=> ' + Copy(AWord, 1, PosNow) + 'ε' +
                    LineEnding + '=> ' + (AWord);
          Exit(True);
        end;
      end
      else
      begin
        Valid := (PosNow < Length(AWord)) and
                 (AWord[PosNow + 1] = FProductions[I].Terminal);
        if not Valid then Continue;
        NewPos := PosNow + 1;
        Target := Copy(AWord, 1, NewPos);
        if FProductions[I].NextState = #0 then
        begin
          if NewPos = Length(AWord) then
          begin
            ATrace := Node.Trace + LineEnding + '=> ' + Target;
            Exit(True);
          end;
        end
        else
        begin
          NewNode.State := FProductions[I].NextState;
          NewNode.Position := NewPos;
          NewNode.Trace := Node.Trace + LineEnding + '=> ' + Target + NewNode.State;
          Idx := Ord(NewNode.State) - Ord('A');
          if not Seen[Idx][NewPos] then
          begin
            Seen[Idx][NewPos] := True;
            SetLength(Queue, Tail + 1);
            Queue[Tail] := NewNode;
            Inc(Tail);
          end;
        end;
      end;
    end;
  end;
end;

procedure TFormGR.FormCreate(Sender: TObject);
begin
  MemoGrammar.Lines.Text := 'S -> aA | bS | eps' + LineEnding + 'A -> aS | b';
  EdWord.Text := '';
  MemoTrace.Clear;
  LblResult.Caption := 'Aguardando teste...';
end;

procedure TFormGR.BtnTestClick(Sender: TObject);
var
  W, TraceText: string;
  Accepted: Boolean;
  I: Integer;
begin
  try
    ParseGrammar;
    W := Trim(EdWord.Text);
    if (W = 'ε') or (LowerCase(W) = 'eps') then W := '';
    for I := 1 to Length(W) do
      if not (W[I] in ['a'..'z', '0'..'9']) then
        raise Exception.Create('A palavra deve conter apenas letras minúsculas ou dígitos.');
    Accepted := Recognize(W, TraceText);
    if Accepted then
    begin
      LblResult.Caption := 'Palavra aceita!';
      LblResult.Font.Color := clGreen;
      MemoTrace.Lines.Text := 'Derivação:' + LineEnding + TraceText;
    end
    else
    begin
      LblResult.Caption := 'Palavra rejeitada.';
      LblResult.Font.Color := clRed;
      MemoTrace.Lines.Text := 'Não existe derivação para a palavra informada.';
    end;
  except
    on E: Exception do
    begin
      LblResult.Caption := 'Erro na gramática.';
      LblResult.Font.Color := clRed;
      MemoTrace.Lines.Text := E.Message;
    end;
  end;
end;

end.
