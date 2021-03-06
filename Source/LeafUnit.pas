unit LeafUnit;

interface

uses
  Math,     // Mathematics
  SysUtils, // String conversions used
  Types,    // TPoint
  Classes,  // TList
  Graphics, // TColor

  GenUtils,   // My utils
  GeomUtils;  // Geometrical utilities

const
  LeafObjectAtEnd = 9999; // ObjectId for end of this leaf

type

  // Predifined attribute types that can be used for storing attribute values

  TLeafAttType = (atUnknown,   // Unknown object to this version of application
                  atString,    // String value  ("sss"" > ")
                  atInteger,   // Integer value (number)
                  atPoint,     // Point value (x,y)
                  atPointList, // List of points (x1,y1,x2,y2,... xn,yn)
                  atRect,      // REct (left, right, top, bottom) (integer)
                  atColor);    // Windows Color (HEX)

  TLeafRecord = record
    LeafId      : integer;      // Unique id of this leaf (in this scope)
    LeafName    : string;       // Name used for saving/loading
    LeafAttType : TLeafAttType; // Type of predifined attribute types
  end;
  TLeafRecordArray = Array of TLeafRecord;

  //--- Functions to handle the Leaf arrays ------------------------------------

  function LeafAdd      (var leafrecord : TLeafRecordArray;
                         Id         : integer;
                         lName      : string;
                         aType      : TLeafAttType): integer;

  function LeafGetId    (leafrecord : TLeafRecordArray;
                         lName      : string): integer;

  function LeafGetName  (leafrecord : TLeafRecordArray;
                         lId        : integer) : string;

  function LeafGetAttType (leafrecord : TLeafRecordArray;
                           lId        : integer) : TLeafAttType;

  //--- Functions to convert attributes to strings -----------------------------

  function LeafIntToStr       (iInt : integer)         : string;
  function LeafStrToStr       (sStr : string)          : string;
  function LeafColorToStr     (tCol : TColor)          : string;
  function LeafPointToStr     (pPos : TPoint)          : string;
  function LeafPointListToStr (pBuf : TPointArray) : string;

  function LeafIntFromStr       (sBuf : string): integer;
  function LeafStrFromStr       (sBuf : string): string;
  function LeafColorFromStr     (sBuf : string): TColor;
  function LeafPointFromStr     (sBuf : string): TPoint;
  function LeafPointListFromStr (sBuf : string; var pBuf : TPointArray) : boolean;

  //--- General Load Functions -------------------------------------------------

  function LeafGetObjectName  (sBuf : string) : string;
  function LeafGetValueStr    (sBuf : string) : string;
  function LeafSkipObject     (var F : TextFile): boolean;

implementation

//------------------------------------------------------------------------------
//                      Functions to handle the Leaf arrays
//------------------------------------------------------------------------------
// Add a new Leaf to an leaf record array
//
function LeafAdd (var leafrecord : TLeafRecordArray;
    Id : integer; lName : string; aType : TLeafAttType): integer;
var
  h : integer;
begin
  h := High(leafrecord);

  if (h = -1) then
    begin
      SetLength(leafrecord, 1);
      h := 0;
    end
  else
    begin
      SetLength(leafrecord, h + 2);
      h := h + 1
    end;

  leafrecord[h].LeafId       := Id;
  leafrecord[h].LeafName     := lName;
  leafrecord[h].LeafAttType  := aType;
  LeafAdd := h;
end;
//------------------------------------------------------------------------------
// Return leaf id from name
//
function  LeafGetId (leafrecord : TLeafRecordArray; lName : string): integer;
var
  i : integer;
begin

  // First test if buffer length is zero, then end of objects

  if length(lName) = 0 then
    begin
      LeafGetId := LeafObjectAtEnd;
      exit;
    end;

  // Search Array for leaf with same name

  for i := 0 to High(Leafrecord) do
    if CompareStr(Leafrecord[i].LeafName, lName) = 0 then
      begin
        LeafGetId := i;
        exit;
      end;
  LeafGetId := -1;
end;
//------------------------------------------------------------------------------
// Return name from id
//
function  LeafGetName (leafrecord : TLeafRecordArray; lId : integer) : string;
var
  h : integer;
begin
  h := High(leafrecord);
  if (lId >= 0) and (lId <= h) then
    LeafGetName := leafrecord[lId].LeafName
  else
    LeafGetName := '';
end;
//------------------------------------------------------------------------------
// Return attribute type from id
//
function  LeafGetAttType (leafrecord : TLeafRecordArray;
            lId : integer) : TLeafAttType;
begin
  if (lId >= 0) and (lId <= High(leafrecord)) then
    LeafGetAttType := leafrecord[lId].LeafAttType
  else
    LeafGetAttType := atUnknown;
end;
//------------------------------------------------------------------------------
//                  Functions to convert attributes to strings
//------------------------------------------------------------------------------
// Convert a integer to a string
//
function  LeafIntToStr   (iInt : integer) : string;
begin
  LeafIntToStr := IntToStr(iInt);
end;
//------------------------------------------------------------------------------
// Convert a string to a string
//
function  LeafStrToStr   (sStr : string) : string;
begin
  LeafStrToStr := '"' + StringAddDel( sStr, '"') + '"';
end;
//------------------------------------------------------------------------------
// Convert a color to a string
//
function  LeafColorToStr (tCol : TColor) : string;
begin
  LeafColorToStr := ColorToString(tCol);
end;
//------------------------------------------------------------------------------
// Convert a point to a string
//
function  LeafPointToStr (pPos : TPoint) : string;
begin
  LeafPointToStr := IntToStr(pPos.X) + ',' + IntToStr(pPos.Y);
end;
//------------------------------------------------------------------------------
// Convert list of points to a string
//
function  LeafPointListToStr (pBuf : TPointArray) : string;
var
  i : integer;
  s : string;
begin
  s := '';

  for i := 0 to High(pBuf) do
    begin
      s := s + LeafPointToStr(pBuf[i]);
      if i < High(pBuf) then
        s := s + ',';
    end;

  LeafPointListToStr := s;
end;
//------------------------------------------------------------------------------
//                  Functions to convert strings to attributes
//------------------------------------------------------------------------------
// Convert a integer to a string
//
function  LeafIntFromStr       (sBuf : string): integer;
begin
  LeafIntFromStr := StrToInt(sBuf);
end;
//------------------------------------------------------------------------------
// Convert a string to a string
//
function  LeafStrFromStr       (sBuf : string): string;
var
  i : integer;
begin
  i := 1;
  LeafStrFromStr := StringNxtDel(i, sBuf, '>');
end;
//------------------------------------------------------------------------------
// Convert a color to a string
//
function  LeafColorFromStr     (sBuf : string): TColor;
begin
  LeafColorFromStr := StringToColor(sBuf);
end;
//------------------------------------------------------------------------------
// Convert a point to a string
//
function  LeafPointFromStr     (sBuf : string): TPoint;
var
  i,x,y : integer;
  s : string;
  a : boolean;
begin
  a := true;
  s := '';
  x := 0;
  y := 0;

  for i := 1 to length(sBuf) do
    if (sBuf[i] >= '0') and (sBuf[i] <= '9') then
      s := s + sBuf[i]
    else if sBuf[i] = ',' then
      begin
        if a then
          begin
            x := StrToInt(s);
            s := '';
            a := false;
          end
        else
          begin
            y := StrToInt(s);
            s := '';
            break;
          end
      end;

  LeafPointFromStr.X := x;
  LeafPointFromStr.Y := y;
end;
//------------------------------------------------------------------------------
// Convert list of points to a string
//
function  LeafPointListFromStr (sBuf : string; var pBuf : TPointArray) : boolean;
var
  i,x : integer;
  s : string;
  t : integer;
  l : integer;
  e : boolean;
begin
  LeafPointListFromStr := false;
  t := 0;
  s := '';
  l := 0;
  x := 0;
  e := false;

  SetLength(pBuf,0);

  for i := 1 to length(sBuf) do
  begin
    // Look for = to start the value
    if e then
      begin
        if (sBuf[i] >= '0') and (sBuf[i] <= '9') then
          begin
            s := s + sBuf[i]
          end
        else if (sBuf[i] = ',') or (sBuf[i] = '>') then
          begin
            if (t = 0) and (length(s) > 0) then
              begin
                x := StrToInt(s);
                s := '';
                t := 1;
              end
            else if (t = 1) and (length(s) > 0) then
              begin
                // Add this to pBuf

                SetLength(pBuf, l + 1);
                pBuf[l].X := x;
                pBuf[l].Y := StrToInt(s);
                l := l + 1;
                s := '';
                t := 0; // Be ready for next X
                LeafPointListFromStr := true;
              end
            else if (sBuf[i] = '>') then
              begin
                break;
              end;
          end
      end
    else if sBuf[i] = '=' then
      begin
        e := true;
      end
  end;
end;
//------------------------------------------------------------------------------
//                            General Load Functions
//------------------------------------------------------------------------------
// Strip a string to get the object name
//
function LeafGetObjectName  (sBuf : string) : string;
var
  i : integer;
  s : string;
  a : boolean;
begin
  s := '';
  a := true;

  // Syntax <objectname= or <attributename=value> or >

  // Walk input string (sBuf)

  for i := 1 to Length(sBuf) do
    if a and (sBuf[i] = '<') then
      a := false
    else if (sBuf[i] = '=') or (sBuf[i] = '>') then
      break
    else
      s := s + sBuf[i];

  LeafGetObjectName := s;
end;
//------------------------------------------------------------------------------
// Read a value string up until next end (>), also ripp of any "
//
function LeafGetValueStr  (sBuf : string) : string;
var
  i : integer;
  s : string;
  t : boolean;
  l : boolean;
  e : boolean;
begin
  s := '';    // Havent got any output yet
  t := false; // Not inside a strings delimiters
  l := false; // Last char was not a delimiter
  e := false; // Havent found = yet

  // Syntax <attributename="string">

  // Walk input string (sBuf)

  for i := 1 to Length(sBuf) do
  begin
    // Dont start until first =
    if e then
    // First look for string delimiters
    if (sBuf[i] = '"') then
      begin
        // If last char was a delimiter, use it
        if l then
          begin
            s := s + '"';
            l := false;  // By using it are ready for next
          end
        // if inside the delimiter, mark it as last, but dont add it
        else if t then
          begin
            l := true;
          end
        // So this can only be the first
        else
          t := true;
      end
    else
      begin
        // Test for end (>) of value
        if sBuf[i] = '>' then
          begin
            // if inside string, then use it, if outside, we are at end
            if (not t) or l then
              break
            else
              s := s + '>';
          end
        else
          begin
            // Use it
            s := s + sBuf[i];
          end;
        // Mark the last char as not a delimiter
        l := false;
      end
    else if sBuf[i] = '=' then
      e := true;
  end;
  LeafGetValueStr := s;
end;
//------------------------------------------------------------------------------
// Strip a string to get the object name
//
function LeafSkipObject  (var F : TextFile) : boolean;
var
  i    : integer;
  sBuf : string;
  num  : integer;
begin
  LeafSkipObject := false;
  num := 1;

  // Walk input lines untill unmatched >

  while not Eof(F) do
    begin
      // Get the first object

      Readln(F, sBuf); // Syntax : <leaf=attribute> >

      // Look only for < and >

      for i := 1 to length(sBuf) do
        if sBuf[i] = '<' then
          num := num + 1
        else if sBuf[i] = '>' then
          num := num - 1;

      // If we are below 1 then we have skiped the unknown object

      if num < 1 then
        begin
          LeafSkipObject := true;
          exit;
        end;
    end;
end;
end.
