//------------------------------------------------------------------------------
//
// All functions that handles Map Image
//
// Cre 2004-02-17 Pma
//
//------------------------------------------------------------------------------
unit MapImage;

interface

uses
  Forms,        // MessageBox + Application
  ExtCtrls,     // TImage
  Controls,     // Mouse
  SysUtils,     // String conversions
  Dialogs,      // ShowMessage
  Types,        // TPoint
  Jpeg,         // TJepeg
  Graphics,     // TBitmap
  Math,         // Mathematics
  Classes,
  ComCtrls,

  GeomUtils;    // Geometrical utilities

const
  constMoveDirLen = 0.15;

  // Types formats of map files that can be loaded

  type TMapType = (mtJpeg, mtGif, mtBmp, mtNone);

  // Record for handling information about maps not loaded (used by listbox)

  type TMapInfo = record
    MapName     : string;   // Name of map without extension
    MapType     : TMapType; // Type of map
    MapExt      : string;   // Real extension of file
    MapSize     : TRect;    // The Width/height of the map
    MapFileSize : integer;  // The size of the mapfile

  end;
  type pTMapInfo = ^TMapInfo;

  type
    TMapImage = class(TObject)
  private
    StatusBar    : TStatusBar;
    MapImage     : TImage;     // Pointer to Map Control
    MapLoaded    : boolean;    // True if map is loaded
    MapType      : TMapType;   // Type of map loaded
    MapJpeg      : TJPEGImage; // JPEG Bitmap
    MapBmp       : TBitmap;    // Bmp Map buffer
    MapFileSize  : integer;    // Size of JPEG file (after loaded)
    MapOrgWidth  : integer;    // Original Jpeg width
    MapOrgHeight : integer;    // Original Jpeg height
    MapMinScale  : real;       // max total scale for 1:1
    MapCurScale  : real;       // current total scale used
    MapOrg       : TPoint;     // origin on Map Image
    MapBuffer    : TBitmap;    // buffer bitmap used
    MapItemColor : TColor;   // Color of items

    MapMatrix    : TMatrix;     // Base matrix with current map scale and
                               // current map position on screen

    // How much scale down/up should step each time in % of org
    // 100 = 2.0, 50= 1.5,  25 = 1.25 scale (on up scaling)
    // 100 = 0.5, 50= 0.75, 25 = 0.75 scale (on down scaling)

    MapScaleIncrement : integer;

  public

    //--- Construction, destruction of MapImage Object -------------------------

    constructor Create(pImage : TImage; stb : TStatusBar); overload;
    procedure   Free; overload;

    //--- Loading the Image Map ------------------------------------------------

    // Convert file extension to map type

    function InqMapTypeFromExt (fExt : string) : TMapType;

    // Load a map image file

    function Load (mName : string) : boolean;

    //--- Move map is a specified direction using move increment ---------------

    // Move map in a direction

    procedure Move (dir : TDirections);

    // Move map a specified distance in screen coordinates

    procedure MoveScrDist (pDist : TPoint); overload;
    procedure MoveScrDist (X,Y  : integer); overload;

    // Move map to a specified map point to middle of screen

    procedure MoveMapPntCenScr (pMap : TPoint);
    function  InqMapPntCenScr : TPoint;

    // Move a specified map point to a specified screen point

    procedure MoveMapPntToScrPnt (pMap, pScr : TPoint);

    // Return which directions the map can move in

    function  InqMoveOptions : TDirections;

    // Basic redraw procedure (just repaints the map at current position)

    procedure BaseDraw;

    // Internal functions

  private
    procedure ScaleInternal (scl : real);
    procedure BaseDrawInternal;
    function IsValid : boolean; // Return true if its ok to use MapImage object
  public

    //---- Scale functions -------------------------------------------------

    procedure Scale (scl : real); overload ;

    procedure Scale (dir : TDirections; pScr : TPoint); overload ;

    function  InqScale : real;    // Return current scale

    function  InqScaleMin : real; // Return the minimum scale
    function  ScaleAssure (pMid : TPoint): boolean;

    function  InqScaleOptions : TDirections; // Return allowed scale up/down

    //---- Generic Inq/Set function --------------------------------------------

    procedure SetScaleIncrement (sclinc : integer);
    function  InqScaleIncrement : integer;

    function  InqOrg   : TPoint; // Get the Map origin

    function  InqDesc  : string; // Get Map description

    //---- Generic geometric functions -----------------------------------------

    // Return the point in Map coordinates from screen bitmap point

    function CnvMapPntToScr(pMap : TPoint): TPoint ;

    // Return the point in Screen bitmap point from point in Map

    function CnvScrPntToMap(pScr : TPoint): TPoint ; overload;
    function CnvScrPntToMap(X,Y : integer): TPoint ; overload;

    // Return if cursor is inside the map image

    function InqCursorInsideMap : boolean;
    function InqMapPosInsideMap (mPos : TPoint) : boolean;

    //---- Draw procedures using Map coordinates -------------------------------

    function  InqMapItemColor : TColor;
    procedure SetMapItemColor (c : TColor);

    // Set fill/pen color/mode and return current

    function DrawSetFillColor (fc : TColor)      : TColor;
    function DrawSetFillMode  (fm : TBrushStyle) : TBrushStyle;
    function DrawSetPenColor  (pc : TColor)      : TColor;
    function DrawSetPenMode   (pm : TPenMode)    : TPenMode;
    function DrawSetPenWidth  (pw : integer)     : integer;

    // Draw functions

    procedure DrawMoveTo (pMap : TPoint); // set start point for LineTo
    procedure DrawLineTo (pMap : TPoint); // Draw from current Pos
    procedure DrawCircle (pMap : TPoint; rad : integer);  // Draw circle
    procedure DrawPoint  (pMap : TPoint; sScr : integer); // Draw a Tpoint
    procedure DrawRect   (rMap : TRect);                  // Draw a TRect

    procedure DrawPline
        (const pBuf   : Array of TPoint;
         const pStart : integer;
         const pStop  : integer;
         const bLine  : boolean;
         const bPnt   : boolean);

    procedure DrawArea
        (const pBuf   : Array of TPoint;
         const pStop  : integer;
         const bLine  : boolean;
         const bPnt   : boolean);

    // Draw the edit frame (bRot if rotation line should be drawn)

    procedure DrawEditFrame ( rect : TRect; bRot : boolean);

    // Matrix functions (uses geomutils as base)

    procedure SetMatrix; overload ; // Set scroll & scale matrix
    procedure SetMatrix(pMid : TPoint; sclX, sclY, ang : real; pMov : TPoint); overload ;
end;

implementation

var
  PolyLineBuf : Array of TPoint; // Buffer for drawing on canvas

//------------------------------------------------------------------------------
//                              Constructors
//------------------------------------------------------------------------------
// Create the Map Image object
//
constructor TMapImage.Create(pImage : TImage; stb : TStatusBar);
begin
  inherited Create;

  StatusBar := stb;

  MapLoaded := false;

  MapImage  := pImage;  // Set a pointer to the Map Image
  MapType   := mtNone;  // No image loaded yet
  MapJpeg   := nil;     // No JPEG Image loaded yet
  MapBmp    := nil;     // No BMP Image loaded yet
  MapBuffer := nil;     // Nu Buffer Bitmap laoded yet

  MapOrgWidth  := 0;
  MapOrgHeight := 0;
  MapMinScale  := 0.0;
  MapCurScale  := 0.0;
  MapOrg.X     := 0;
  MapOrg.Y     := 0;

  MapFileSize := 0;

  MapMatrix := MatrixIdent();

  MapScaleIncrement := 20; // Step each time the scale in increment of two
end;
//------------------------------------------------------------------------------
// Checks if its ok to use the map
//
function TMapImage.IsValid : boolean;
begin
  IsValid := (MapLoaded)         and  // A Map must be loaded
             (MapType <> mtNone) and  // A real MapType must be loaded
             (MapImage <> nil)   and  // The Pointer to the MapImage must exist
             (MapOrgWidth > 0)   and  // Map width must be bigger than 0
             (MapOrgHeight > 0);      // Map height must be bigger than 0
end;
//------------------------------------------------------------------------------
// Free the Map Image object
//
procedure TMapImage.Free;
begin
  // Make sure nobody will use it

  MapLoaded := false;

  // Free all things

  MapJpeg.Free;
  MapBmp.Free;
  MapBuffer.Free;

  // Let borland do their stuff also

  inherited Free;
end;
//------------------------------------------------------------------------------
//  Return MapType from file extension (used for search directory)
//
function TMapImage.InqMapTypeFromExt (fExt : string) : TMapType;
begin
  InqMapTypeFromExt := mtNone;
  if CompareStr(fExt, '.jpg') = 0 then
    InqMapTypeFromExt := mtJpeg
  //else if CompareStr(fExt, '.gif') = 0 then  // Dont know how to do this yet
  //  InqMapTypeFromExt := mtGif
  else if CompareStr(fExt, '.bmp') = 0 then
    InqMapTypeFromExt := mtBmp;
end;
//------------------------------------------------------------------------------
//                    Loading of the image from file
//------------------------------------------------------------------------------
//  Load the JPEG Image and set the initial scale
//
function TMapImage.Load (mName : string) : boolean;
var
  ScaleWdt : real;
  ScaleHgt : real;
  pMap     : TPoint;
  fExt     : string;
begin
  Load := false; // So far no good

  // Load the image from file (The full path must be set

  if FileExists(mName) then
    begin

      // Find the extension of the file

      fExt := ExtractFileExt(mName);

      // Get the map type from extension

      MapType := InqMapTypeFromExt(ExtractFileExt(mName));

      // Load depending on map type

      Case MapType of
      mtJpeg:
        begin
          // Load the image from file into the JPEG Image

          // Create the different bitmaps needed

          if MapJpeg = nil then
            MapJpeg := TJPEGImage.Create;

          if MapBuffer = nil then
            MapBuffer := TBitmap.Create;

          try
            MapJpeg.LoadFromFile(mName);
          except
            on E: Exception do
              begin
                ShowMessage('LoadFromFile Jpeg: ' + E.Message);
                exit;
              end;
          end;

          // Set full size to get the size of the bitmap
          // (He doesn't actually do stuff i think)

          MapJpeg.Performance := jpBestSpeed; // or jpBestQuality
          MapJpeg.Scale := jsFullSize;

          MapOrgHeight := MapJpeg.Height;
          MapOrgWidth  := MapJpeg.Width;
        end;
      mtBmp:
        begin
          // Load the image from file into the MapBuffer

          // Create the different bitmaps needed

          if MapBmp = nil then
            MapBmp := TBitmap.Create;

          if MapBuffer = nil then
            MapBuffer := TBitmap.Create;

          try
            MapBmp.LoadFromFile(mName);
          except
            on E: Exception do
              begin
                ShowMessage('LoadFromFile (bmp): ' + E.Message);
                exit;
              end;
          end;

          MapOrgHeight := MapBmp.Height;
          MapOrgWidth  := MapBmp.Width;
        end;
      mtNone: exit;
      end;

      MapLoaded := (MapOrgHeight > 0) and (MapOrgWidth > 0);
      if not MapLoaded then
        exit;

      // Calculate the maximum scale that can be used to fill screen Map
      // with current size of Map canvas

      ScaleWdt := MapImage.Width / MapOrgWidth;
      ScaleHgt := MapImage.Height / MapOrgHeight;

      if ScaleWdt < ScaleHgt then
        MapMinScale := ScaleHgt
      else
        MapMinScale := ScaleWdt;

      // Fill the screen with the Map

      Scale (MapMinScale);

      // Position it in the middle

      pMap.X := round(MapOrgWidth / 2);
      pMap.Y := round(MapOrgHeight / 2);
      MoveMapPntCenScr(pMap);

      // Free any resources not used

      Case MapType of
        mtJpeg:
          begin
            // Free any old Bmp buffer

            if MapBmp <> nil then
              MapBmp.Free;
            MapBmp := nil;
          end;
        mtGif:
          begin
            // Free any old JPEG Image

            if MapJpeg <> nil then
              MapJpeg.Free;
            MapJpeg := nil;

            // Free any old Bmp buffer

            if MapBmp <> nil then
              MapBmp.Free;
            MapBmp := nil;

          end;
        mtBmp:
          begin
            // Free any old JPEG Image

            if MapJpeg <> nil then
              MapJpeg.Free;
            MapJpeg := nil;
          end;
      end;

      Load := true; // OK, loaded
    end;
end;
//------------------------------------------------------------------------------
//                        Moving (scrolling) the map
//------------------------------------------------------------------------------
// Scroll in a direction
//
procedure TMapImage.Move (dir : TDirections);
begin
  if not IsValid() then Exit;

  // Set the new org depending on scroll direction

  if (drLeft in dir) then
    MapOrg.X := MapOrg.X + round(MapImage.ClientWidth * constMoveDirLen)
  else if drRight in dir then
    MapOrg.X := MapOrg.X - round(MapImage.ClientWidth * constMoveDirLen);

  if drUp in dir then
      MapOrg.Y := MapOrg.Y + round(MapImage.ClientHeight * constMoveDirLen)
  else if drDown in dir then
      MapOrg.Y := MapOrg.Y - round(MapImage.ClientHeight * constMoveDirLen);

  BaseDraw; // Use the basic draw
end;
//------------------------------------------------------------------------------
// Move the Map to a Map Point  InqMapPntCenScr
//
procedure TMapImage.MoveMapPntCenScr (pMap : TPoint);
var
  mX, mY : integer;
begin
  if not IsValid() then Exit;

  // Calc Screen absolut pos without any scroll yet

  mX  := round(pMap.X * MapCurScale);
  mY  := round(pMap.Y * MapCurScale);

  // Set the new org for draw so the pos is in the middle of map

  MapOrg.X := - mX + round(MapImage.Width / 2);
  MapOrg.Y := - mY + round(MapImage.Height / 2);

  BaseDraw; // Use the basic draw
end;
//------------------------------------------------------------------------------
// Return the Map point in the center of screen
//
function TMapImage.InqMapPntCenScr : TPoint;
begin
  InqMapPntCenScr.X := 0;
  InqMapPntCenScr.Y := 0;

  if not IsValid() then Exit;

  // Find the screen pos in middle
  // Convert this to map coordinates

  InqMapPntCenScr := CnvScrPntToMap (round(MapImage.Width / 2),
                                      round(MapImage.Height / 2));
end;
//------------------------------------------------------------------------------
// Move the Map to a Map Point
//
procedure TMapImage.MoveMapPntToScrPnt (pMap, pScr : TPoint);
var
  mX, mY : integer;
begin
  if not IsValid() then Exit;

  // Calc Screen absolut pos without any scroll yet

  mX  := round(pMap.X * MapCurScale);
  mY  := round(pMap.Y * MapCurScale);

  // Set the new org for draw so the pos is in the middle of map

  MapOrg.X := - mX + pScr.X;
  MapOrg.Y := - mY + pScr.Y;

  BaseDraw; // Use the basic draw
end;
//------------------------------------------------------------------------------
// Move the Map a specific distance (scr coords)
//
procedure TMapImage.MoveScrDist (pDist : TPoint);
begin
  MoveScrDist(pDist.X,pDist.Y);
end;
procedure TMapImage.MoveScrDist (X,Y : integer);
begin
  if not IsValid() then Exit;

  // Set the new org for draw

  MapOrg.X := MapOrg.X + X;
  MapOrg.Y := MapOrg.Y + Y;

  BaseDraw; // Use the basic draw
end;
//------------------------------------------------------------------------------
// Return current Item color
//
function TMapImage.InqMapItemColor : TColor;
begin
  InqMapItemColor := MapItemColor;
end; 
//------------------------------------------------------------------------------
// Set current Item color
//
procedure TMapImage.SetMapItemColor (c : TColor);
begin
  MapItemColor := c;
end;
//------------------------------------------------------------------------------
// Draw the map to canvas when all is set
//
procedure TMapImage.BaseDraw;
begin
  BaseDrawInternal;
end;
//------------------------------------------------------------------------------
// Draw the map to canvas when all is set
//
procedure TMapImage.BaseDrawInternal;
const bit = 2;
var
  DestRect, SourceRect : TRect;
begin
  if not IsValid() then Exit;

  if MapCurScale <= 1.01 then
    begin
      // When scale is 1.0 or lower the MapBuffer has the right
      // dimensions and its a straight copy rect without stretching at all

      // Make sure you dont move outside canvas

      if MapOrg.X > 0 then
        MapOrg.X := 0;

      if MapOrg.Y > 0 then
        MapOrg.Y := 0;

      if MapOrg.Y < - (MapBuffer.Height - MapImage.Height) then
        MapOrg.Y := - (MapBuffer.Height - MapImage.Height);

      if MapOrg.X < - (MapBuffer.Width - MapImage.Width) then
        MapOrg.X := - (MapBuffer.Width - MapImage.Width);

      SourceRect.Left   := - MapOrg.X;
      SourceRect.Right  := - MapOrg.X + MapImage.Width;
      SourceRect.Top    := - MapOrg.Y;
      SourceRect.Bottom := - MapOrg.Y + MapImage.Height;
    end
  else
    begin
      // When the scale is bigger the MapBuffer is still 1.0 scale
      // And we strech out the Copy the amount of the bigger scale

      if MapOrg.X > 0 then
        MapOrg.X := 0;

      if MapOrg.Y > 0 then
        MapOrg.Y := 0;

      if MapOrg.Y < - (round(MapBuffer.Height*MapCurScale) - MapImage.Height) then
        MapOrg.Y := - (round(MapBuffer.Height*MapCurScale) - MapImage.Height);

      if MapOrg.X < - (round(MapBuffer.Width*MapCurScale) - MapImage.Width) then
        MapOrg.X := - (round(MapBuffer.Width*MapCurScale) - MapImage.Width);

      SourceRect.Left   := - MapOrg.X;
      SourceRect.Right  := - MapOrg.X + MapImage.Width;
      SourceRect.Top    := - MapOrg.Y;
      SourceRect.Bottom := - MapOrg.Y + MapImage.Height;

      SourceRect := RectScale(SourceRect, 1/MapCurScale);

      //SourceRect.Left := bit * (SourceRect.Left Div bit);
      //SourceRect.Right := bit * (SourceRect.Right Div bit);
      //SourceRect.Top := bit * (SourceRect.Top Div bit);
      //SourceRect.Bottom := bit * (SourceRect.Bottom Div bit);
    end;


  // The destination map is always the map image size on the screen

  DestRect.Left   := 0;
  DestRect.Right  := MapImage.Width;
  DestRect.Top    := 0;
  DestRect.Bottom := MapImage.Height;

  //StatusBar.Panels[0].Text := 'Scl: ' + FloatToStr(MapCurScale) + 's: ' +
  //                RectToStr(SourceRect) + ' d: ' + RectToStr(DestRect);

  MapImage.Picture.Bitmap.Canvas.CopyRect(DestRect, MapBuffer.Canvas, SourceRect);

  
  SetMatrix; // Set the basic matrix used when drawing map items

end;
//------------------------------------------------------------------------------
//                          Scaling of the image
//------------------------------------------------------------------------------
// We change the scale of the picture
//
procedure TMapImage.Scale(scl : real);
var
  oldScale : real;
  oldCursor : TCursor;
begin

  if scl < 0.01 then exit;
  
  oldScale := InqScale();

  oldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;

  try
    try
      ScaleInternal (scl);
    except
      on E: EOutOfResources do
        begin
          ShowMessage('Out of resurces (internal): ' + E.Message);
          ScaleInternal (oldScale * 0.8);
        end
    end;
  finally
    Screen.Cursor := oldCursor
  end;
end;
//------------------------------------------------------------------------------
// We change the scale of the picture
//
procedure TMapImage.ScaleInternal(scl : real);
var
  newScale  : real;
  rRect     : TRect;
  destRect, sourceRect : TRect;
begin
  if not IsValid() then Exit;

  // Make sure scale is a fraction 0.1 (looks better)

  newScale := round(scl * 10) / 10;

  // Dont use any smaller size than will fill on map

  newScale := max (MapMinScale, newScale);
  MapCurScale := newScale;

  // Find the best Jpeg Scale to use (one size bigger than scale)

  case MapType of
  mtJpeg :
    begin
      if (newScale <= 0.125) then
        MapJpeg.Scale := jsEighth
      else if (newScale <= 0.25) then
        MapJpeg.Scale := jsQuarter
      else if (newScale <= 0.5) then
        MapJpeg.Scale := jsHalf
      else
        MapJpeg.Scale := jsFullSize;

      // Calculate the Buffer Bitmap size (Don't go over 1.0)

      MapBuffer.Width  := round(MapOrgWidth * Min(1.0, newScale));
      MapBuffer.Height := round(MapOrgHeight * Min(1.0, newScale));

      // Draw the Jpeg Image to the buffer with stretch draw

      rRect.Left := 0;
      rRect.Right := MapBuffer.Width;

      rRect.Top := 0;
      rRect.Bottom := MapBuffer.Height;

      MapBuffer.Canvas.StretchDraw (rRect,MapJpeg);

      // Draw the Buffer bitmap on the Map Image Canvas
    end;
  mtBmp:
    begin

      // Calculate the Buffer Bitmap size (Don't go over 1.0)

      MapBuffer.Width  := round(MapOrgWidth * Min(1.0, newScale));
      MapBuffer.Height := round(MapOrgHeight * Min(1.0, newScale));

      // Draw the Bmp Image to the buffer with stretch draw

      // MapBuffer is destination

      destRect.Left := 0;
      destRect.Right := MapBuffer.Width;
      destRect.Top := 0;
      destRect.Bottom := MapBuffer.Height;

      // MapBmp is Source

      sourceRect.Left := 0;
      sourceRect.Right := MapBmp.Width;
      sourceRect.Top := 0;
      sourceRect.Bottom := MapBmp.Height;

      rRect.Left := 0;
      rRect.Right := MapBuffer.Width;

      rRect.Top := 0;
      rRect.Bottom := MapBuffer.Height;

      // Somehow the strech draw is better (looks nicer)

      //MapBuffer.Canvas.CopyRect (destRect,MapBmp.Canvas, sourceRect);
      MapBuffer.Canvas.StretchDraw (rRect,MapBmp);
    end;
  end;

  MapOrg.X := 0;
  MapOrg.Y := 0;

  MapImage.Picture.Bitmap.Width := MapImage.Width;
  MapImage.Picture.Bitmap.Height := MapImage.Height;

  BaseDraw;

end;
//------------------------------------------------------------------------------
// Set Scale Up/down  (dir 1=up, dir 2=down)
//
procedure TMapImage.Scale (dir : TDirections; pScr : TPoint);
var
  pMap : TPoint;
  newScl : real;
  sclInc : real;
begin
  if not IsValid() then Exit;

  // Calc point from screen to map

  pMap := CnvScrPntToMap(pScr);

  newScl := MapCurScale;

  case MapScaleIncrement of
  10: sclInc := 0.1;
  20: sclInc := 0.2;
  else
      sclInc := 0.4;
  end;

  // Calculate the new scale to use

  if drUp in dir then
      newScl := MapCurScale + sclInc
  else if drDown in dir then
      newScl := MapCurScale - sclInc;

  // Calculate the new orging (in the middle of the map)

  pScr.X := round(MapImage.Width * 0.5);
  pScr.Y := round(MapImage.Height * 0.5);

  // Scale it

  Scale (newScl);

  // Move it to point also

  MoveMapPntCenScr(pMap);

end;
//------------------------------------------------------------------------------
// Make sure the current scale is not to small
//
function TMapImage.ScaleAssure (pMid : TPoint): boolean;
var
  sWdt, sHgt : real;
begin
  ScaleAssure := false;

  if not IsValid() then Exit;

  // Calculate the maximum scale that can be used to fill screen Map
  // with current size of Map canvas

  sWdt := MapImage.Width / MapOrgWidth;
  sHgt := MapImage.Height / MapOrgHeight;

  if sWdt < sHgt then
    MapMinScale := sHgt
  else
    MapMinScale := sWdt;

  if MapCurScale < MapMinScale then
    begin
      Scale (MapMinScale);
      MoveMapPntCenScr(pMid);
      ScaleAssure := true;
    end
  else
    begin
      Scale(MapCurScale);
      MoveMapPntCenScr(pMid);
    end;
end;
//------------------------------------------------------------------------------
// Return current scale
//
function TMapImage.InqScale : real;
begin
  InqScale := MapCurScale;
end;
//------------------------------------------------------------------------------
// Return minimum scale
//
function TMapImage.InqScaleMin : real;
begin
  InqScaleMin := MapMinScale;
end;
//------------------------------------------------------------------------------
// Return current scale increment
//
function TMapImage.InqScaleIncrement : integer;
begin
  InqScaleIncrement := MapScaleIncrement;
end;
//------------------------------------------------------------------------------
// Set scale increment
//
procedure TMapImage.SetScaleIncrement (sclinc : integer);
begin
  case sclinc of
  10: MapScaleIncrement := 10;
  20: MapScaleIncrement := 20;
  else
      MapScaleIncrement := 40;
  end;
end;
//------------------------------------------------------------------------------
// Return allowed scale options
//
function TMapImage.InqScaleOptions : TDirections;
var
  dirOpt : TDirections;
begin
  InqScaleOptions := [];

  dirOpt := [];

  if (MapCurScale <= 10) then
    dirOpt := dirOpt + [drUp];

  if (MapCurScale > MapMinScale) then
    dirOpt := dirOpt + [drDown];

  InqScaleOptions := dirOpt;
end;
//------------------------------------------------------------------------------
//                        Simple Inq / Set functions
//------------------------------------------------------------------------------
// Return current origin of the map in screen coordinates
//
function TMapImage.InqOrg : TPoint;
begin
  InqOrg := MapOrg;
end;
//------------------------------------------------------------------------------
// Return string describing the map
//
function TMapImage.InqDesc : string;
begin
  case MapType of
  mtJpeg : InqDesc := 'Jpeg: ' + IntToStr(MapOrgWidth) + 'x' +
                                 IntToStr(MapOrgHeight) +
                      ' Pixels';
  mtGif  : InqDesc := 'Gif: ' + IntToStr(MapOrgWidth) + 'x' +
                                IntToStr(MapOrgHeight) +
                      ' Pixels';
  mtBmp  : InqDesc := 'Bmp: ' + IntToStr(MapOrgWidth) + 'x' +
                                IntToStr(MapOrgHeight) +
                      ' Pixels';
  else
    InqDesc := 'Not loaded';
  end;
end;
//------------------------------------------------------------------------------
// Return which direction is allowed to scroll in
//
function TMapImage.InqMoveOptions : TDirections;
var
  dirOpt : TDirections;
begin
  InqMoveOptions := [];

  if (not (MapBuffer is TBitmap)) or (not (MapImage is TImage)) then Exit;

  dirOpt := [];

  if not (MapOrg.X = 0) then
    dirOpt := dirOpt + [drLeft];

  if not (MapOrg.X = - (MapBuffer.Width - MapImage.Width)) then
    dirOpt := dirOpt + [drRight];

  if not (MapOrg.Y = 0) then
    dirOpt := dirOpt + [drUp];

  if not (MapOrg.Y = - (MapBuffer.Height - MapImage.Height)) then
    dirOpt := dirOpt + [drDown];

  InqMoveOptions := dirOpt;
end;
//------------------------------------------------------------------------------
// Set MapMatrix after each scroll or rescale of map
//
procedure TMapImage.SetMatrix;
begin
  MapMatrix := MatrixMlt(MatrixScl(MapCurScale),MatrixTran(MapOrg));
end;
//------------------------------------------------------------------------------
// Set MapMatrix when scaling, rotating or moving an item
//
procedure TMapImage.SetMatrix(pMid : TPoint; sclX, sclY, ang : real; pMov : TPoint);
var
  mTmp : TMatrix;
  pTmp : TPoint;
begin

  // Set the base identity matrix

  SetMatrix;

  // Move to the mid point to scale and rotate around

  pTmp.X := - pMid.X;
  pTmp.Y := - pMid.Y;
  mTmp := MatrixTran (pTmp);

  // Rotate and scale

  mTmp := MatrixMlt(mTmp,MatrixRot(ang));
  mTmp := MatrixMlt(mTmp,MatrixScl(sclX, sclY));

  // Move back to the mid point

  mTmp := MatrixMlt(mTmp,MatrixTran(PntMove(pMid,pMov)));

  // Catinate with current display matrix and use it

  MapMatrix := MatrixMlt(mTmp,MapMatrix);
end;
//------------------------------------------------------------------------------
// Draw a edit frame
//
procedure TMapImage.DrawEditFrame (rect : TRect; bRot : boolean);
var
  pMid : TPoint;
  rTmp : TRect;

  fm : TBrushStyle;
  pc : TColor;
  pw : integer;
  pm : TPenMode;

  sclBoxSize  : integer;
  midBoxSize  : integer;
  rotBoxSize  : integer;
  rotLineSize : integer;

begin
  if (MapCurScale = 0.0) or
     (not (MapImage is TImage)) then
    Exit;

  // Set fill/pen properties

  fm := DrawSetFillMode  (bsClear);
  pc := DrawSetPenColor  (clBlack);
  pm := DrawSetPenMode   (pmNotXor);
  pw := DrawSetPenWidth  (1);

  // Calculate scale box size, mid box size, and rot box size

  sclBoxSize  := round(msSclSize/MapCurScale);
  midBoxSize  := round(msMoveSize/MapCurScale);
  rotBoxSize  := round(msRotSize/MapCurScale);
  rotLineSize := round(msRotLineSize/MapCurScale);

  // Draw the outside rectangle

  DrawRect(rect);

  // Draw a small scuare at each corner

  rTmp.Left   := rect.Left - sclBoxSize;
  rTmp.Right  := rect.Left + sclBoxSize;
  rTmp.Top    := rect.Top  - sclBoxSize;
  rTmp.Bottom := rect.Top  + sclBoxSize;

  DrawRect(rTmp);

  rTmp.Left   := rect.Left   - sclBoxSize;
  rTmp.Right  := rect.Left   + sclBoxSize;
  rTmp.Top    := rect.Bottom - sclBoxSize;
  rTmp.Bottom := rect.Bottom + sclBoxSize;

  DrawRect(rTmp);

  rTmp.Left   := rect.Right  - sclBoxSize;
  rTmp.Right  := rect.Right  + sclBoxSize;
  rTmp.Top    := rect.Bottom - sclBoxSize;
  rTmp.Bottom := rect.Bottom + sclBoxSize;

  DrawRect(rTmp);

  rTmp.Left   := rect.Right - sclBoxSize;
  rTmp.Right  := rect.Right + sclBoxSize;
  rTmp.Top    := rect.Top   - sclBoxSize;
  rTmp.Bottom := rect.Top   + sclBoxSize;

  DrawRect(rTmp);

  // Draw a small scuare in the middle

  rTmp.Left   := rect.Left + round((rect.Right  - rect.Left)/2) - midBoxSize;
  rTmp.Right  := rect.Left + round((rect.Right  - rect.Left)/2) + midBoxSize;
  rTmp.Top    := rect.Top +  round((rect.Bottom - rect.Top)/2)  - midBoxSize;
  rTmp.Bottom := rect.Top +  round((rect.Bottom - rect.Top)/2)  + midBoxSize;

  DrawRect(rTmp);

  if bRot then
    begin
      // Draw a small line out to the right with a scuare at end

      pMid := InqMidOfRect(rect);

      DrawMoveTo(pMid);
      pMid.X := pMid.X + rotLineSize;
      DrawLineTo(pMid);

      DrawRect(RectIncrement(pMid,rotBoxSize));

    end;

  // Reset fill/pen properties

  DrawSetFillMode  (fm);
  DrawSetPenColor  (pc);
  DrawSetPenMode   (pm);
  DrawSetPenWidth  (pw);
end;
//------------------------------------------------------------------------------
//                        Genereal geometric functions
//------------------------------------------------------------------------------
// Return the point in Map coordinates from screen bitmap point
//
function TMapImage.CnvMapPntToScr(pMap : TPoint): TPoint ;
begin
  //CnvMapPntToScr.X := round(pMap.X * MapCurScale) + MapOrg.X;
  //CnvMapPntToScr.Y := round(pMap.Y * MapCurScale) + MapOrg.Y;
  CnvMapPntToScr := MatrixInqPos(MapMatrix,pMap);
end;
//------------------------------------------------------------------------------
// Return the point in Screen bitmap point from point in Map
//
function TMapImage.CnvScrPntToMap(pScr : TPoint): TPoint ;
begin
  if MapCurScale <> 0.0 then
    begin
      CnvScrPntToMap.X := round((pScr.X - MapOrg.X) / MapCurScale);
      CnvScrPntToMap.Y := round((pScr.Y - MapOrg.Y) / MapCurScale);
    end
  else
    begin
      CnvScrPntToMap.X := 0;
      CnvScrPntToMap.Y := 0;
    end
end;
function TMapImage.CnvScrPntToMap(X,Y : integer): TPoint ;
begin
  if MapCurScale <> 0.0 then
    begin
      CnvScrPntToMap.X := round((X - MapOrg.X) / MapCurScale);
      CnvScrPntToMap.Y := round((Y - MapOrg.Y) / MapCurScale);
    end
  else
    begin
      CnvScrPntToMap.X := 0;
      CnvScrPntToMap.Y := 0;
    end
end;
//------------------------------------------------------------------------------
// Return true if cursor is indide the map
//
function TMapImage.InqCursorInsideMap : boolean;
var
  pScr : TPoint;
begin
  InqCursorInsideMap := false;

  if (MapImage is TImage) then
    begin
      pScr := MapImage.ScreenToClient(Mouse.CursorPos);

      InqCursorInsideMap := not
        ((pScr.Y < 0) or (pScr.Y > MapImage.Height) or
        (pScr.X < 0) or (pScr.X > MapImage.Width));
    end;
end;
//------------------------------------------------------------------------------
// Return true if a map point is visible
//
function TMapImage.InqMapPosInsideMap (mPos : TPoint) : boolean;
var
  pScr : TPoint;
begin
  InqMapPosInsideMap := false;

  if (MapImage is TImage) then
    begin
      pScr := CnvMapPntToScr(mPos);

      InqMapPosInsideMap := not
        ((pScr.Y < 0) or (pScr.Y > MapImage.Height) or
        (pScr.X < 0) or (pScr.X > MapImage.Width));
    end;
end;
//------------------------------------------------------------------------------
//                  Draw procedures using Map coordinates
//------------------------------------------------------------------------------
// Set fill/pen color/mode returning old values
//
function TMapImage.DrawSetFillColor (fc : TColor)      : TColor;
begin
  if (MapImage is TImage) then
    begin
      DrawSetFillColor := MapImage.Canvas.Brush.Color;
      MapImage.Canvas.Brush.Color := fc;
    end
  else
    DrawSetFillColor := clBlack;
end;
function TMapImage.DrawSetFillMode  (fm : TBrushStyle) : TBrushStyle;
begin
  if (MapImage is TImage) then
    begin
      DrawSetFillMode := MapImage.Canvas.Brush.Style;
      MapImage.Canvas.Brush.Style := fm;
    end
  else
    DrawSetFillMode := bsClear;
end;
function TMapImage.DrawSetPenColor  (pc : TColor)      : TColor;
begin
  if (MapImage is TImage) then
    begin
      DrawSetPenColor := MapImage.Canvas.Pen.Color;
      MapImage.Canvas.Pen.Color := pc;
    end
  else
    DrawSetPenColor := clBlack;
end;
function TMapImage.DrawSetPenMode   (pm : TPenMode)    : TPenMode;
begin
  if (MapImage is TImage) then
    begin
      DrawSetPenMode := MapImage.Canvas.Pen.Mode;
      MapImage.Canvas.Pen.Mode := pm;
    end
  else
    DrawSetPenMode := pmCopy;
end;
function TMapImage.DrawSetPenWidth   (pw : integer)    : integer;
begin
  if (MapImage is TImage) then
    begin
      DrawSetPenWidth := MapImage.Canvas.Pen.Width;
      MapImage.Canvas.Pen.Width := pw;
    end
  else
    DrawSetPenWidth := 1;
end;
//------------------------------------------------------------------------------
// Move current point to pMap
//
procedure TMapImage.DrawMoveTo (pMap : TPoint);
var
  p : TPoint;
begin
  if (MapImage is TImage) then
    begin
      p := MatrixInqPos(MapMatrix,pMap);
      MapImage.Canvas.MoveTo (p.X, p.Y);
    end;
end;
//------------------------------------------------------------------------------
// Draw from current point to pMap
//
procedure TMapImage.DrawLineTo (pMap : TPoint);
var
  p : TPoint;
begin
  if (MapImage is TImage) then
    begin
      p := MatrixInqPos(MapMatrix,pMap);
      MapImage.Canvas.LineTo (p.X, p.Y);
    end;
end;
//------------------------------------------------------------------------------
// Draw a circle at pMap using radie rad
//
procedure TMapImage.DrawCircle (pMap : TPoint; rad : integer);
begin
  if (MapImage is TImage) then
    MapImage.Canvas.Ellipse (RectIncrement(MatrixInqPos(MapMatrix,pMap),
                                MatrixInqSize (MapMatrix,rad)));
end;
//------------------------------------------------------------------------------
// Draw a point (the size is screen pixels)
//
procedure TMapImage.DrawPoint (pMap : TPoint; sScr : integer);
begin
  if (MapImage is TImage) then
    MapImage.Canvas.Ellipse
          (RectIncrement(MatrixInqPos(MapMatrix,pMap), sScr));
end;
//------------------------------------------------------------------------------
// Draw a ractangle
//
procedure TMapImage.DrawRect (rMap : TRect);
var
  pnt, oldpnt : TPoint;
begin
  if (MapImage is TImage) then
    begin
      oldpnt := MapImage.Canvas.PenPos;

      // Move to starting point

      pnt := rMap.TopLeft;
      DrawMoveTo(pnt);

      pnt.X := rMap.Right;
      DrawLineTo(pnt);

      pnt.Y := rMap.Bottom;
      DrawLineTo(pnt);

      pnt.X := rMap.Left;
      DrawLineTo(pnt);

      pnt.Y := rMap.Top;
      DrawLineTo(pnt);

      DrawMoveTo(oldpnt);
    end;
end;
//------------------------------------------------------------------------------
// Draw a Poly line   Canvas.Polyline(Slice(PointArray, 10));
//
procedure TMapImage.DrawPline
        (const pBuf   : Array of TPoint;
         const pStart : integer;
         const pStop  : integer;
         const bLine  : boolean;
         const bPnt   : boolean);
var
 ind : integer;
 pos : TPoint;
 len : integer;

begin
  if MapImage = nil then exit;

  // Make sure the PolyLineBuffer has enough space

  if bLine then
    begin
      SetLength(PolyLineBuf, pStop + 1 - pStart);
    end;

  // Build up the PolyLineBuffer with screen coordinates

  len := 0;

  for ind := pStart to pStop  do
    begin

      // Map this point to scr matrix

      pos := MatrixInqPos(MapMatrix,pBuf[ind]);

      if bPnt then
        begin
          // Draw a point in the size of the screen

          MapImage.Canvas.Ellipse (RectIncrement(pos, msPointSize));
        end;

      if bLine then
        begin
          PolyLineBuf[len] := pos;
          len := len +1;
        end;
    end;

  if bLine then
    begin
      MapImage.Canvas.Polyline(PolyLineBuf);
    end;
end;
//------------------------------------------------------------------------------
// Draw a Area Polugon
//
procedure TMapImage.DrawArea
        (const pBuf   : Array of TPoint;
         const pStop  : integer;
         const bLine  : boolean;
         const bPnt   : boolean);
var
 ind : integer;
 pos : TPoint;
 len : integer;

begin
  if MapImage = nil then exit;

  // Make sure the PolyLineBuffer has enough space

  if bLine then
    begin
      SetLength(PolyLineBuf, pStop + 1);
    end;

  // Build up the PolyLineBuffer with screen coordinates

  len := 0;

  for ind := 0 to pStop  do
    begin

      // Map this point to scr matrix

      pos := MatrixInqPos(MapMatrix,pBuf[ind]);

      if bPnt then
        begin
          // Draw a point in the size of the screen

          MapImage.Canvas.Ellipse (RectIncrement(pos, msPointSize));
        end;

      if bLine then
        begin
          PolyLineBuf[len] := pos;
          len := len +1;
        end;
    end;

  if bLine then
    begin
      MapImage.Canvas.Polygon(PolyLineBuf);
    end;
end;
end.
