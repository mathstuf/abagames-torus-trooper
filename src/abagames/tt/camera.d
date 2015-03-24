/*
 * $Id: camera.d,v 1.4 2005/01/09 03:49:59 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.camera;

private import std.math;
private import gl3n.linalg;
private import abagames.util.rand;
private import abagames.tt.ship;
private import abagames.tt.screen;

/**
 * Handle a camera.
 */
public class Camera {
 private:
  static const int ZOOM_CNT = 24;
  static enum MoveType {
    FLOAT, FIX,
  };
  Ship ship;
  Rand rand;
  vec3 _cameraPos, cameraTrg, cameraVel;
  vec3 _lookAtPos, lookAtOfs;
  int lookAtCnt, changeCnt, moveCnt;
  float _deg;
  float _zoom;
  float zoomTrg, zoomMin;
  int type;

  public this(Ship ship) {
    this.ship = ship;
    _cameraPos = vec3(0);
    cameraTrg = vec3(0);
    cameraVel = vec3(0);
    _lookAtPos = vec3(0);
    lookAtOfs = vec3(0);
    _zoom = zoomTrg = 1;
    zoomMin = 0.5f;
    rand = new Rand;
    type = MoveType.FLOAT;
  }

  public void start() {
    changeCnt = 0;
    moveCnt = 0;
  }

  public void move() {
    changeCnt--;
    if (changeCnt < 0) {
      type = rand.nextInt(2);
      switch (type) {
      case MoveType.FLOAT:
        changeCnt = 256 + rand.nextInt(150);
        cameraTrg.x = ship.relPos.x + rand.nextSignedFloat(1);
        cameraTrg.y = ship.relPos.y - 12 + rand.nextSignedFloat(48);
        cameraTrg.z = rand.nextInt(32);
        cameraVel.x = (ship.relPos.x - cameraTrg.x) / changeCnt * (1 + rand.nextFloat(1));
        cameraVel.y = (ship.relPos.y - 12 - cameraTrg.y) / changeCnt * (1.5f + rand.nextFloat(0.8f));
        cameraVel.z = (16 - cameraTrg.z) / changeCnt * rand.nextFloat(1);
        _zoom = zoomTrg = 1.2f + rand.nextFloat(0.8f);
        break;
      case MoveType.FIX:
        changeCnt = 200 + rand.nextInt(100);
        cameraTrg.x = rand.nextSignedFloat(0.3f);
        cameraTrg.y = -8 - rand.nextFloat(12);
        cameraTrg.z = 8 + rand.nextInt(16);
        cameraVel.x = (ship.relPos.x - cameraTrg.x) / changeCnt * (1 + rand.nextFloat(1));
        cameraVel.y = rand.nextSignedFloat(0.05f);
        cameraVel.z = (10 - cameraTrg.z) / changeCnt * rand.nextFloat(0.5f);
        zoomTrg = 1.0f + rand.nextSignedFloat(0.25f);
        _zoom = 0.2f + rand.nextFloat(0.8f);
        break;
      default:
        assert(0);
      }
      _cameraPos = cameraTrg;
      _deg = cameraTrg.x;
      lookAtOfs = vec3(0);
      lookAtCnt = 0;
      zoomMin = 1.0f - rand.nextFloat(0.9f);
    }
    lookAtCnt--;
    if (lookAtCnt == ZOOM_CNT) {
      lookAtOfs.x = rand.nextSignedFloat(0.4f);
      lookAtOfs.y = rand.nextSignedFloat(3);
      lookAtOfs.z = rand.nextSignedFloat(10);
    } else if (lookAtCnt < 0) {
      lookAtCnt = 32 + rand.nextInt(48);
    }
    cameraTrg += cameraVel;
    vec3 co;
    switch (type) {
    case MoveType.FLOAT:
      co = cameraTrg;
      break;
    case MoveType.FIX:
      co = cameraTrg + vec3(ship.relPos, 0);
      float od = ship.relPos.x - _deg;
      while (od >= PI)
        od -= PI * 2;
      while (od < -PI)
        od += PI * 2;
      _deg += od * 0.2f;
      break;
    default:
      assert(0);
    }
    co -= cameraPos;
    while (co.x >= PI)
      co.x -= PI * 2;
    while (co.x < -PI)
      co.x += PI * 2;
    _cameraPos += co * 0.12f;
    float ofsRatio;
    if (lookAtCnt <= ZOOM_CNT)
      ofsRatio = 1.0f + fabs(zoomTrg - _zoom) * 2.5f;
    else
      ofsRatio = 1.0f;
    vec3 lo = vec3(ship.relPos, 0) + lookAtOfs * ofsRatio - _lookAtPos;
    while (lo.x >= PI)
      lo.x -= PI * 2;
    while (lo.x < -PI)
      lo.x += PI * 2;
    if (lookAtCnt <= ZOOM_CNT) {
      _zoom += (zoomTrg - _zoom) * 0.16f;
      _lookAtPos += lo * 0.2f;
    } else {
      _lookAtPos += lo * 0.1f;
    }
    lookAtOfs *= 0.985f;
    if (fabs(lookAtOfs.x) < 0.04f)
      lookAtOfs.x = 0;
    if (fabs(lookAtOfs.y) < 0.3f)
      lookAtOfs.y = 0;
    if (fabs(lookAtOfs.z) < 1)
      lookAtOfs.z = 0;
    moveCnt--;
    if (moveCnt < 0) {
      moveCnt = 15 + rand.nextInt(15);
      float _lox = fabs(_lookAtPos.x - _cameraPos.x);
      if (_lox > PI)
        _lox = PI * 2 - _lox;
      float ofs = _lox * 3 + fabs(_lookAtPos.y - _cameraPos.y);
      zoomTrg = 3.0f / ofs;
      if (zoomTrg < zoomMin)
        zoomTrg = zoomMin;
      else if (zoomTrg > 2)
        zoomTrg = 2;
    }
    if (_lookAtPos.x < 0)
      _lookAtPos.x += PI * 2;
    else if (_lookAtPos.x >= PI * 2)
      _lookAtPos.x -= PI * 2;
  }

  public vec3 cameraPos() {
    return _cameraPos;
  }

  public vec3 lookAtPos() {
    return _lookAtPos;
  }

  public float deg() {
    return _deg;
  }

  public float zoom() {
    return _zoom;
  }
}
