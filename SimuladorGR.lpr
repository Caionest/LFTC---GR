program SimuladorGR;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, UnitGR;


begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TFormGR, FormGR);
  Application.Run;
end.
