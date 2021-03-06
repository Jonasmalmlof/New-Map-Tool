unit GeomCurve;

interface

uses
  Types;        // TPoint

const
  tolerans_simpel  = 1;
  tolerans_display = 2;
  tolerans_plot    = 3;

  CurveMaxPoints = 100;

  TYPE  TPolyCoeffs  = ARRAY [0..(CurveMaxPoints + 2)] OF REAL;

  //--- Cubic curve ------------------------------------------------------------

  PROCEDURE CubicSpline
            (const pBuf   : Array of TPoint;
             const n      : INTEGER;
             out   b,c,d  : TPolyCoeffs);

  PROCEDURE CubicMakeSpline
            (const coords : Array of TPoint;
             const cLen   : INTEGER;
             const num    : integer;
             out   xmax   : INTEGER;
             out   oLen   : INTEGER);

  FUNCTION CubicEval
            (const pBuf   : Array of TPoint;
             const iter   : INTEGER;
             const pLen   : INTEGER;
             const b,c,d  : TPolyCoeffs): REAL;

  PROCEDURE DrawCubic
            (const coords    : Array of TPoint;
             const cLen      : INTEGER;
             const quality   : integer;
             const OutMax    : integer;
             var   OutPoints : Array of TPoint;
             var   OutLen    : integer);

  //--- BSpline Curve ----------------------------------------------------------

  FUNCTION BSplineKnot
             (const iter : INTEGER) : INTEGER ;

  FUNCTION BSplineBlend
             (const iter,ki : INTEGER;
              const u    : REAL): REAL ;

  PROCEDURE BSplineAdd
              (var    x,y    : REAL;
               const  u      : REAL;
               const  n,ki   : INTEGER;
               const  coords : Array of TPoint);

  PROCEDURE DrawBSpline
            (const coords    : Array of TPoint;
             const c_len     : INTEGER;
             const tol       : INTEGER;
             const OutMax    : integer;
             var   OutPoints : Array of TPoint;
             var   OutLen    : integer);

implementation

var
  // For Cubic

  // Array of the points to calculate

  xp,yp : ARRAY [0..(CurveMaxPoints + 2)] OF TPoint;

  // Array of real

  bx,cx,dx,by,cy,dy : TPolyCoeffs;

  // For bspline

  curve_knotk,
  curve_knotn   : INTEGER;

//------------------------------------------------------------------------------
// Local
//
PROCEDURE CubicSpline
            (const pBuf    : Array of TPoint;
             const n       : INTEGER;
             out   b, c, d : TPolyCoeffs);


VAR
  i  : INTEGER;
  j  : integer;
  k  : integer;
  t  : REAL;
  nm : integer;
BEGIN

  // if less than 2 points its no use

  IF n < 2 THEN
    exit
  else IF n < 3
    THEN
      BEGIN
        // If 2 points just add them

        b[1] := (pBuf[2].Y - pBuf[1].y) /
                (pBuf[2].x - pBuf[1].x);
        c[1] := 0;
        d[1] := 0;
        b[2] := b[1];
        c[2] := 0;
        d[2] := 0;

        exit;
      END;

  nm := n - 1;

  // Set the first line

  d[1] :=  pBuf[2].x - pBuf[1].x;
  c[2] := (pBuf[2].y - pBuf[1].y) / d[1];

  // walk the rest of the lines

  FOR i := 2 TO nm DO
    BEGIN
      j    := i + 1;
      d[i] := pBuf[j].x - pBuf[i].x;
      b[i] := 2*(d[i-1] + d[i]);
      c[j] := (pBuf[j].y - pBuf[i].y) / d[i];
      c[i] := c[j] - c[i];
    END;

  // Calc the first and last

  b[1] := -d[1];
  b[n] := -d[nm];
  c[1] := 0;
  c[1] := 0;

  IF n <> 3 THEN
    BEGIN
      j := n - 2;
      k := n - 3;

      c[1] := c[3]/(pBuf[4].x - pBuf[2].x) -
              c[2]/(pBuf[3].x - pBuf[1].x);

      c[n] := c[nm]/(pBuf[n].x  - pBuf[j].x) -
              c[j] /(pBuf[nm].x - pBuf[k].x);

      c[1] := c[1]*SQR(d[1])/(pBuf[4].x - pBuf[1].x);

      c[n] := c[n]*SQR(d[nm])/(pBuf[n].x - pBuf[k].x)
    END;

  FOR i := 2 TO n DO
    BEGIN
      j    := i - 1;
      t    := d[j] / b[j];
      b[i] := b[i] - t*d[j];
      c[i] := c[i] - t*c[j];
    END;

  c[n] := c[n]/b[n];

  FOR j := 1 TO nm DO
    BEGIN
      i    := n - j;
      c[i] := (c[i] - d[i] * c[i+1]) / b[i];
    END;

  b[n] := (pBuf[n].y - pBuf[nm].y)/d[nm] + d[nm]*(c[nm] + 2*c[n]);

  FOR i := 1 TO nm DO
    BEGIN
      j    := i + 1;
      b[i] := (pBuf[j].y - pBuf[i].y)/d[i] - d[i] * (c[j] + 2*c[i]);
      d[i] := (c[j] - c[i])/d[i];
      c[i] := 3*c[i];
    END;

  c[n] := 3*c[n];
  d[n] := d[nm];

END;
//------------------------------------------------------------------------------
// Local
//
PROCEDURE CubicMakeSpline
  (const coords : Array of TPoint; // Input map points
   const cLen   : INTEGER;         // Input map points number
   const num    : integer;         // Quality
   out   xmax   : INTEGER;         // Max number
   out   oLen   : INTEGER);        // Number of output reals
VAR
  i      : INTEGER;
BEGIN

  oLen := 0; // Nothing yet

  // Walk all coords in map buffer

  FOR i := 0 TO cLen - 1 DO
    begin
      // Always take the first point
      // Don't take next point if its the same as last

      if (i = 0) or ((coords[i].x <> coords[i-1].x) or
                     (coords[i].y <> coords[i-1].y)) then
        BEGIN
          xmax := num * (i+1);

          // Add to output Points buffer

          oLen := oLen + 1;

          xp[oLen].x := xmax;
          xp[oLen].y := coords[i].x;

          yp[oLen].x := xmax;
          yp[oLen].y := coords[i].y;

        END;
    end;

  CubicSpline (xp, oLen, bx, cx, dx); // Calc X real buffers
  CubicSpline (yp, oLen, by, cy, dy); // Calc Y real buffers

  END;
//------------------------------------------------------------------------------
// Local
//
FUNCTION CubicEval
            (const pBuf   : Array of TPoint;
             const iter   : INTEGER;
             const pLen   : INTEGER;
             const b,c,d  : TPolyCoeffs): REAL;
VAR
  dxx,i,j,k : INTEGER;
BEGIN

  i := 1;

  // Test this iteration against first and next point

  if (iter < pBuf[i].x) or (iter > pBuf[i+1].x) then
    BEGIN
      i := 1;
      j := pLen + 1;
      REPEAT
        k := (i + j) DIV 2;

        IF (iter < pBuf[k].x) THEN
          j := k
        else
          i := k;

      UNTIL j <= i + 1
    END;

  dxx := iter - pBuf[i].x;

  CubicEval := pBuf[i].y + dxx*(b[i] + dxx*(c[i] + dxx*d[i]));
END;
//------------------------------------------------------------------------------
// Main procedure for drawing Cubic curve
//
PROCEDURE DrawCubic
            (const coords    : Array of TPoint;
             const cLen      : INTEGER;
             const quality   : integer;
             const OutMax    : integer;
             var   OutPoints : Array of TPoint;
             var   OutLen    : integer);

var
  iter : integer; // Index for iteration when calculating output
  xmax : integer; // Max iterations
  oLen : INTEGER; // Number of points in buffer
  x,y  : REAL;    // real point
  num  : integer; // Start iteration
BEGIN
  OutLen := 0;

  // Must at least be two points

  IF cLen < 2 THEN
    exit;

  // If two not the same point... please

  IF (cLen = 2) THEN
    if (coords[0].x = coords[1].x) and (coords[0].y = coords[1].y)
      THEN exit;

  {-- decide number of lines to draw --}

  num := quality;

  // Compute polynome coeffients

  CubicMakeSpline (coords, cLen, num, xmax, oLen);

  // Iterate the result

  FOR iter := num TO xmax DO
    BEGIN

      // Calculate next point

      x := CubicEval (xp, iter, oLen, bx, cx, dx);
      y := CubicEval (yp, iter, oLen, by, cy, dy);
      // Add pos to output buffer

      if OutLen < OutMax then
        begin
              OutPoints[OutLen].X := ROUND(x);
              OutPoints[OutLen].Y := ROUND(y);
              OutLen := OutLen + 1;
        end
      else
        begin
          // Exeeded the output buffer length
          Exit;
        end;
    END;
         
END;
//------------------------------------------------------------------------------
//                              BSpline Curve
//------------------------------------------------------------------------------
// Local procedure
//
FUNCTION BSplineKnot
             (const iter : INTEGER) : INTEGER ;
BEGIN
 
  IF iter < curve_knotK
    THEN
      begin
        BSplineKnot := 0
      end
    ELSE
      begin
        IF iter > curve_KnotN
          THEN
            BSplineKnot := curve_KnotN - curve_knotK + 2
          ELSE
            BSplineKnot := iter - curve_knotK + 1;
      end
END;
//------------------------------------------------------------------------------
// Local procedure
//
FUNCTION BSplineBlend
             (const iter, ki : INTEGER;
              const u        : REAL): REAL ;
VAR
  t : integer;
  v : real;
BEGIN
  IF ki = 1
    THEN
      BEGIN
        v := 0;
        IF (BSplineKnot(iter) <= u) AND
           (u < BSplineKnot(iter+1))
          THEN
            v := 1
      END
    ELSE
      BEGIN
        v := 0;
        t := BSplineKnot(iter+ki-1) -
             BSplineKnot(iter);
        IF t <> 0
          THEN
            v := (u-BSplineKnot(iter))*
                    BSplineBlend(iter,ki-1,u)/t;

        t := BSplineKnot(iter+ki) -
             BSplineKnot(iter+1);
        IF t <> 0
          THEN v := v + (BSplineKnot(iter+ki)-u)*
                         BSplineBlend(iter+1,ki-1,u)/t;
      END;
  BSplineBlend := v;
END;
//------------------------------------------------------------------------------
// Local procedure
//
PROCEDURE BSplineAdd
              (var   x,y    : REAL;
               const u      : REAL;
               const n,ki   : INTEGER;
               const coords : Array of TPoint);
VAR
  iter : INTEGER;
  b : REAL;
BEGIN

  IF u >= (n-ki+2)
    THEN
      BEGIN
        x := coords[n].x;
        y := coords[n].y;
        exit;
      END;

  curve_knotk := ki;
  curve_knotn := n;

  x := 0.0;
  y := 0.0;

  FOR iter := 0 TO n DO
    BEGIN
      b := BSplineBlend(iter,ki,u);
      x := x + coords[iter].x * b;
      y := y + coords[iter].y * b;
    END;
end;
//------------------------------------------------------------------------------
// Draw a bSpline curve
//
  PROCEDURE DrawBSpline
            (const coords    : Array of TPoint;
             const c_len     : INTEGER;
             const tol       : INTEGER;
             const OutMax    : integer;
             var   OutPoints : Array of TPoint;
             var   OutLen    : integer);
VAR
  i,n,ki,k   : INTEGER;
  x,y              : REAL;
  pos              : TPoint;
BEGIN
  k := 400;
  n := c_len * 2;
  OutLen := 0;
  curve_knotk := 0;
  curve_knotn := 0;

  {-- decide number of lines to draw --}
                
  {case tol of
    tolerans_simpel  : n := c_len * 18;
    tolerans_display : n := c_len * 36;
    tolerans_plot    : n := c_len * 108;
  end; }

  ki := ROUND(k/100);
                
  FOR i := 0 TO n DO
    BEGIN
          
      {-- get coord --}

      BSplineAdd (x, y, (i/n)*(c_len-ki+1), c_len - 1, ki, coords);

      pos.x := ROUND(x);
      pos.y := ROUND(y);

      {-- add pos to path --}

      if OutLen < OutMax then
        begin
          OutPoints[OutLen] := pos;
          OutLen := OutLen + 1;
        end
      else
        Exit;

    END;

END;
end.
