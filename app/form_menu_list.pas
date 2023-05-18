(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit form_menu_list;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  LclType, LclProc,
  ExtCtrls, Buttons,
  ATStringProc,
  ATSynEdit,
  ATSynEdit_Globals,
  ATListbox,
  ATButtons,
  proc_globdata,
  proc_colors,
  Math;

type
  TAppListSelectEvent = procedure(AIndex: integer; const AStr: string) of object;

type
  { TfmMenuList }

  TfmMenuList = class(TForm)
    ButtonCancel: TATButton;
    List: TATListbox;
    plCaption: TPanel;
    procedure ButtonCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure ListDrawItem(Sender: TObject; C: TCanvas; AIndex: integer;
      const ARect: TRect);
    procedure ListClick(Sender: TObject);
  private
    FColorBg: TColor;
    FColorBgSel: TColor;
    FColorFont: TColor;
    FColorFontSel: TColor;
    FColorFontAlt: TColor;
    FOnListSelect: TAppListSelectEvent;
    procedure SetListCaption(const AValue: string);
    procedure DoListChangedSel(Sender: TObject);
    procedure UpdateColors;
    { private declarations }
  public
    { public declarations }
    InitialItemIndex: integer;
    ResultIndex: integer;
    Items: TStringlist;
    CloseOnCtrlRelease: boolean;
    TextHint: String;
    property OnListSelect: TAppListSelectEvent read FOnListSelect write FOnListSelect;
  end;

var
  fmMenuList: TfmMenuList;

implementation

{$R *.lfm}

{ TfmMenuList }

procedure TfmMenuList.FormShow(Sender: TObject);
begin
  SetListCaption(Caption);
  UpdateFormOnTop(Self);
  List.VirtualItemCount:= Items.Count;
  List.ItemIndex:= InitialItemIndex;
  ButtonCancel.Width:= ButtonCancel.Height;
  list.UpdateItemHeight;
  Height := List.BorderSpacing.Around * 2 + Min(list.VirtualItemCount, 10) * List.ItemHeight;
  Top := Top + 6;
end;

procedure TfmMenuList.ListDrawItem(Sender: TObject; C: TCanvas; AIndex: integer;
  const ARect: TRect);
var
  pnt: TPoint;
  str1, str2: string;
  NColorFont, NColorBack: TColor;
begin
  if (AIndex<0) or (AIndex>=Items.Count) then exit;
  SSplitByChar(Items[AIndex], #9, str1, str2);

  if AIndex=List.ItemIndex then
  begin
    NColorFont:= FColorFontSel;
    NColorBack:= FColorBgSel;
  end
  else
  begin
    NColorFont:= FColorFont;
    NColorBack:= FColorBg;
  end;

  c.Brush.Color:= NColorBack;
  c.Pen.Color:= NColorBack;
  c.Font.Color:= NColorFont;
  c.FillRect(ARect);

  pnt:= Point(ARect.Left+4, ARect.Top+list.Font.Size div 2 -3);
  c.TextOut(pnt.x, pnt.y, str1);

  c.Font.Color:= FColorFontAlt;
  c.TextOut(ARect.Right-c.TextWidth(str2)-4, pnt.y, str2);
end;

procedure TfmMenuList.ListClick(Sender: TObject);
begin
  ResultIndex:= List.ItemIndex;
  Close;
end;

procedure TfmMenuList.UpdateColors;
begin
  FColorBg:= GetAppColor(apclListBg);
  FColorBgSel:= GetAppColor(apclListSelBg);
  FColorFont:= GetAppColor(apclListFont);
  FColorFontSel:= GetAppColor(apclListSelFont);
  FColorFontAlt:= GetAppColor(apclListFontHotkey);

  self.Color:= FColorBg;
  List.Color:= FColorBg;
end;

procedure TfmMenuList.FormCreate(Sender: TObject);
begin
  //if UiOps.ShowMenuDialogsWithBorder then
  //  BorderStyle:= bsDialog;


  List.DoubleBuffered:= UiOps.DoubleBuffered;

  UpdateColors;

  plCaption.Height:= ATEditorScale(26);
  plCaption.Font.Name:= UiOps.VarFontName;
  plCaption.Font.Size:= ATEditorScaleFont(UiOps.VarFontSize);
  plCaption.Font.Color:= GetAppColor(apclListFont);

  Width := ATEditorScale(UiOps.ListboxSizeX);
  //self.Height:= ATEditorScale(UiOps.ListboxSizeY);

  list.Font.Name:= EditorOps.OpFontName;
  list.Font.Size:= ATEditorScaleFont(UiOps.VarFontSize);
  list.Font.Quality:= EditorOps.OpFontQuality;
  List.OnChangedSel:= @DoListChangedSel;
  List.ItemHeight := ATEditorScale(list.Font.Size+list.Font.Size + 6);

  Items:= nil;
  ResultIndex:= -1;
end;

procedure TfmMenuList.FormDeactivate(Sender: TObject);
begin
  ModalResult:= mrCancel;
end;

procedure TfmMenuList.ButtonCancelClick(Sender: TObject);
begin
  ModalResult:= mrCancel;
end;


procedure TfmMenuList.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_DOWN) or
    ((Key=VK_TAB) and (Shift=[ssCtrl])) or
    ((Key=VK_J) and (Shift=[ssCtrl])) then
  begin
    if List.ItemIndex=List.ItemCount-1 then
      List.ItemIndex:= 0
    else
      List.ItemIndex:= List.ItemIndex+1;
    key:= 0;
    exit;
  end;

  if (Key=VK_UP) or
   ((Key=VK_TAB) and (Shift=[ssCtrl, ssShift])) or
   ((Key=VK_K) and (Shift=[ssCtrl])) then
  begin
    if List.ItemIndex=0 then
      List.ItemIndex:= List.ItemCount-1
    else
      List.ItemIndex:= List.ItemIndex-1;
    key:= 0;
    exit;
  end;

  if (key=VK_HOME) and (Shift=[ssCtrl]) then
  begin
    List.ItemIndex:= 0;
    key:= 0;
    exit;
  end;

  if (key=VK_END) and (Shift=[ssCtrl]) then
  begin
    List.ItemIndex:= List.ItemCount-1;
    key:= 0;
    exit;
  end;

  if (key=VK_PRIOR) and (Shift=[]) then
  begin
    List.ItemIndex:= Max(0, List.ItemIndex-List.VisibleItems);
    key:= 0;
    exit;
  end;

  if (key=VK_NEXT) and (Shift=[]) then
  begin
    List.ItemIndex:= Min(List.ItemCount-1, List.ItemIndex+List.VisibleItems);
    key:= 0;
    exit;
  end;

  if key=VK_ESCAPE then
  begin
    Close;
    key:= 0;
    exit;
  end;

  if key=VK_RETURN then
  begin
    if (List.ItemIndex>=0) and (List.ItemCount>0) then
    begin
      ResultIndex:= List.ItemIndex;
      Close;
    end;
    key:= 0;
    exit;
  end;
end;

procedure TfmMenuList.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if CloseOnCtrlRelease and (Key=VK_CONTROL) then
  begin
    Key:= 0;
    ResultIndex:= List.ItemIndex;
    Close;
  end;
end;

procedure TfmMenuList.SetListCaption(const AValue: string);
begin
  if UiOps.ShowMenuDialogsWithBorder then
  begin
    Caption:= AValue;
    plCaption.Hide;
  end
  else
  begin
    plCaption.Caption:= AValue;
  end;
end;

procedure TfmMenuList.DoListChangedSel(Sender: TObject);
var
  N: integer;
  S: string;
begin
  N:= List.ItemIndex;
  if (N>=0) and (N<Items.Count) then
    if Assigned(FOnListSelect) then
    begin
      if N>0 then
        S:= Items[N]
      else
        S:= '';
      FOnListSelect(N, S);
      UpdateColors;
      List.Invalidate;
    end;
end;

end.
