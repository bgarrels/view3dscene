{
  Copyright 2003-2014 Michalis Kamburelis.

  This file is part of "view3dscene".

  "view3dscene" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "view3dscene" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "view3dscene"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  ----------------------------------------------------------------------------
}

{ Status text font and colors. }
unit V3DSceneStatus;

interface

uses CastleFonts, Classes, CastleUIControls, CastleTimeUtils,
  CastleControls;

type
  TStatusText = class(TCastleLabel)
  private
    FMaxLineChars: Cardinal;
    FlashTime, Time: TFloatTime;
    FlashText: string;
  protected
    procedure CalculateText; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Render; override;
    procedure ContainerResize(const AContainerWidth, AContainerHeight: Cardinal); override;
    procedure Update(const SecondsPassed: Single;
      var HandleInput: boolean); override;

    { How many characters can reasonably fit in a line for current window
      width. }
    property MaxLineChars: Cardinal read FMaxLineChars;

    { Show a message that will fadeout with time. }
    procedure Flash(const AText: string);
  end;

var
  StatusText: TStatusText;

implementation

uses SysUtils, CastleTextureFont_DejaVuSansMonoBold_15,
  CastleVectors, CastleUtils, CastleColors;

{ TStatusText ---------------------------------------------------------------- }

constructor TStatusText.Create(AOwner: TComponent);
begin
  inherited;
  Tags := true;
  Left := 5;
  Bottom := 5;
  Color := Yellow;
  Padding := 5;
  CustomFont := TTextureFont.Create(TextureFont_DejaVuSansMonoBold_15);
  OwnsCustomFont := true;
end;

procedure TStatusText.Render;
begin
  if not GetExists then Exit;
  Text.Clear;
  CalculateText;
  inherited;
end;

const
  FlashDelay = 1.0;

procedure TStatusText.CalculateText;
begin
  if (FlashText <> '') and (FlashTime + FlashDelay > Time) then
  begin
    Text.Append('<font color="#' + ColorToHex(Vector4Single(1, 1, 0,
      1 - (Time - FlashTime) / FlashDelay)) + '">' + FlashText + '</font>');
    Text.Append('');
  end;
end;

procedure TStatusText.ContainerResize(const AContainerWidth, AContainerHeight: Cardinal);
var
  CharWidth: Integer;
begin
  inherited;
  CharWidth := Font.TextWidth('W');
  if CharWidth > 0 then
    FMaxLineChars := Max(Integer(10), Integer(ContainerWidth - Padding * 2 -
      Left * 2) div CharWidth) else
    FMaxLineChars := 10; // fallback in case we cannot calculate CharWidth
end;

procedure TStatusText.Flash(const AText: string);
begin
  FlashText := AText;
  FlashTime := Time;
end;

procedure TStatusText.Update(const SecondsPassed: Single;
  var HandleInput: boolean);
begin
  inherited;
  if not GetExists then Exit;
  if (FlashText <> '') and (FlashTime + FlashDelay > Time) then VisibleChange;
  Time += SecondsPassed;
end;

end.
