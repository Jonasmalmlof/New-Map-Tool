//------------------------------------------------------------------------------
//
// All functions that handles all Map Items Types in current map
//
// Cre 2004-02-17 Pma
//
//------------------------------------------------------------------------------
unit MapItemTypeList;

interface

uses
  SysUtils, // String conversions used
  Types,    // TPoint
  Classes,  // TList

  LeafUnit,     // Save/Loading
  MapItemType;  // TMapItemType

const
  // Save/Load

  LeafItemType = 0;

  // function used when sorting item types in TList

  function SortItems (Item1, Item2: Pointer): Integer;

type

  TMapItemTypeList = class(TList)
  private
    DefaultIndex : integer; // Index of the default type
  public

    //--- Constructors and destructors -----------------------------------------

    constructor Create;  overload;
    destructor  Free;    overload;

    //--- Loading and Saving of item types -------------------------------------

    // Save all item types in list

    function  SaveToFile   (var F : TextFIle) : boolean;

    // Loading all Item Types in a file

    function  LoadFromFile (var F : TextFile) : boolean;

    // Clear all item types (before loading a new map)

    procedure ClearAll;

    //--- General functions ----------------------------------------------------

    // Add a new item type using name and geometry

    function  Add (name   : string; gt : TMapItemGeometry):
                                          TMapItemType; Overload;

    // Return a item type using a name (Name can't be same)

    function  GetItemType (name : string): TMapItemType;

    // Return the default item type (last one used)

    function  GetDefaultType : TMapItemType;

    // Set new default type

    procedure SetDefaultType (it : TMapItemType);

    // Set all item types to the same visible state

    procedure SetVisibleAll (visible : boolean);

  end;

implementation

var
  LeafsItemTypeList : TLeafRecordArray; // Save / Load Item Types

//------------------------------------------------------------------------------
//                    Construction and destruction
//------------------------------------------------------------------------------
// Construct
//
constructor TMapitemTypeList.Create;
begin
  inherited Create;

  // Set the default index to nil

  DefaultIndex := -1;
end;
//------------------------------------------------------------------------------
// Destructor
//
destructor TMapitemTypeList.Free;
begin
  // Clear all item types

  ClearAll;
  inherited Free;
end;
//------------------------------------------------------------------------------
//                          Loading and Saving
//------------------------------------------------------------------------------
// Save this item type to file
//
function TMapitemTypeList.SaveToFile (var F : TextFIle) : boolean;
var
  i : integer;
  it : TMapItemType;
begin
  SaveToFile := true;

  { Save semantics
    The Calling function will wrap it into itemtypelist

    for each item type do

    <itemtype=
    ... item types attributes
    >

  }

  for i := 0 to Count - 1 do
    begin
      it := Items[i];
      if it <> nil then
        begin
          // Put the header

          WriteLn(F, '<' + LeafGetName(LeafsItemTypeList,LeafItemType) + '=');

          // Save the item type

          it.SaveToFile(F);

          // Put the end

          WriteLn(F, '>');

        end;
    end;
end;
//------------------------------------------------------------------------------
// Load this item from to file
//
function TMapitemTypeList.LoadFromFile (var F : TextFIle) : boolean;
var
  sBuf : string;
  id   : integer;
  it   : TMapItemType;
begin
  LoadFromFile := false;

  while not Eof(F) do
    begin
      // Get the first object

      Readln(F, sBuf); // Syntax : <objectname=

      id := LeafGetId(LeafsItemTypeList, LeafGetObjectName(sBuf));
      case id of
        LeafObjectAtEnd  : break;
        LeafItemType :
          begin
            // Create the object, load it from file, and add it to list
            it := TMapItemType.Create;
            it.LoadFromFile(F);
            Add(it);
          end;
      else
        // Unknown object, skip it
        LeafSkipObject(F);
      end;
    end;
end;
//------------------------------------------------------------------------------
// Add a new Item Type, return the type
//
procedure TMapitemTypeList.ClearAll;
var
  i : integer;
  it : TMapItemType;
begin

  // Remove all item types and free then

  // NOTE, make sure all items are removed also
  // otherwise ther will be dangling pointers.

  for i := 0 to Count - 1 do
    begin
      it := Items[i];
      if it <> nil then
        it.Free;
    end;

  // Set no default things

  DefaultIndex := -1;

end;
//------------------------------------------------------------------------------
//                             General functions
//------------------------------------------------------------------------------
// Add a new Item Type, return the type
//
function TMapitemTypeList.Add(name:string;gt:TMapItemGeometry):TMapItemType;
var
  i  : integer;
  it : TMapItemType;
begin

  // Test if it already exist and return it

  for i := 0 to Count - 1 do
    begin
      it := Items[i];
      if it <> nil then
        if CompareStr(it.InqName(), name) = 0 then
          begin
            // return this item type and exit

            Add := it;
            exit;
          end;
    end;

  // Wasn't found, add it as new and return it

  it := TMapItemType.Create(name, gt);
  Add (it);

  // Sort all the items in TList

  Sort(@SortItems);

  // Return with new Item Type

  Add := it;
end;
//------------------------------------------------------------------------------
// Add a new Item Type, return the type
//
function TMapitemTypeList.GetItemType(name : string): TMapItemType;
var
  i  : integer;
  it : TMapItemType;
begin
  GetItemType := nil;

  // Test if it already exist and return it

  for i := 0 to Count - 1 do
    begin
      it := Items[i];
      if it <> nil then
        if StrComp(PAnsiChar(it.InqName()), PAnsiChar(name)) = 0 then
          begin
            GetItemType := it;
            exit;
          end;
    end;
end;
//------------------------------------------------------------------------------
// Add a new Item Type, return the type
//
function TMapitemTypeList.GetDefaultType: TMapItemType;
begin

  // If no types yet, just add one. Use the first always

  if Count = 0 then
    Add ('New Type',gtPoint);

  // if DefaultIndex is set use it if its within index

  if (DefaultIndex >= 0) and (DefaultIndex < Count) then
    GetDefaultType := Items[DefaultIndex]
  else
    GetDefaultType := Items[0];
end;
//------------------------------------------------------------------------------
// Set a new Item Type as default
//
procedure TMapitemTypeList.SetDefaultType (it : TMapItemType);
var
  ind : integer;
begin
  ind := IndexOf(it);
  if (ind >= 0) and (ind < Count) then
    DefaultIndex := ind
  else
    DefaultIndex := -1;
end;
//------------------------------------------------------------------------------
// Set all item types to the same visibility
//
procedure TMapitemTypeList.SetVisibleAll (visible : boolean);
var
  i  : integer;
  it : TMapItemType;
begin

  // Test if it already exist and return it

  for i := 0 to Count - 1 do
    begin
      it := Items[i];
      if it <> nil then
        it.SetVisible(visible);
    end;
end;
//------------------------------------------------------------------------------
// Sort function for items
//
function SortItems (Item1, Item2: Pointer): Integer;
begin
  Result := CompareText(TMapItemType(Item2).InqName(),
                        TMapItemType(Item1).InqName());
end;

initialization

  // Add all necessary leafs for this object

  LeafAdd (LeafsItemTypeList, LeafItemType, 'ItemType', atString);

end.
