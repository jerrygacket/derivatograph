unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph, TASeries, TAFuncSeries, Forms, Controls,
  Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Spin, SdpoSerial, Synaser,
  IniFiles, strutils;

const   //константы для библиотеки ком-порта
  br : array [0..12] of TBaudRate = (br___300, br___600, br__1200, br__2400,
             br__4800, br__9600, br_19200, br_38400, br_57600, br115200,
             br230400, br460800, br921600);
  db : array [0..3] of TDataBits=(db8bits,db7bits,db6bits,db5bits);
  par : array [0..4] of TParity=(pNone,pOdd,pEven,pMark,pSpace);
  fc : array [0..2] of TFlowControl=(fcNone,fcXonXoff,fcHardware);
  sb : array [0..1] of TStopBits=(sbOne,sbTwo);

type

  { TForm1 }

  TForm1 = class(TForm)
    allpages: TPageControl;
    InitDetector: TButton;
    DetectorPort: TSdpoSerial;
    DetectorPortConnect: TRadioButton;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    DetectorBoudRate: TComboBox;
    DetectorDataBits: TComboBox;
    DetectorFlowControl: TComboBox;
    DetectorParity: TComboBox;
    DetectorStopBit: TComboBox;
    Label18: TLabel;
    Label3: TLabel;
    ListBox1: TListBox;
    StartYustBtn: TButton;
    StopYustBtn: TButton;
    ClosePanel: TButton;
    Label12: TLabel;
    EndPanel: TPanel;
    SaveBar: TProgressBar;
    StartBtn: TButton;
    StopBtn: TButton;
    SaveGraf: TButton;
    SetupUgol: TButton;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    StartUgol: TSpinEdit;
    StopUgol: TSpinEdit;
    ViewFilesList: TListBox;
    SaveDirOpen: TButton;
    SaveDirSelect: TSelectDirectoryDialog;
    OtmetkaConnect: TButton;
    OtmetkaBoudRate: TComboBox;
    OtmetkaDataBits: TComboBox;
    OtmetkaStopBit: TComboBox;
    OtmetkaParity: TComboBox;
    OtmetkaFlowControl: TComboBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    OtmetkaPortName: TComboBox;
    GroupBox3: TGroupBox;
    DetectorConnect: TButton;
    DetectorPortName: TComboBox;
    DevStatus: TStatusBar;
    GroupBox2: TGroupBox;
    ViewPulse: TLabel;
    Label2: TLabel;
    OtmekaPortConnect: TRadioButton;
    SaveDir: TLabeledEdit;
    MainSeries: TLineSeries;
    PulseBar: TProgressBar;
    OtmetkaPort: TSdpoSerial;
    ViewChart: TChart;
    MainChart: TChart;
    GroupBox1: TGroupBox;
    izmerenie: TTabSheet;
    FileName: TLabeledEdit;
    Memo1: TMemo;
    ObjName: TLabeledEdit;
    Comment: TLabeledEdit;
    prosmotr: TTabSheet;
    ViewSeries: TLineSeries;
    yustirovka: TTabSheet;
    nastroiki: TTabSheet;
    procedure ClosePanelClick(Sender: TObject);
    procedure DetectorPortRxData(Sender: TObject);
    procedure FileNameKeyPress(Sender: TObject; var Key: char);
    procedure InitDetectorClick(Sender: TObject);
    procedure OtmetkaPortRxData(Sender: TObject);
    procedure prosmotrShow(Sender: TObject);
    procedure SaveDirOpenClick(Sender: TObject);
    procedure DetectorConnectClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure OtmetkaConnectClick(Sender: TObject);
    procedure SetupUgolClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure StartYustBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure StopYustBtnClick(Sender: TObject);
    procedure ViewFilesListClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  Ugol:Integer;
  pulsenum:real; // общее количество импульсов за одну отметку
  medpulsenum:real; // предидущий средний результат количества импульсов
  pulsecount:byte; // счетчик количества замеров импульсов за одну метку
  firstpoint:boolean;// замер первой точки.
  //т.к. детектор начинает считать до начала чтеиня из него, то
  //обычно первый замер с детектора очень большой,
  buff:string;
  IsConnect:boolean;

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

procedure TForm1.FormCreate(Sender: TObject);
var
  reg:TInifile;
begin
  form1.WindowState:=wsMaximized;

  OtmetkaPortName.Items.CommaText:=GetSerialPortNames;
  {DetectorPortName.Items.CommaText:=GetSerialPortNames;
  OtmekaPortConnect.Checked := OtmetkaPort.Active;
  DetectorPortConnect.Checked := DetectorPort.Active;
  reg := TInifile.Create('cfg.ini');
  DetectorPortName.ItemIndex:=reg.ReadInteger('Detector','PortIndex',-1);
  DetectorBoudRate.ItemIndex:=reg.ReadInteger('Detector','BoudRate',9);
  DetectorDataBits.ItemIndex:=reg.ReadInteger('Detector','DataBits',0);
  DetectorStopBit.ItemIndex:=reg.ReadInteger('Detector','StopBit',0);
  DetectorParity.ItemIndex:=reg.ReadInteger('Detector','Parity',0);
  DetectorFlowControl.ItemIndex:=reg.ReadInteger('Detector','FlowControl',0);
  OtmetkaPortName.ItemIndex:=reg.ReadInteger('Otmetka','PortIndex',-1);
  OtmetkaBoudRate.ItemIndex:=reg.ReadInteger('Otmetka','BoudRate',9);
  OtmetkaDataBits.ItemIndex:=reg.ReadInteger('Otmetka','DataBits',0);
  OtmetkaStopBit.ItemIndex:=reg.ReadInteger('Otmetka','StopBit',0);
  OtmetkaParity.ItemIndex:=reg.ReadInteger('Otmetka','Parity',0);
  OtmetkaFlowControl.ItemIndex:=reg.ReadInteger('Otmetka','FlowControl',0);
  SaveDir.Text:=reg.ReadString('Main','savedir','C:');
  reg.Free; //закрытие реестра
  //Form1.OtmetkaConnect.Click;
  DetectorConnect.Click;
  InitDetector.Click;}
  allpages.ActivePageIndex:=0;
end;

procedure TForm1.OtmetkaConnectClick(Sender: TObject);
begin
  if OtmetkaPort.Active then OtmetkaPort.Close;
  DevStatus.Panels.Items[1].Text:='Отметчик отключен';
  OtmekaPortConnect.Checked:=OtmetkaPort.Active;
  OtmetkaPort.Device:=OtmetkaPortName.Text;
  OtmetkaPort.BaudRate := br[OtmetkaBoudRate.ItemIndex];
  OtmetkaPort.DataBits:=db[OtmetkaDataBits.ItemIndex];
  OtmetkaPort.Parity:=par[OtmetkaParity.ItemIndex];
  OtmetkaPort.StopBits:=sb[OtmetkaStopBit.ItemIndex];
  OtmetkaPort.FlowControl:=fc[OtmetkaFlowControl.ItemIndex];
  if OtmetkaPort.Device<>'' then OtmetkaPort.Open;
  if OtmetkaPort.Active then
   DevStatus.Panels.Items[1].Text:='Отметчик подключен'
   else showmessage('Отметчик не подключен!');
  OtmekaPortConnect.Checked:=OtmetkaPort.Active;
end;

procedure TForm1.SetupUgolClick(Sender: TObject);
begin
  label11.Caption:=StartUgol.Caption;
  Ugol:=trunc(StartUgol.Value*100);
end;

procedure TForm1.StartBtnClick(Sender: TObject);
begin
  StartUgol.Caption:=label11.Caption;
  {if not OtmetkaPort.Active then
   begin
     ShowMessage('Не подключен отметчик.');
     Exit;
   end;  }
  if not DetectorPort.Active then
   begin
     ShowMessage('Не подключен детектор.');
     Exit;
   end;
  if FileName.Text='' then
   begin
     FileName.SetFocus;
     ShowMessage('Не задан файл.');
     Exit;
   end;
  if ObjName.Text='' then
   begin
     ObjName.SetFocus;
     ShowMessage('Не задан объект.');
     Exit;
   end;
  If StartUgol.Value=StopUgol.Value then
   begin
     ShowMessage('Начальный и конечный углы равны.');
     Exit;
   end;

  //SetupUgol.Click;
  firstpoint:=true;
  pulsenum:=0;
  medpulsenum:=0;
  pulsecount:=0;
  MainSeries.Clear;


  SetupUgol.Enabled:=False;
  StartUgol.Enabled:=False;
  StopUgol.Enabled:=False;
  FileName.Enabled:=False;
  allpages.Pages[1].Enabled:=False;
  allpages.Pages[2].Enabled:=False;
  allpages.Pages[3].Enabled:=False;

  StopBtn.Enabled:=True;
  StartBtn.Enabled:=False;
  DevStatus.Panels.Items[2].Text:='Идет измерение...';
  if StartUgol.Value < StopUgol.Value then
    DetectorPort.WriteData('70,1'+#10);
  if StartUgol.Value > StopUgol.Value then
    DetectorPort.WriteData('82,1'+#10);
end;

procedure TForm1.StartYustBtnClick(Sender: TObject);
begin
  if StopBtn.Enabled then exit;
  if not DetectorPort.Active then
   begin
     ShowMessage('Не подключен детектор.');
     Exit;
   end;

  FirstPoint:=True;
  StartYustBtn.Enabled:=False;
  allpages.Pages[0].Enabled:=False;
  allpages.Pages[1].Enabled:=False;
  allpages.Pages[3].Enabled:=False;

  //start sending data from detector
  DetectorPort.WriteData('85,1'+#10);

  DevStatus.Panels.Items[2].Text:='Идет измерение...';
end;

procedure TForm1.StopBtnClick(Sender: TObject);
var
  i:integer;
  f:textfile;
  fname:string;
begin
  StopBtn.Enabled:=false;
  DevStatus.Panels.Items[2].Text:='Измерение остановлено';
  DetectorPort.WriteData('83,0'+#10);

  EndPanel.Visible:=True;
  EndPanel.Top:=trunc(form1.Height/2-EndPanel.Height/2);
  EndPanel.Left:=trunc(form1.Width/2-EndPanel.Width/2);
  EndPanel.BringToFront;
  SaveBar.Position:=SaveBar.Min;
  //Application.ProcessMessages;
  SaveBar.Max:=MainSeries.Count+10;
  SaveBar.StepIt;
  fname:=Utf8ToAnsi(SaveDir.Text+'\'+FileName.Text+'.dtf');
  While fileexists(fname) do
    begin
      fname:=Utf8ToAnsi(SaveDir.Text+'\'+FileName.Text
        +IntToStr(Random(1000))+'.dtf');
    end;
  AssignFile(F, fname);
  Rewrite(f);
  writeln(f,'**************************************');
  writeln(f,datetostr(date));
  writeln(f,timetostr(time));
  writeln(f,ObjName.Text);
  WriteLn(F,Comment.Text);
  writeln(f,'Начальный угол: '+StartUgol.Text);
  writeln(f,'Конечный угол: '+StopUgol.Text);
  WriteLn(f,'Begin:');
  SaveBar.StepIt;
  for i:=0 to MainSeries.Count-1 do
    begin
      writeln(f,FloatToStrF(MainSeries.XValue[i],ffFixed,5,2)
              ,#09,FloatToStrF(MainSeries.YValue[i],ffFixed,10,2));
      SaveBar.StepIt;
      Application.ProcessMessages;
    end;
  SaveBar.StepIt;
  writeln(f,'End:');
  closefile(f);
  SaveBar.Position:=SaveBar.Max;
  label12.Caption:='Сохранение закончено.';
  ClosePanel.Enabled:=True;
end;

procedure TForm1.StopYustBtnClick(Sender: TObject);
begin
  if StartYustBtn.Enabled then exit;
  DevStatus.Panels.Items[2].Text:='Измерение остановлено';
  StartYustBtn.Enabled:=True;
  allpages.Pages[0].Enabled:=True;
  allpages.Pages[1].Enabled:=True;
  allpages.Pages[3].Enabled:=True;
end;

procedure TForm1.ViewFilesListClick(Sender: TObject);
var
  i,j:integer;
  StartPoint:integer;
  StopPoint:integer;
  XRecord,YRecord:real;
begin
  if ViewFilesList.Items.Count<=0 then exit;
  if ViewFilesList.ItemIndex<0 then exit;
  ViewSeries.Clear;
  memo1.Lines.LoadFromFile(SaveDir.Text+'\'
         +ViewFilesList.Items.Strings[ViewFilesList.ItemIndex]+'.dtf');
  for i:=0 to memo1.Lines.Count-1 do
  begin
    if AnsiContainsStr(memo1.Lines.Strings[i],'Begin:') then break;
  end;
  StartPoint:=i+1;
  for i:=memo1.Lines.Count-1 downto 0 do
  begin
    if AnsiContainsStr(memo1.Lines.Strings[i],'End:') then break;
  end;
  StopPoint:=i-1;
  for i:=StartPoint to StopPoint do
  begin
    j:=pos(#09,memo1.Lines.Strings[i]);
    XRecord:=StrToFloat(copy(memo1.Lines.Strings[i],1,j-1));
    YRecord:=StrToFloat(copy(memo1.Lines.Strings[i],j+1,
             Length(memo1.Lines.Strings[i])));
    ViewSeries.AddXY(XRecord,YRecord);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  reg:TInifile;
begin
  reg := TInifile.Create('cfg.ini');
  reg.WriteInteger('Detector','PortIndex',DetectorPortName.ItemIndex);
  reg.WriteInteger('Detector','BoudRate',DetectorBoudRate.ItemIndex);
  reg.WriteInteger('Detector','DataBits',DetectorDataBits.ItemIndex);
  reg.WriteInteger('Detector','StopBit',DetectorStopBit.ItemIndex);
  reg.WriteInteger('Detector','Parity',DetectorParity.ItemIndex);
  reg.WriteInteger('Detector','FlowControl',DetectorFlowControl.ItemIndex);

  reg.WriteInteger('Otmetka','PortIndex',OtmetkaPortName.ItemIndex);
  reg.WriteInteger('Otmetka','BoudRate',OtmetkaBoudRate.ItemIndex);
  reg.WriteInteger('Otmetka','DataBits',OtmetkaDataBits.ItemIndex);
  reg.WriteInteger('Otmetka','StopBit',OtmetkaStopBit.ItemIndex);
  reg.WriteInteger('Otmetka','Parity',OtmetkaParity.ItemIndex);
  reg.WriteInteger('Otmetka','FlowControl',OtmetkaFlowControl.ItemIndex);
  reg.WriteString('Main','savedir',SaveDir.Text);
  reg.Free; //закрытие реестра
  if DetectorPort.Active then
   begin
     DetectorPort.WriteData('85,0'+#10);
     DetectorPort.Close;
     DevStatus.Panels.Items[0].Text:='Детектор отключен';
     DetectorPortConnect.Checked:=DetectorPort.Active;
   end;
   if OtmetkaPort.Active then
    begin
      OtmetkaPort.Close;
      DevStatus.Panels.Items[1].Text:='Отметчик отключен';
      OtmekaPortConnect.Checked:=OtmetkaPort.Active;
    end;
end;

procedure TForm1.DetectorConnectClick(Sender: TObject);
begin
  if DetectorPort.Active then DetectorPort.Close;
  DevStatus.Panels.Items[0].Text:='Детектор отключен';
  DetectorPortConnect.Checked:=DetectorPort.Active;
  DetectorPort.Device:=DetectorPortName.Text;
  DetectorPort.BaudRate := br[DetectorBoudRate.ItemIndex];
  DetectorPort.DataBits:=db[DetectorDataBits.ItemIndex];
  DetectorPort.Parity:=par[DetectorParity.ItemIndex];
  DetectorPort.StopBits:=sb[DetectorStopBit.ItemIndex];
  DetectorPort.FlowControl:=fc[DetectorFlowControl.ItemIndex];
  if DetectorPort.Device<>'' then DetectorPort.Open;
  if DetectorPort.Active then
    DevStatus.Panels.Items[0].Text:='Детектор подключен'
   else showmessage('Детектор не подключен!');
  DetectorPortConnect.Checked:=DetectorPort.Active;
end;

procedure TForm1.SaveDirOpenClick(Sender: TObject);
begin
  if SaveDirSelect.Execute then Savedir.Text:=SaveDirSelect.FileName;
end;

procedure TForm1.OtmetkaPortRxData(Sender: TObject);
var
  tmpvar:integer;
begin
  //if form1.allpages.ActivePage.Name='yustirovka' then exit;
  if TryStrToInt(trim(OtmetkaPort.ReadData),tmpvar) then
    Ugol := Ugol + tmpvar;
  label11.Caption:=floattostrf(Ugol/100,ffFixed,5,2);
  if StartBtn.Enabled then exit;
  if pulsecount>0 then medpulsenum:=pulsenum/pulsecount;
  pulsecount:=0;
  pulsenum:=0;
  MainSeries.AddXY(Ugol,medpulsenum);
  if (trunc(Ugol)=trunc(100*StopUgol.Value)) and StopBtn.Enabled then StopBtn.Click;
end;

procedure TForm1.prosmotrShow(Sender: TObject);
var
  tmplist:TStrings;
  i:integer;
begin
  ViewFilesList.Clear;
  if not directoryexists(Utf8ToAnsi(Savedir.Text)) then exit;
  tmplist:= FindAllFiles(Savedir.Text,'*.dtf',false);
  if tmplist.Count>0 then
    for i:=0 to tmplist.Count-1 do
      begin
        //ViewFilesList.Items.Add(ExtractFileNameOnly(tmplist.Strings[i]));
      end;
end;

procedure TForm1.ClosePanelClick(Sender: TObject);
begin
  StartBtn.Enabled:=True;
  SetupUgol.Enabled:=True;
  StartUgol.Enabled:=True;
  StopUgol.Enabled:=True;
  FileName.Enabled:=True;
  allpages.Pages[1].Enabled:=True;
  allpages.Pages[2].Enabled:=True;
  allpages.Pages[3].Enabled:=True;
  EndPanel.Visible:=false;
end;

procedure TForm1.DetectorPortRxData(Sender: TObject);
var
  tmpvar:integer;
  UgolNo:integer;
  PulseNo:integer;
begin
  IsConnect:=true;
  buff:=DetectorPort.ReadData;
  listbox1.Items.Add(buff);
  if listbox1.Count>10 then listbox1.Clear;
  if length(buff)<=0 then exit;
  if buff[length(buff)-1]<>#13 then exit;
  tmpvar:=pos(';',buff);
  if tmpvar<=0 then exit;
  if not TryStrToInt(trim(copy(buff,1,tmpvar-1)),PulseNo) then exit;
  if not TryStrToInt(trim(copy(buff,tmpvar+1,length(buff)-tmpvar)),UgolNo) then
     exit;
  buff:='';

  if allpages.ActivePage.Name='yustirovka' then
      begin
        ViewPulse.Caption:=inttostr(PulseNo);
        if PulseNo>PulseBar.Max then
         PulseBar.Max:=trunc(PulseNo+PulseNo*0.2);
        PulseBar.Position:=PulseNo;
      end;

  Ugol := Ugol + UgolNo;
  label11.Caption:=floattostrf(Ugol/100,ffFixed,5,2);
  label3.Caption:=Label8.Caption+' '+label11.Caption;

  if not StopBtn.Enabled then exit;
  if not firstpoint then
    begin
      Pulsenum:=Pulsenum+PulseNo;
      inc(Pulsecount);
    end;
  firstpoint:=false;
  if UgolNo<>0 then
     if pulsecount>0 then
      begin
        medpulsenum:=pulsenum/pulsecount;
        pulsecount:=0;
        pulsenum:=0;
        MainSeries.AddXY(Ugol/100,medpulsenum);
      end;
  if (trunc(Ugol)=trunc(100*StopUgol.Value)) and StopBtn.Enabled then StopBtn.Click;
end;

procedure TForm1.FileNameKeyPress(Sender: TObject; var Key: char);
begin
  key:=checkstrings(key,FileName.Text,1);
end;

procedure TForm1.InitDetectorClick(Sender: TObject);
begin
  if DetectorPort.Active then
   DetectorPort.WriteData('85,1'+#10);
end;

end.

