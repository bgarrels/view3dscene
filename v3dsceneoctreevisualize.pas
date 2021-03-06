{
  Copyright 2002-2014 Michalis Kamburelis.

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

{ Visualizing the octree. }
unit V3DSceneOctreeVisualize;

{$I castleconf.inc}

interface

uses CastleOctree, CastlePrecalculatedAnimation, CastleWindow;

type
  TOctreeDisplay = object
  private
    procedure AddDisplayStatus(var S: string);
  public
    { Constructor, initially display is none (Whole = @false and Depth = -1). }
    constructor Init(const AName: string);
  public
    Whole: boolean;

    { Depth to dispay. Meaningful only if Whole = false.
      -1 means "don't display octree". }
    Depth: Integer;

    Name: string;

    MenuWhole: TMenuItemChecked;

    procedure DoMenuIncDepth;
    procedure DoMenuDecDepth;
    procedure DoMenuToggleWhole;
  end;

var
  OctreeTrianglesDisplay: TOctreeDisplay;
  OctreeVisibleShapesDisplay: TOctreeDisplay;
  OctreeCollidableShapesDisplay: TOctreeDisplay;

procedure OctreeDisplay(SceneAnimation: TCastlePrecalculatedAnimation);

function OctreeDisplayStatus: string;

implementation

uses CastleGL, CastleColors, CastleGLUtils, CastleShapes, SysUtils;

{ TOctreeDisplay ------------------------------------------------------------- }

constructor TOctreeDisplay.Init(const AName: string);
begin
  Whole := false;
  Depth := -1;
  Name := AName;
end;

procedure TOctreeDisplay.DoMenuIncDepth;
begin
  if Whole then
  begin
    Whole := false;
    MenuWhole.Checked := Whole;
    Depth := -1;
  end;

  Inc(Depth);
end;

procedure TOctreeDisplay.DoMenuDecDepth;
begin
  if Whole then
  begin
    Whole := false;
    MenuWhole.Checked := Whole;
    Depth := -1;
  end;

  Dec(Depth);
  if Depth < -1 then Depth := -1;
end;

procedure TOctreeDisplay.DoMenuToggleWhole;
begin
  Whole := not Whole;
  if not Whole then
    Depth := -1;
end;

procedure TOctreeDisplay.AddDisplayStatus(var S: string);
begin
  if Whole then
    S += Format(', Octree %s display: whole', [Name]) else
  if Depth <> -1 then
    S += Format(', Octree %s display: depth %d', [Name, Depth]);
end;

{ ---------------------------------------------------------------------------- }

procedure OctreeDisplay(SceneAnimation: TCastlePrecalculatedAnimation);
{$ifndef OpenGLES} //TODO-es

  procedure DisplayOctreeDepth(octreenode: TOctreeNode;
    OctreeDisplayDepth: integer);
  var
    b0, b1, b2: boolean;
  begin
    with octreenode do
      if Depth = OctreeDisplayDepth then
      begin
        if not (IsLeaf and (ItemsCount = 0)) then
          glDrawBox3DWire(Box);
      end else
      if not IsLeaf then
      begin
        for b0 := false to true do
          for b1 := false to true do
            for b2 := false to true do
              DisplayOctreeDepth(TreeSubNodes[b0, b1, b2], OctreeDisplayDepth);
      end;
  end;

  procedure DisplayOctreeTrianglesDepth(OctreeDisplayDepth: integer);
  var
    SI: TShapeTreeIterator;
  begin
    { Octree is not always ready, as it's recalculation during animations
      may hurt. Also, Draw may be called in various situations even when Scene
      is not really ready (e.g. when showing errors after scene loading).
      Also, octrees for particular shapes are not necessarily
      created, since some shapes may be not collidable.
      So we have to carefully check here whether appropriate things
      are initialized. }

    if (SceneAnimation <> nil) and
       (SceneAnimation.ScenesCount <> 0) then
    begin
      SI := TShapeTreeIterator.Create(SceneAnimation.FirstScene.Shapes, true);
      try
        while SI.GetNext do
          if SI.Current.OctreeTriangles <> nil then
          begin
            glPushMatrix;
              glMultMatrix(SI.Current.State.Transform);
              DisplayOctreeDepth(SI.Current.OctreeTriangles.TreeRoot,
                OctreeDisplayDepth);
            glPopMatrix;
          end;
      finally FreeAndNil(SI) end;
    end;
  end;

  procedure DisplayOctreeWhole(OctreeNode: TOctreeNode);
  var
    b0, b1, b2: boolean;
  begin
    with OctreeNode do
    begin
      if not (IsLeaf and (ItemsCount = 0)) then
        glDrawBox3DWire(Box);

      if not IsLeaf then
      begin
        for b0 := false to true do
          for b1 := false to true do
            for b2 := false to true do
              DisplayOctreeWhole(TreeSubNodes[b0, b1, b2]);
      end;
    end;
  end;

  procedure DisplayOctreeTrianglesWhole;
  var
    SI: TShapeTreeIterator;
  begin
    { Octree is not always ready, as it's recalculation during animations
      may hurt. Also, Draw may be called in various situations even when Scene
      is not really ready (e.g. when showing errors after scene loading).
      Also, octrees for particular shapes are not necessarily
      created, since some shapes may be not collidable.
      So we have to carefully check here whether appropriate things
      are initialized. }

    if (SceneAnimation <> nil) and
       (SceneAnimation.ScenesCount <> 0) then
    begin
      SI := TShapeTreeIterator.Create(SceneAnimation.FirstScene.Shapes, true);
      try
        while SI.GetNext do
          if SI.Current.OctreeTriangles <> nil then
          begin
            glPushMatrix;
              glMultMatrix(SI.Current.State.Transform);
              DisplayOctreeWhole(SI.Current.OctreeTriangles.TreeRoot);
            glPopMatrix;
          end;
      finally FreeAndNil(SI) end;
    end;
  end;

begin
  if OctreeTrianglesDisplay.Whole then
  begin
    glColorv(Yellow);
    DisplayOctreeTrianglesWhole;
  end else
  if OctreeTrianglesDisplay.Depth >= 0 then
  begin
    glColorv(Yellow);
    DisplayOctreeTrianglesDepth(OctreeTrianglesDisplay.Depth);
  end;

  if OctreeVisibleShapesDisplay.Whole then
  begin
    glColorv(Blue);
    DisplayOctreeWhole(SceneAnimation.FirstScene.OctreeRendering.TreeRoot);
  end else
  if OctreeVisibleShapesDisplay.Depth >= 0 then
  begin
    glColorv(Blue);
    DisplayOctreeDepth(SceneAnimation.FirstScene.OctreeRendering.TreeRoot,
      OctreeVisibleShapesDisplay.Depth);
  end;

  if OctreeCollidableShapesDisplay.Whole then
  begin
    glColorv(Red);
    DisplayOctreeWhole(SceneAnimation.FirstScene.OctreeDynamicCollisions.TreeRoot);
  end else
  if OctreeCollidableShapesDisplay.Depth >= 0 then
  begin
    glColorv(Red);
    DisplayOctreeDepth(SceneAnimation.FirstScene.OctreeDynamicCollisions.TreeRoot,
      OctreeCollidableShapesDisplay.Depth);
  end;
{$else}
begin
{$endif}
end;

function OctreeDisplayStatus: string;
begin
  Result := '';
  OctreeTrianglesDisplay       .AddDisplayStatus(Result);
  OctreeVisibleShapesDisplay   .AddDisplayStatus(Result);
  OctreeCollidableShapesDisplay.AddDisplayStatus(Result);
end;

initialization
  OctreeTrianglesDisplay       .Init('triangles');
  OctreeVisibleShapesDisplay   .Init('visible shapes');
  OctreeCollidableShapesDisplay.Init('collidable shapes');
end.
