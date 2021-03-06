//------------------------------------------------------------------------------
//
// Main Application Start for Map Tool
//
// Cre 2004-02-17 Pma
//
//------------------------------------------------------------------------------
program MapTool;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {TheMainForm},
  MapItemList in 'MapItemList.pas',
  MapItem in 'MapItem.pas',
  GenUtils in 'GenUtils.pas',
  MapImage in 'MapImage.pas',
  AboutBox in 'AboutBox.pas' {AboutForm},
  GeomUtils in 'GeomUtils.pas',
  MapUtils in 'MapUtils.pas',
  MapItemType in 'MapItemType.pas',
  MapItemTypeList in 'MapItemTypeList.pas',
  MapItemTypeNew in 'MapItemTypeNew.pas' {MapItemTypeNewForm},
  GeomCurve in 'GeomCurve.pas',
  LeafUnit in 'LeafUnit.pas',
  DirDialog in 'DirDialog.pas' {Form1},
  GenPref in 'GenPref.pas' {PrefForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TTheMainForm, TheMainForm);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.CreateForm(TMapItemTypeNewForm, MapItemTypeNewForm);
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPrefForm, PrefForm);
  Application.Run;
end.
