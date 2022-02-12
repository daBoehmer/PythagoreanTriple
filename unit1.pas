UNIT Unit1;

{$mode objfpc}{$H+}
{$WARN 5057 off : Local variable "$1" does not seem to be initialized}
{$WARN 5089 off : Local variable "$1" of a managed type does not seem to be initialized}
INTERFACE

USES
Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ActnList,
ExtCtrls, Grids, omv, typ, math, DateUtils;

TYPE

{ TForm1 }

TForm1 = CLASS(TForm)
  btnStartGenerating: TButton;
  btnExit: TButton;
  cbSort: TCheckBox;
  GroupBox1: TGroupBox;
  GroupBox2: TGroupBox;
  GroupBox3: TGroupBox;
  gbOperations: TGroupBox;
  GroupBox4: TGroupBox;
  labEd_upperLimit: TLabeledEdit;
  labEd_lowerLimit: TLabeledEdit;
  labSortBy: TLabel;
  labOperations: TLabel;
  labTimePassed: TLabel;
  radBtn_PrimOnly: TRadioButton;
  radBtn_All: TRadioButton;
  radBtn_sortA: TRadioButton;
  radBtn_sortB: TRadioButton;
  radBtn_sortC: TRadioButton;
  strGrid: TStringGrid;
  PROCEDURE btnExitClick(Sender: TObject);
  PROCEDURE btnStartGeneratingClick(Sender: TObject);
  PROCEDURE cbSortChange(Sender: TObject);
  PROCEDURE FormCreate(Sender: TObject);
private

public

END;

VAR
Form1: TForm1;

IMPLEMENTATION

{$R *.lfm}
TYPE
  TVector = array[1..3] of ArbFloat;
  TVectorArray = array of TVector;
  TripleIndices = (a := 1, b, c);

  TRecursionThread = class(TThread)
    PRIVATE
      startTriple:TVector;
    PROTECTED
      PROCEDURE Execute; override;
    PUBLIC
      CONSTRUCTOR Create(startingTriple:TVector; CreateSuspended:BOOLEAN=TRUE); overload;
  END;

  TThreadList = array of TRecursionThread;

CONSTRUCTOR TRecursionThread.Create(
  startingTriple:TVector;
  CreateSuspended:BOOLEAN=TRUE
  );
BEGIN
  FreeOnTerminate:=TRUE;
  INHERITED Create(CreateSuspended);
  startTriple := startingTriple;
END;

CONST
  Matrix_A: array[1..3, 1..3] of ArbFloat = (
  (1, -2, 2),
  (2, -1, 2),
  (2, -2, 3)
  );
  Matrix_B: array[1..3, 1..3] of ArbFloat= (
  (1, 2, 2),
  (2, 1, 2),
  (2, 2, 3)
  );
  Matrix_C: array[1..3, 1..3] of ArbFloat = (
  (-1, 2, 2),
  (-2, 1, 2),
  (-2, 2, 3)
  );
  MaxInteger = 2147483647;

  G_ThreadAmount = 27;

VAR
  TRIPLES: TVectorArray;
  G_upperLimit, G_lowerLimit: INTEGER;
  G_timeStart: TDateTime;
  G_SortingIndex:BYTE;
  G_GenerationIsRunning: BOOLEAN;

{ TMyApplication }

FUNCTION addTVectors(a, b:TVector):TVector;
VAR
  c:TVECTOR;
BEGIN
  c[1] := a[1] + b[1];
  c[2] := a[2] + b[2];
  c[3] := a[3] + b[3];
  addTVectors := c;
END;

PROCEDURE Swap(VAR a, b:TVector);
VAR
  cache:TVector;
BEGIN
  cache := a;
  a := b;
  b := cache;
END;

FUNCTION partialSort(low, high:INTEGER):INTEGER;
// Does one iteration of quicksort on the given interval
//      (from index low to index high)
VAR
  pivot:TVector;
  low_cache, high_cache:INTEGER;
BEGIN
  pivot := TRIPLES[high];
  low_cache := low;
  high_cache := high;

  WHILE low < high DO BEGIN
      WHILE (high > low_cache) AND
            (TRIPLES[high, G_SortingIndex] >= pivot[G_SortingIndex]) DO
                high := high - 1;
      WHILE (low < high_cache) AND
            (TRIPLES[low, G_SortingIndex] < pivot[G_SortingIndex]) DO
                 low := low + 1;
      IF low < high THEN
         Swap(TRIPLES[low], TRIPLES[high]);
      // else the outter while loop breaks
  END;
  IF TRIPLES[low,G_SortingIndex] > pivot[G_SortingIndex] THEN
     Swap(TRIPLES[high_cache], TRIPLES[low]);

  partialSort := low;
END;

PROCEDURE QuicksortTriples(low:INTEGER = 0; high:INTEGER = MaxInteger);
VAR
  pivot:INTEGER;
BEGIN
  IF high = MaxInteger THEN
     high := Length(TRIPLES)-1;
  IF low < high THEN BEGIN
     pivot := partialSort(low, high);
     quicksortTriples(low, pivot-1);
     quicksortTriples(pivot+1, high);
  END;
END;

PROCEDURE genTriples(triple: TVector);
VAR
  pA, pB, pC: TVector;
BEGIN
  omvmmv(Matrix_A[1,1], 3, 3, 3,
    triple[1], pA[1]);
  omvmmv(Matrix_B[1,1], 3, 3, 3,
    triple[1], pB[1]);
  omvmmv(Matrix_C[1,1], 3, 3, 3,
    triple[1], pC[1]);

  IF pA[3] <= G_upperLimit THEN BEGIN
     IF pA[3] >= G_lowerLimit THEN BEGIN
       SetLength(TRIPLES, Length(TRIPLES)+1);
       TRIPLES[Length(TRIPLES)-1] := pA;
     END;
     genTriples(pA);
  END;

  IF pB[3] <= G_upperLimit THEN BEGIN
     IF pB[3] >= G_lowerLimit THEN BEGIN
       SetLength(TRIPLES, Length(TRIPLES)+1);
       TRIPLES[Length(TRIPLES)-1] := pB;
     END;
     genTriples(pB);
  END;

  IF pC[3] <= G_upperLimit THEN BEGIN
     IF pC[3] >= G_lowerLimit THEN BEGIN
       SetLength(TRIPLES, Length(TRIPLES)+1);
       TRIPLES[Length(TRIPLES)-1] := pC;
     END;
    genTriples(pC);
  END;
END;


PROCEDURE TRecursionThread.Execute;
BEGIN
  genTriples(startTriple);
END;

FUNCTION roundXDigits(nr:ArbFloat; digits:BYTE):ArbFloat;
BEGIN
  Result := (round(nr*math.Power(10, digits))/math.Power(10, digits));
END;

PROCEDURE MakeOutputs;
VAR
  i:INTEGER;
BEGIN
  Form1.strGrid.RowCount := Length(TRIPLES)+1;
  FOR i:=0 TO Length(TRIPLES)-1 DO BEGIN
      Form1.strGrid.Cells[0,i+1] := IntToStr(i+1);
      Form1.strGrid.Cells[1,i+1] := FloatToStr(TRIPLES[i,1]);
      Form1.strGrid.Cells[2,i+1] := FloatToStr(TRIPLES[i,2]);
      Form1.strGrid.Cells[3,i+1] := FloatToStr(TRIPLES[i,3]);
      Form1.strGrid.Cells[4,i+1] := (
      FloatToStr(sqr(TRIPLES[i,1])) + ' + ' + FloatToStr(sqr(TRIPLES[i,2])) +
      ' = ' + FloatToStr(sqr(TRIPLES[i,3]))
      );
  END;
  Form1.labOperations.Caption:=IntToStr(Length(TRIPLES));
  Form1.labTimePassed.Caption:=FloatToStr(roundXDigits(SecondSpan(Now, G_timeStart), 3)) + 's';
END;

PROCEDURE StartGenPrim;
VAR
  smallestPrimTriple: TVector;
BEGIN
  smallestPrimTriple[1] := 3;
  smallestPrimTriple[2] := 4;
  smallestPrimTriple[3] := 5;

  IF (smallestPrimTriple[3] >= G_lowerLimit)
     AND (smallestPrimTriple[3] <= G_upperLimit) THEN BEGIN
      SetLength(TRIPLES, 1);
      TRIPLES[0] := smallestPrimTriple;
     END;
  genTriples(smallestPrimTriple);
END;


PROCEDURE GenPrimTripleTree(triple: TVector; depth: BYTE);
VAR
  pA, pB, pC: TVector;
BEGIN
  IF depth > 0 THEN BEGIN
    omvmmv(Matrix_A[1,1], 3, 3, 3,
      triple[1], pA[1]);
    omvmmv(Matrix_B[1,1], 3, 3, 3,
      triple[1], pB[1]);
    omvmmv(Matrix_C[1,1], 3, 3, 3,
      triple[1], pC[1]);

    SetLength(TRIPLES, Length(TRIPLES)+3);
    TRIPLES[Length(TRIPLES)-3] := pA;
    TRIPLES[Length(TRIPLES)-2] := pB;
    TRIPLES[Length(TRIPLES)-1] := pC;
    GenPrimTripleTree(pA, depth-1);
    GenPrimTripleTree(pB, depth-1);
    GenPrimTripleTree(pC, depth-1);
  END;
END;

PROCEDURE StartGenPrimMultiThreaded;
// Taking information from
// https://en.wikipedia.org/wiki/Tree_of_primitive_Pythagorean_triples#/media/File:Berggrens's_tree_with_reordered_path_keys.svg
// tree depth 1
VAR
  bufferVector: TVector;
  threadList: TThreadList;
  i:BYTE;
BEGIN

  bufferVector[1] := 3;
  bufferVector[2] := 4;
  bufferVector[3] := 5;

  SetLength(TRIPLES, 1);
  TRIPLES[0] := bufferVector;

  GenPrimTripleTree(TRIPLES[0], math.Floor(math.LogN(3, G_ThreadAmount)));

  SetLength(threadList, round(Math.Power(3, math.Floor(math.LogN(3, G_ThreadAmount)))));

  FOR i:=0 TO Length(threadList)-1 DO BEGIN
      threadList[i] := TRecursionThread.Create(TRIPLES[Length(TRIPLES)-1-i]);
  END;

  FOR i:=0 TO Length(threadList)-1 DO BEGIN
      threadList[i].Execute;
  END;

  FOR i:=0 TO Length(threadList)-1 DO BEGIN
      WaitForThreadTerminate(threadList[i].ThreadID, MaxInteger);
  END;

  FOR i:=0 TO Length(threadList)-1 DO BEGIN
      threadList[i].Terminate;
  END;

END;

PROCEDURE StartGenAll;
VAR
  i, j:INTEGER;
  newTriples:TVectorArray;
  tempTriple:TVector;
BEGIN
  StartGenPrimMultiThreaded;
  FOR i:=0 TO Length(TRIPLES)-1 DO BEGIN
      tempTriple := TRIPLES[i];
      SetLength(newTriples, Length(newTriples)+1);
      newTriples[Length(newTriples)-1] := tempTriple;
      FOR j:=1 TO (G_upperLimit DIV round(TRIPLES[i, 3]))-1 DO BEGIN
          tempTriple := addTVectors(tempTriple, TRIPLES[i]);
          SetLength(newTriples, Length(newTriples)+1);
          newTriples[Length(newTriples)-1] := tempTriple;
      END;
  END;
  FOR i:=0 TO Length(newTriples)-1 DO BEGIN
      SetLength(newTriples, Length(newTriples)+1);
      tempTriple[1] := newTriples[i, 2];
      tempTriple[2] := newTriples[i, 1];
      tempTriple[3] := newTriples[i,3];
      newTriples[Length(newTriples)-1] := tempTriple;
  END;
  TRIPLES := newTriples;
END;

{ TForm1 }

PROCEDURE TForm1.btnExitClick(Sender: TObject);
BEGIN

  Form1.Close;
end;

PROCEDURE TForm1.btnStartGeneratingClick(Sender: TObject);
BEGIN
  IF NOT G_GenerationIsRunning THEN BEGIN;
    G_GenerationIsRunning:=TRUE;
    G_timeStart := Now;
    G_SortingIndex:=Ord(TripleIndices.a);
    G_upperLimit := StrToInt(Form1.labEd_upperLimit.Caption);
    G_lowerLimit := StrToInt(Form1.labEd_lowerLimit.Caption);

    TRIPLES := [];

    IF Form1.cbSort.Checked THEN BEGIN
      IF Form1.radBtn_sortA.Checked THEN G_SortingIndex:=Ord(TripleIndices.a)
      ELSE IF Form1.radBtn_sortB.Checked THEN G_SortingIndex:=Ord(TripleIndices.b)
      ELSE IF Form1.radBtn_sortC.Checked THEN G_SortingIndex:=Ord(TripleIndices.c);
    END
    ELSE G_SortingIndex:=0;

    IF Form1.radBtn_PrimOnly.Checked THEN StartGenPrimMultiThreaded
    ELSE IF Form1.radBtn_All.Checked THEN StartGenAll;

    IF G_SortingIndex > 0 THEN QuicksortTriples;
    MakeOutputs;
    G_GenerationIsRunning:=FALSE;
  END;
end;

PROCEDURE TForm1.cbSortChange(Sender: TObject);
BEGIN
  IF Form1.cbSort.Checked THEN BEGIN
     Form1.labSortBy.Visible:=TRUE;
     Form1.radBtn_sortA.Visible:=TRUE;
     Form1.radBtn_sortB.Visible:=TRUE;
     Form1.radBtn_sortC.Visible:=TRUE;
  END
  ELSE BEGIN
     Form1.labSortBy.Visible:=FALSE;
     Form1.radBtn_sortA.Visible:=FALSE;
     Form1.radBtn_sortB.Visible:=FALSE;
     Form1.radBtn_sortC.Visible:=FALSE;
  END;
end;

PROCEDURE TForm1.FormCreate(Sender: TObject);
BEGIN
  G_GenerationIsRunning:=FALSE;
end;

END.
