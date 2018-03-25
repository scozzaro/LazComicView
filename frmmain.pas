{
 ***************************************************************************
 *                                                                         *
 *  This software created by Vincenzo Scozzaro for read manga for Mac OSX  *
 *                                                                         *
 ***************************************************************************
}
unit frmmain;

{$MODE Delphi}

interface

uses
  SysUtils, Classes, Controls, Forms, LazFileUtils, LazUTF8, thumbcontrol,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ActnList, Menus, LCLType, Buttons,
  Graphics, Spin, frmabout,
  fpreadtiff {adds TIFF format read support to TImage}, threadedimageLoader, Types;

type

  { TMainForm }

  TMainForm = class(TForm)
    BitBtn1: TBitBtn;
    btnPrerior: TBitBtn;
    btnNext: TBitBtn;
    btnPlay: TBitBtn;
    btnStop: TBitBtn;
    BtnAumeta: TBitBtn;
    btnDim: TBitBtn;
    BtnUgualeWidth: TBitBtn;
    BtnUgualeHeight: TBitBtn;
    D1: TMenuItem;
    imgOrign: TImage;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenFolderImage: TMenuItem;
    MIHalfSize: TMenuItem;
    MImage: TMenuItem;
    MINextImage: TMenuItem;
    N2: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PreviousImage1: TMenuItem;
    spinTime: TSpinEdit;
    SpinStep: TSpinEdit;
    Splitter1: TSplitter;
    ThumbControl1: TThumbControl;
    ToolBar1: TToolBar;
    SPImage: TSplitter;
    ILMain: TImageList;
    ODImage: TOpenDialog;
    PImage: TPanel;
    ScrollBox: TScrollBox;
    IMain: TImage;
    ToolButton1: TToolButton;
    ToolButton4: TToolButton;
    ToolButton3: TToolButton;
    OpenDialog1: TOpenDialog;

    {$IFDEF DARWIN}
    AppMenu: TMenuItem;
    AppAboutCmd: TMenuItem;
    AppSep1Cmd: TMenuItem;
    AppPrefCmd: TMenuItem;
    {$ENDIF}

    procedure BitBtn1Click(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnPreriorClick(Sender: TObject);

    procedure btnPlayClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure BtnAumetaClick(Sender: TObject);
    procedure btnDimClick(Sender: TObject);
    procedure BtnUgualeHeightClick(Sender: TObject);
    procedure BtnUgualeWidthClick(Sender: TObject);
    procedure D1Click(Sender: TObject);
    procedure D1DrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
    procedure D1MeasureItem(Sender: TObject; ACanvas: TCanvas; var AWidth, AHeight: integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MIHalfSizeClick(Sender: TObject);
    procedure MINextImageClick(Sender: TObject);
    procedure OpenFolderImageClick(Sender: TObject);
    procedure PreviousImage1Click(Sender: TObject);
    procedure ScrollBoxClick(Sender: TObject);
    procedure ScrollBoxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
    procedure ThumbControl1Click(Sender: TObject);
    procedure ThumbControl1SelectItem(Sender: TObject; Item: TThreadedImage);
    procedure TrackBar1Change(Sender: TObject);
    {$IFDEF DARWIN}
    procedure mnuAboutClick(Sender: TObject);
    procedure OptionsCmdClick(Sender: TObject);

    {$ENDIF}
  private
    { Private declarations }
    procedure NextImage;
    procedure PreviousImage;

    procedure DoError(Msg: string; Args: array of const);
  public
    { Public declarations }
    function ResizeBmp(bitmp: TBitmap; wid, hei: integer): boolean;
    procedure RefreshItem;
  end;

var
  MainForm: TMainForm;
  mWidth, mHeight, nx, px: integer;
  AspRat: integer;
  Stop: boolean;

implementation

{$R *.lfm}

const
  ImageTypes = '|.jpg|.jpeg|.bmp|.xpm|.png';
  {$IFDEF DARWIN}
  pxBorder = 15;
  {$ELSE}
  pxBorder = 30;
  {$ENDIF}


  nxBorder = 30;


resourcestring
  SSelectImageDir = 'Select directory to add images from';
  SSelectImageDirRec = 'Select directory to recursively add images from';
  SImageViewer = 'LazComicView';
  SErrNeedArgument = 'Option at position%d (%s) needs an argument';



procedure TMainForm.BitBtn1Click(Sender: TObject);
var
  Dir: string;
begin
  if SelectDirectory(SSelectImageDir, '/', Dir, True) then
  begin
    ThumbControl1.Visible := True;
    ThumbControl1.Directory := Dir;
    refreshItem;
    Stop := True;
    btnPlay.Enabled := True;
    btnStop.Enabled := False;
    ;
  end;
end;

procedure TMainForm.btnNextClick(Sender: TObject);
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    ThumbControl1.MoveNext;
    Scrollbox.VertScrollBar.Position := 0;
    application.ProcessMessages;
  end;
end;


procedure TMainForm.btnPreriorClick(Sender: TObject);
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    ThumbControl1.MovePrior;
    Scrollbox.VertScrollBar.Position := 0;
    application.ProcessMessages;
  end;
end;


procedure TMainForm.btnPlayClick(Sender: TObject);
var
  fine: integer;

  procedure Delay(dt: DWORD);
  var
    tc: DWORD;
  begin
    tc := GetTickCount;
    while (GetTickCount < tc + dt) and (not Application.Terminated) do
      Application.ProcessMessages;
  end;

begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    fine := 0;
    Stop := False;
    btnPlay.Enabled := False;
    btnStop.Enabled := True;
    ;
    repeat
      scrollbox.VertScrollBar.Position := scrollbox.VertScrollBar.Position + spinStep.Value;
      delay(spinTime.Value * 10);
      fine := 0;
      if (Scrollbox.VertScrollBar.Page + Scrollbox.VertScrollBar.Position) > (Scrollbox.VertScrollBar.Range - 1) then
      begin
        Inc(nx);
        if (ThumbControl1.fMngr.ActiveIndex + 1 = ThumbControl1.fMngr.CountItems) then
          fine := 1;
        if nx > 2 then
        begin
          nx := 0;
          if (ThumbControl1.fMngr.CountItems > 0) and (ThumbControl1.fMngr.ActiveIndex + 1 < ThumbControl1.fMngr.CountItems) then
          begin
            ThumbControl1.MoveNext;
            Scrollbox.VertScrollBar.Position := 0;
            application.ProcessMessages;
          end;

        end;
      end;
    until (ThumbControl1.fMngr.ActiveIndex + fine > ThumbControl1.fMngr.CountItems - 1) or (Stop = True);
  end;

end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
  Stop := True;
  btnPlay.Enabled := True;
  btnStop.Enabled := False;
  ;
end;


{$IFDEF DARWIN}
procedure TMainForm.mnuAboutClick(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

  procedure TMainForm.OptionsCmdClick(Sender: TObject);
begin
  ShowMessage('working in progress');
end;

{$ENDIF}



procedure TMainForm.btnDimClick(Sender: TObject);
var
  NewWith, AspectRatio: double;
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    NewWith := mWidth;
    NewWith := NewWith - (NewWith * 20 / 100);

    AspectRatio := imgOrign.Picture.Height / imgOrign.Picture.Width;
    iMain.Visible := False;
    iMain.Picture.Assign(imgOrign.Picture);
    mWidth := trunc(NewWith);
    mHeight := round(AspectRatio * mWidth);

    if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
    begin
    end
    else
    begin
      ShowMessage('errore');
    end;
    iMain.Visible := True;
  end;

end;

procedure TMainForm.BtnUgualeHeightClick(Sender: TObject);
var
  NewHeight: integer;
  AspectRatio: double;
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    AspRat := 2;
    NewHeight := scrollbox.Height - pxBorder;


    AspectRatio := imgOrign.Picture.Width / imgOrign.Picture.Height;
    iMain.Picture.Assign(imgOrign.Picture);
    mHeight := NewHeight;
    mWidth := round(AspectRatio * mHeight);

    if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
    begin
    end
    else
    begin
      ShowMessage('errore');
    end;
  end;
end;

procedure TMainForm.BtnUgualeWidthClick(Sender: TObject);
var
  NewWidth: integer;
  AspectRatio: double;
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    AspRat := 1;
    NewWidth := scrollbox.Width - 30;
    AspectRatio := imgOrign.Picture.Height / imgOrign.Picture.Width;
    iMain.Picture.Assign(imgOrign.Picture);
    mWidth := NewWidth;
    mHeight := round(AspectRatio * mWidth);

    if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
    begin
    end
    else
    begin
      ShowMessage('errore');
    end;
  end;
end;

procedure TMainForm.D1Click(Sender: TObject);
begin
  BtnAumetaClick(sender);
end;

procedure TMainForm.D1DrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin

end;

procedure TMainForm.D1MeasureItem(Sender: TObject; ACanvas: TCanvas; var AWidth, AHeight: integer);
begin

end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
function MyMessageDlg(const aMsg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons): TModalResult;
begin
  with CreateMessageDialog(aMsg, DlgType, Buttons) do
  begin
    Result := ShowModal;
    Free;
  end;
end;

var
  buttonSelected: integer;
begin


  if (Self.Active = True) then
    buttonSelected :=  MyMessageDlg('Vuoi davvero uscire dal programma?', mtConfirmation, [mbYes, mbNo]);
  if buttonSelected = mrYes then
  begin
    CanClose := True;
    Stop := True;
  end
  else
  begin
    CanClose := False;
  end;

end;



procedure TMainForm.FormCreate(Sender: TObject);
begin
  {$IFDEF DARWIN}
  AppMenu := TMenuItem.Create(Self);  {Application menu}
  AppMenu.Caption := #$EF#$A3#$BF;  {Unicode Apple logo char}
  MainMenu.Items.Insert(0, AppMenu);

  AppAboutCmd := TMenuItem.Create(Self);
  AppAboutCmd.Caption := 'About LazComicView';  //<== BundleName set elsewhere
  AppAboutCmd.OnClick := mnuAboutClick;
  AppMenu.Add(AppAboutCmd);  {Add About as item in application menu}

  AppSep1Cmd := TMenuItem.Create(Self);
  AppSep1Cmd.Caption := '-';
  AppMenu.Add(AppSep1Cmd);

  AppPrefCmd := TMenuItem.Create(Self);
  AppPrefCmd.Caption := 'Preferences...';
  AppPrefCmd.Shortcut := ShortCut(VK_OEM_COMMA, [ssMeta]);
  AppPrefCmd.OnClick := OptionsCmdClick;  //<== "Options" on other platforms
  AppMenu.Add(AppPrefCmd);
  MenuItem1.Visible:= false;
  {$ENDIF}
  //file1.Caption := #$EF#$A3#$BF;

  AspRat := 1;  // 1 Adapt width, 2 Adapt Height
end;

procedure TMainForm.FormResize(Sender: TObject);
var
  NewWith, NewHeight: integer;
  AspectRatio: double;
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    if AspRat = 1 then
    begin
      NewWith := scrollbox.Width - 30;

      AspectRatio := imgOrign.Picture.Height / imgOrign.Picture.Width;
      iMain.Picture.Assign(imgOrign.Picture);
      mWidth := NewWith;
      mHeight := round(AspectRatio * mWidth);
      if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
      begin
        //work in progress
      end
      else
      begin
        ShowMessage('errore');
      end;
    end
    else
    begin
      NewHeight := scrollbox.Height - pxBorder;
      AspectRatio := imgOrign.Picture.Width / imgOrign.Picture.Height;
      iMain.Picture.Assign(imgOrign.Picture);
      mHeight := NewHeight;
      mWidth := round(AspectRatio * mHeight);

      if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
      begin
        //work in progress
      end
      else
      begin
        ShowMessage('errore');
      end;
    end;
  end;
end;

procedure TMainForm.BtnAumetaClick(Sender: TObject);
var
  NewWith, AspectRatio: double;
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
  begin
    NewWith := mWidth;
    NewWith := NewWith + (NewWith * 20 / 100);

    AspectRatio := imgOrign.Picture.Height / imgOrign.Picture.Width;
    iMain.Visible := False;
    iMain.Picture.Assign(imgOrign.Picture);
    mWidth := trunc(NewWith);
    mHeight := round(AspectRatio * mWidth);

    if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
    begin
    end
    else
    begin
      ShowMessage('errore');
    end;
    iMain.Visible := True;
  end;
end;


function TMainForm.ResizeBmp(bitmp: TBitmap; wid, hei: integer): boolean;
var
  TmpBmp: TBitmap;
  ARect: TRect;
begin
  Result := False;
  try
    TmpBmp := TBitmap.Create;
    try
      TmpBmp.Width := wid;
      TmpBmp.Height := hei;
      ARect := Rect(0, 0, wid, hei);
      TmpBmp.Canvas.StretchDraw(ARect, Bitmp);
      bitmp.Assign(TmpBmp);
    finally
      TmpBmp.Free;
    end;
    Result := True;
  except
    Result := False;
  end;
end;


procedure TMainForm.RefreshItem;
var
  newWidth: integer;
  AspectRatio: double;
begin
  ThumbControl1.RefreshTop;
  newWidth := scrollbox.Width - 30;

  AspectRatio := imgOrign.Picture.Height / imgOrign.Picture.Width;
  iMain.Picture.Assign(imgOrign.Picture);
  mWidth := newWidth;
  mHeight := round(AspectRatio * mWidth);

  if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
  begin
    //Working
  end
  else
  begin
    ShowMessage('errore');
  end;
end;



procedure TMainForm.NextImage;
begin
  ThumbControl1.MoveNext;
  ScrollBox.VertScrollBar.Position := 0;
end;

procedure TMainForm.PreviousImage;
begin
  ThumbControl1.MovePrior;
  ScrollBox.VertScrollBar.Position := 0;
end;


procedure TMainForm.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  // todo: write help about with at least key combinations!
  if (shift = [ssShift]) or (shift = [ssAlt]) then
  begin
    if (key = VK_Prior) then
    begin
      // Page Up
      btnDimClick(Sender);
      Key := 0;
    end
    else if (key = VK_Next) then
    begin
      // Page Down
      BtnAumetaClick(Sender);
      Key := 0;
    end
    else if (key = VK_Left) then
    begin
      // Left
      ThumbControl1.MovePrior;
      Key := 0;
    end
    else if (key = VK_right) then
    begin
      // Right
      ThumbControl1.MoveNext;
      Key := 0;
    end;
  end
  else if (shift = []) then
  begin
    if Key = VK_UP then
    begin
      // Up
      ThumbControl1.MovePrior;
      Key := 0;
    end
    else if Key = VK_DOWN then
    begin
      // Down
      ThumbControl1.MoveNext;
      Key := 0;
    end;
  end;
end;

procedure TMainForm.DoError(Msg: string; Args: array of const);

begin
  ShowMessage(Format(Msg, Args));
end;



procedure TMainForm.FormShow(Sender: TObject);
begin

end;

procedure TMainForm.MenuItem1Click(Sender: TObject);
begin
  AboutForm.ShowModal;
end;

procedure TMainForm.MIHalfSizeClick(Sender: TObject);
begin
  btnDimClick(Sender);
end;

procedure TMainForm.MINextImageClick(Sender: TObject);
begin
  btnNextClick(Sender);
end;

procedure TMainForm.OpenFolderImageClick(Sender: TObject);
begin
  BitBtn1Click(Sender);
end;

procedure TMainForm.PreviousImage1Click(Sender: TObject);
begin
  btnPreriorClick(Sender);
end;

procedure TMainForm.ScrollBoxClick(Sender: TObject);
begin
  if (ThumbControl1.fMngr.CountItems > 0) then
    NextImage;
end;


procedure TMainForm.ScrollBoxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
begin
  if ((Sender as TScrollBox).VertScrollBar.Position - WheelDelta) >= 0 then
  begin
    px := 0;
  end
  else
  begin
    Inc(px);
    if px > 2 then
    begin
      px := 0;
      if (ThumbControl1.fMngr.CountItems > 0) then
      begin
        ThumbControl1.MovePrior;
        (Sender as TScrollBox).VertScrollBar.Position := (Sender as TScrollBox).VertScrollBar.Page;
        ;
      end;
    end;
  end;


  if ((Sender as TScrollBox).VertScrollBar.Page + (Sender as TScrollBox).VertScrollBar.Position) >
    ((Sender as TScrollBox).VertScrollBar.Range - 1) then
  begin
    Inc(nx);
    // go to next page
    if nx > 4 then
    begin
      nx := 0;
      if (ThumbControl1.fMngr.CountItems > 0) and (ThumbControl1.fMngr.ActiveIndex + 1 < ThumbControl1.fMngr.CountItems) then
      begin
        ThumbControl1.MoveNext;
        (Sender as TScrollBox).VertScrollBar.Position := 0;
      end;
    end;
  end
  else
  begin
    nx := 0;
  end;
  Caption := IntToStr(px) + ' ' + IntToStr(nx) + ' ' + IntToStr((Sender as TScrollBox).VertScrollBar.Page) +
    ' ' + IntToStr((Sender as TScrollBox).VertScrollBar.Position) + ' ' + IntToStr(WheelDelta) + ' ' + IntToStr(
    (Sender as TScrollBox).VertScrollBar.Range);

end;

procedure TMainForm.ThumbControl1Click(Sender: TObject);
begin
  ScrollBox.VertScrollBar.Position := 0;
end;




procedure TMainForm.ThumbControl1SelectItem(Sender: TObject; Item: TThreadedImage);
var
  newWidth, newHeight: integer;
  Scale: double;
  AspectRatio: double;

begin

  if AspRat = 1 then
  begin
    newWidth := scrollbox.Width - 30;
    imgOrign.Picture.LoadFromFile(item.URL);
    iMain.Picture := imgOrign.Picture;
    AspectRatio := imgOrign.Picture.Height / imgOrign.Picture.Width;
    mWidth := newWidth;
    mHeight := round(AspectRatio * mWidth);
    if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
    begin
    end
    else
    begin
      ShowMessage('errore');
    end;
  end
  else
  begin
    newHeight := scrollbox.Height - pxBorder;
    imgOrign.Picture.LoadFromFile(item.URL);
    AspectRatio := imgOrign.Picture.Width / imgOrign.Picture.Height;
    iMain.Picture.Assign(imgOrign.Picture);
    mHeight := newHeight;
    mWidth := round(AspectRatio * mHeight);
    if ResizeBmp(iMain.Picture.Bitmap, mWidth, mHeight) = True then
    begin
    end
    else
    begin
      ShowMessage('errore');
    end;
  end;

end;

procedure TMainForm.TrackBar1Change(Sender: TObject);
begin

end;


end.
