unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph, TASeries, Forms, Controls, Graphics,
  Dialogs, ActnList, StdCtrls, ExtCtrls, ComCtrls, Buttons, Menus, SdpoSerial,
  strutils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Chart2: TChart;
    Temp2Series: TLineSeries;
    Temp1Series: TLineSeries;
    Splitter1: TSplitter;
    StartBtn: TButton;
    StopBtn: TButton;
    ConnectBtn: TButton;
    DisconnectBtn: TButton;
    SaveDirBtn: TButton;
    SaveFileBtn: TButton;
    TareBtn: TButton;
    ClearBtn: TButton;
    Chart1: TChart;
    FileName: TEdit;
    Savedir: TLabel;
    MainSeries: TLineSeries;
    Memo1: TMemo;
    SaveDirSelect: TSelectDirectoryDialog;
    DetectorPort: TSdpoSerial;
    StatusBar1: TStatusBar;
    procedure ClearBtnClick(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure DetectorPortRxData(Sender: TObject);
    procedure DisconnectBtnClick(Sender: TObject);
    procedure FileNameKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure SaveDirBtnClick(Sender: TObject);
    procedure SaveFileBtnClick(Sender: TObject);
    procedure TareBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
    buff:string;

implementation

{$R *.lfm}

{ TForm1 }

function checkstrings(key:char;S:string; checkmode:byte):char;
var
  i:integer;
begin //порядок команд имеет значение
  Result:=key;
  case checkmode of
    0:begin
        if key=#46 then Key:=#44;  //если перед этой строкой
        //выполнить Result:=key; то будут ставиться точки и запятые
        Result:=key;
        Case key of // положительные дробные числа
          #8, #48..#57 : Result := Key;
          #44 : For i := 1 to Length(S) do
                        If (S[i] = '.') or //контсрукция (S[i] = key) не работает
                           (S[i] = ',') then
                            Result := #0;
          Else Result := #0;
        end;
      end;
    1:begin
        Case key of // имена файлов и директорий
           #34, #42, #47, #58, #60, #62, #63, #92, #124 : Result := #0;
           Else Result := key;
         end;
      end;
  end;
end;

procedure TForm1.SaveDirBtnClick(Sender: TObject);
begin
  if SaveDirSelect.Execute then Savedir.Caption:=SaveDirSelect.FileName + '/';
  FileName.Left:=Savedir.Width + Savedir.Left + 3;
end;

procedure TForm1.SaveFileBtnClick(Sender: TObject);
var
  tmpstr:string;
begin
  if FileName.Text = '' then FileName.Text:=FormatDateTime('yyyy-mm-dd_hh-nn-ss',Now)+'.txt';
  tmpstr:=SaveDir.Caption+FileName.Text;
  if fileexists(tmpstr) then
     begin
       showmessage('Файл'+#13#10+tmpstr+#13#10+'существует'+#13#10+'Выберите другое имя файла или папку');
       exit;
     end;
  Memo1.Lines.SaveToFile(SaveDir.Caption+FileName.Text);
end;

procedure TForm1.TareBtnClick(Sender: TObject);
begin
  DetectorPort.WriteData('t');
end;

procedure TForm1.StartBtnClick(Sender: TObject);
begin
  DetectorPort.WriteData('b');
  StopBtn.Enabled:=true;
  StartBtn.Enabled:=false;
  TareBtn.Enabled:=false;
  ClearBtn.Enabled:=false;
end;

procedure TForm1.StopBtnClick(Sender: TObject);
begin
  DetectorPort.WriteData('e');
  StopBtn.Enabled:=false;
  StartBtn.Enabled:=true;
  TareBtn.Enabled:=true;
  ClearBtn.Enabled:=true;
end;

procedure TForm1.FileNameKeyPress(Sender: TObject; var Key: char);
begin
  key:=checkstrings(key,FileName.Text,1);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if StopBtn.Enabled then StopBtn.Click;
  if DisconnectBtn.Enabled then DisconnectBtn.Click;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ConnectBtn.Enabled:=true;
  DisconnectBtn.Enabled:=false;
  StopBtn.Enabled:=false;
  StartBtn.Enabled:=false;
  TareBtn.Enabled:=false;
  Memo1.Clear;
  FileName.Clear;
  MainSeries.Clear;
end;

procedure TForm1.FormWindowStateChange(Sender: TObject);
begin
  splitter1.Top:=round((form1.Height-chart1.Top)/2+chart1.Top/4);
  //if form1.WindowState = wsMaximized then splitter1.Top:=500;
  //if form1.WindowState = wsNormal then chart1.Height:=200;
end;

procedure TForm1.DetectorPortRxData(Sender: TObject);
var
  x:integer; // время в секундах с момента начала измерений
  z1,z2:integer; // y - вес в унциях, z1,z2 - миливольты термопары
  y,mv1,mv2:real;
  tmpstr:string;
begin
  buff := buff + DetectorPort.ReadData;
  if pos(#10,buff) = 0 then exit;
  buff:=trim(buff);
  //if (pos('Startup',buff) > 0) and (StartBtn.Enabled = false) then
  if (pos('Ready',buff) > 0) and (StartBtn.Enabled = false) then
     begin
       if StopBtn.Enabled then
          StopBtn.Click
       else
         begin
           StartBtn.Enabled:=true;
           TareBtn.Enabled:=true;
           DetectorPort.WriteData('e');
         end;
     end;

  if pos(';',buff) <> 0 then
      begin
        if not TryStrToInt(ExtractWord(1,buff,[';']),x) then x:=0;
        if not TryStrToFloat(ExtractWord(2,buff,[';']),y) then y:=0;
        if not TryStrToInt(ExtractWord(3,buff,[';']),z1) then z1:=0;
        if not TryStrToInt(ExtractWord(4,buff,[';']),z2) then z2:=0;
//        if not TryStrToInt(ExtractWord(5,buff,[';']),amp) then amp:=0;
        //buff:=StringReplace(buff,'.',',',[rfReplaceAll, rfIgnoreCase]);
        //buff:=StringReplace(buff,';',#09,[rfReplaceAll, rfIgnoreCase]);
        //Memo1.Append(buff);
        MainSeries.AddXY(x,y);
        mv1:=z1*1.49011611938e-07*2.5/16*1000;
        mv2:=z2*1.49011611938e-07*2.5/16*1000;
        Temp1Series.AddXY(x,mv1);
        Temp2Series.AddXY(x,mv2);
        tmpstr:=inttostr(x)+#09;
        tmpstr:=tmpstr+FormatFloat('0.000', y)+#09;
        tmpstr:=tmpstr+FormatFloat('0.000', mv1)+#09;
        tmpstr:=tmpstr+FormatFloat('0.000', mv2);
        Memo1.Append(tmpstr);
      end;
  buff:='';
end;

procedure TForm1.DisconnectBtnClick(Sender: TObject);
begin
  if StopBtn.Enabled then StopBtn.Click;
  DetectorPort.Close;
  if not DetectorPort.Active then
     begin
       ConnectBtn.Enabled:=true;
       DisconnectBtn.Enabled:=false;
       StopBtn.Enabled:=false;
       StartBtn.Enabled:=false;
       TareBtn.Enabled:=false;
     end;
end;

procedure TForm1.ConnectBtnClick(Sender: TObject);
begin
  DetectorPort.Open;
  if DetectorPort.Active then
     begin
       ConnectBtn.Enabled:=false;
       DisconnectBtn.Enabled:=true;
       StopBtn.Enabled:=false;
       TareBtn.Enabled:=true;
       //StartBtn.Enabled:=true;
     end;
end;

procedure TForm1.ClearBtnClick(Sender: TObject);
begin
  Memo1.Clear;
  FileName.Clear;
  MainSeries.Clear;
  Temp1Series.CLear;
  Temp2Series.CLear;
end;

end.

