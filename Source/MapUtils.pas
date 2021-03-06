//------------------------------------------------------------------------------
//
// All generic functions on Map
//
// Cre 2004-02-17 Pma
//
//------------------------------------------------------------------------------
unit MapUtils;

interface
uses
  Windows, SysUtils, Classes, Controls, Forms,
  Dialogs, Menus, StdCtrls, ExtCtrls, ComCtrls;

const
  // Loaded cursors for Map

  crMapDefault    =  1; // Default cursor for Map
  crMapDrag       =  2; // Used when dragging / scrolling map
  crMapRotate     =  3; // Used when rotating an item
  crMapPointMove  =  4; // Used when moving a point
  crMapMidMove    =  5; // Used when moving an item
  crMapPointAdd   =  6; // Used when adding a point
  crMapScale      =  7; // Used when scaling a point
  crMapScaleLu    =  8; // Used when scaling Left Up
  crMapScaleLd    =  9; // Used when scaling Left Down
  crMapItem       = 10; // Used when found an item
  crMapPointDel   = 11; // Used when deleting a map point

  procedure LoadCursors;
  function  LoadThisCursor (cur : string) : THandle;

implementation

//------------------------------------------------------------------------------
//                           Loading of cursors
//
procedure LoadCursors;
var
  h : THandle;
begin

  { loaded cursors constants
  crMapDefault    = 1; // Default cursor for Map
  crMapDrag       = 2; // Used when dragging / scrolling map
  crMapRotate     = 3; // Used when rotating an item
  crMapPointMove  = 4; // Used when moving a point
  crMapMidMove    = 5; // Used when moving an item
  crMapPointAdd   = 6; // Used when adding a point
  crMapScale      = 7; // Used when scaling a point
  crMapScaleLu    = 8; // Used when scaling Left Up
  crMapScaleLd    = 9; // Used when scaling Left Down
  crMapItem       = 10; // Used when found an item
  crMapPointDel   = 11; // Used when deleting a map point
  }

  h := LoadThisCursor('MapDefault');
  if h <> 0 then
    Screen.Cursors[crMapDefault] := h;

  h := LoadThisCursor('MapDrag');
  if h <> 0 then
    Screen.Cursors[crMapDrag] := h;

  h := LoadThisCursor('MapRotate');
  if h <> 0 then
    Screen.Cursors[crMapRotate] := h;

  h := LoadThisCursor('MapPointMove');
  if h <> 0 then
    Screen.Cursors[crMapPointMove] := h;

  h := LoadThisCursor('MapMidMove');
  if h <> 0 then
    Screen.Cursors[crMapMidMove] := h;

  h := LoadThisCursor('MapPointAdd');
  if h <> 0 then
    Screen.Cursors[crMapPointAdd] := h;

  h := LoadThisCursor('MapScale');
  if h <> 0 then
    Screen.Cursors[crMapScale] := h;

  h := LoadThisCursor('MapScaleLu');
  if h <> 0 then
    Screen.Cursors[crMapScaleLu] := h;

  h := LoadThisCursor('MapScaleLd');
  if h <> 0 then
    Screen.Cursors[crMapScaleLd] := h;

  h := LoadThisCursor('MapItem');
  if h <> 0 then
    Screen.Cursors[crMapItem] := h;

  h := LoadThisCursor('MapPointDel');
  if h <> 0 then
    Screen.Cursors[crMapPointDel] := h;

end;
//------------------------------------------------------------------------------
//  Load one cursor
//
function LoadThisCursor (cur : string) : THandle;
var
  h : THandle;
  s : string;
begin
  s := ExtractFilePath(Application.ExeName) + cur + '.cur';
  h := LoadImage(0,PAnsiChar(s),
        IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE or LR_LOADFROMFILE);
  if h = 0 then
    ShowMessage('Cursor not loaded >' + cur + '.cur<');

  LoadThisCursor := h;
end;
end.
 