unit frmabout;

{$mode objfpc}{$H+}

interface

uses
    {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Buttons,
  ExtCtrls, StdCtrls,

  {$IFDEF DARWIN}
     MacOSAll,
     CarbonProc,
    StrUtils,
  {$ENDIF}

    fileinfo
  , winpeimagereader {need this for reading exe info}
  , elfreader {needed for reading ELF executables}
  , machoreader {needed for reading MACH-O executables}
  ;


type

  { TAboutForm }

  TAboutForm = class(TForm)
    BitBtn1: TBitBtn;
    Button1: TButton;
    Image1: TImage;
    StaticTextAppTitle: TLabel;
    StaticTextCompany: TLabel;
    StaticTextAppVer: TLabel;
    Label4: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);

    procedure Image1Click(Sender: TObject);
  private
     procedure ReadInfo;
  public

  end;

    TVerInfo=packed record
                    Notuse: array[0..47] of byte;
                    Minor,Major,Build,Release: word;
    end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

procedure TAboutForm.BitBtn1Click(Sender: TObject);
begin
  close;
end;

procedure TAboutForm.BitBtn2Click(Sender: TObject);

begin


end;

procedure TAboutForm.Button1Click(Sender: TObject);
begin
   ReadInfo;
end;


procedure TAboutForm.ReadInfo;
{$IFDEF DARWIN}
  var
     BundleID: String;
     BundleName: String;
     BundleRef: CFBundleRef;
     BundleVer: String;
     CompanyName: AnsiString;
     KeyRef: CFStringRef;
     ValueRef: CFTypeRef;

  function GetInfoPlistString(const KeyName : string) : string;
  begin
       try
          Result := '';
          BundleRef := CFBundleGetMainBundle;
          if BundleRef = nil then Exit;  {Executable not in an app bundle?}
          KeyRef := CFStringCreateWithPascalString(nil,KeyName,kCFStringEncodingUTF8);
          ValueRef := CFBundleGetValueForInfoDictionaryKey(BundleRef, KeyRef);
          if CFGetTypeID(ValueRef) <> CFStringGetTypeID then Exit;  {Value not a string?}
          Result := CFStringToStr(ValueRef);
       except
         on E : Exception do
            ShowMessage(E.Message);
       end;
      FreeCFString(KeyRef);
  end;
{$ENDIF}

begin
   {$IFDEF DARWIN}
   try
     AboutForm.Caption := 'About '+Application.Title;
     StaticTextAppTitle.Caption := Application.Title;
     BundleID := GetInfoPlistString('CFBundleIdentifier');
     // CompanyName is presumed to be in the form of: com.Company.AppName'''
     CompanyName := AnsiMidStr(BundleID,AnsiPos('.',BundleID)+1,Length(BundleID));
     CompanyName := AnsiMidStr(CompanyName,0,AnsiPos('.',CompanyName)-1);
     BundleVer := GetInfoPlistString('CFBundleVersion');
     StaticTextAppVer.Caption := Application.Title+' version '+BundleVer;
     StaticTextCompany.Caption := CompanyName;
   except
   on E : Exception do
          ShowMessage(E.Message);
   end
   {$ENDIF}

end;



procedure TAboutForm.Image1Click(Sender: TObject);
begin
  ReadInfo;
end;

end.

