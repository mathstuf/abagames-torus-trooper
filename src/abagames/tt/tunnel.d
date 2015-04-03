/*
 * $Id: tunnel.d,v 1.3 2005/01/02 05:49:31 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.tunnel;

private import std.math;
private import gl3n.linalg;
private import abagames.util.math;
private import abagames.util.rand;
private import abagames.util.support.gl;
private import abagames.util.sdl.displaylist;
private import abagames.tt.ship;
private import abagames.tt.enemy;
private import abagames.tt.screen;

/**
 * Tunnel course manager.
 */
public class Tunnel {
 public:
  static final int DEPTH_NUM = 72;
  static final int SHIP_IDX_OFS = 5;
  static final float RAD_RATIO = 1.05;
 private:
  // Interval between slices gets longer as the distance from the eye position increases.
  static final float DEPTH_CHANGE_RATIO = 1.15;
  static final float DEPTH_RATIO_MAX = 80;
  Slice[] slice;
  float shipDeg, shipOfs, shipY;
  int shipIdx;
  vec3 shipPos;
  vec3 tpos;
  Torus torus;
  int torusIdx;
  float pointFrom;
  float sightDepth;
  Slice[] sliceBackward;

  public this() {
    slice = new Slice[DEPTH_NUM];
    foreach (ref Slice sl; slice)
      sl = new Slice;
    sliceBackward = new Slice[DEPTH_NUM];
    foreach (ref Slice sl; sliceBackward)
      sl = new Slice;
    shipPos = vec3(0);
    tpos = vec3(0);
  }

  public void start(Torus torus) {
    this.torus = torus;
    torusIdx = 0;
    pointFrom = 0;
    sightDepth = 0;
  }

  public void setSlices() {
    float ti = torusIdx;
    int pti;
    sightDepth = 0;
    float dr = 1;
    Slice ps = slice[0];
    ps.setFirst(pointFrom, torus.getSliceState(torusIdx), -shipIdx - shipOfs);
    for (int i = 1; i < slice.length; i++) {
      pti = cast(int) ti;
      ti += dr;
      sightDepth += dr;
      if (ti >= torus.sliceNum)
        ti -= torus.sliceNum;
      slice[i].set(ps, torus.getSliceStateWithRing(cast(int) ti, pti), dr,
                   sightDepth - shipIdx - shipOfs);
      if (i >= slice.length / 2 && dr < DEPTH_RATIO_MAX)
        dr *= DEPTH_CHANGE_RATIO;
      ps = slice[i];
    }
  }

  public void setSlicesBackward() {
    float ti = torusIdx;
    int pti;
    float sd = 0;
    float dr = -1;
    Slice ps = sliceBackward[0];
    ps.setFirst(pointFrom, torus.getSliceState(torusIdx), -shipIdx - shipOfs);
    for (int i = 1; i < sliceBackward.length; i++) {
      pti = cast(int) ti;
      ti += dr;
      sd += dr;
      if (ti < 0)
        ti += torus.sliceNum;
      sliceBackward[i].set(ps, torus.getSliceStateWithRing(pti, cast(int) ti), dr,
                           sd - shipIdx - shipOfs);
      if (i >= sliceBackward.length / 2 && dr > -DEPTH_RATIO_MAX)
        dr *= DEPTH_CHANGE_RATIO;
      ps = sliceBackward[i];
    }
  }

  public void goToNextSlice(int n) {
    if (n <= 0)
      return;
    torusIdx += n;
    for (int i = 0; i < n; i++) {
      pointFrom += slice[i].state.mp;
      pointFrom %= slice[i].state.pointNum;
      if (pointFrom < 0)
        pointFrom += slice[i].state.pointNum;
    }
    if (torusIdx >= torus.sliceNum) {
      torusIdx -= torus.sliceNum;
      pointFrom = 0;
    }
  }

  public void setShipPos(float d, float o, float y) {
    shipDeg = d;
    shipOfs = o;
    shipY = y;
    shipIdx = SHIP_IDX_OFS;
  }

  // Convert args(deg, sliceOffset, sliceIdx, radiusRatio) to a 3D position.
  public vec3 getPos(float d, float o, size_t si, float rr) {
    size_t nsi = si + 1;
    float r = slice[si].state.rad * (1 - o) + slice[nsi].state.rad * o;
    float d1 = slice[si].d1 * (1 - o) + slice[nsi].d1 * o;
    float d2 = slice[si].d2 * (1 - o) + slice[nsi].d2 * o;
    tpos = vec3(0, r * rr, 0);
    tpos.rollZ(d);
    tpos.rollY(d1);
    tpos.rollX(d2);
    tpos += slice[si].centerPos * (1 - o) + slice[nsi].centerPos * o;
    return tpos;
  }

  public vec3 getPosBackward(float d, float o, size_t si, float rr) {
    size_t nsi = si + 1;
    float r = sliceBackward[si].state.rad * (1 - o) + sliceBackward[nsi].state.rad * o;
    float d1 = sliceBackward[si].d1 * (1 - o) + sliceBackward[nsi].d1 * o;
    float d2 = sliceBackward[si].d2 * (1 - o) + sliceBackward[nsi].d2 * o;
    tpos = vec3(0, r * rr, 0);
    tpos.rollZ(d);
    tpos.rollY(d1);
    tpos.rollX(d2);
    tpos += sliceBackward[si].centerPos * (1 - o) + sliceBackward[nsi].centerPos * o;
    return tpos;
  }

  // Convert args(deg, sliceOffset, sliceIdx) to a 3D position.
  public vec3 getPos(float d, float o, size_t si) {
    return getPos(d, o, si, 1.0f);
  }

  // Convert a vector(deg, depth) to a 3D position.
  public vec3 getPos(vec2 p) {
    size_t si;
    float o;
    if (p.y >= -shipIdx - shipOfs) {
      calcIndex(p.y, si, o);
      return getPos(p.x, o, si, 1.0f);
    } else {
      calcIndexBackward(p.y, si, o);
      return getPosBackward(p.x, o, si, 1.0f);
    }
  }

  // Convert a vector(deg, depth, radiusRatio) to a 3D position.
  public vec3 getPos(vec3 p) {
    size_t si;
    float o;
    calcIndex(p.y, si, o);
    return getPos(p.x, o, si, RAD_RATIO - p.z / slice[si].state.rad);
  }

  public vec3 getCenterPos(float y, out float d1, out float d2) {
    size_t si;
    float o;
    y -= shipY;
    if (y < -getTorusLength() / 2)
      y += getTorusLength();
    if (y >= -shipIdx - shipOfs) {
      calcIndex(y, si, o);
      size_t nsi = si + 1;
      d1 = slice[si].d1 * (1 - o) + slice[nsi].d1 * o;
      d2 = slice[si].d2 * (1 - o) + slice[nsi].d2 * o;
      tpos = slice[si].centerPos * (1 - o) + slice[nsi].centerPos * o;
    } else {
      calcIndexBackward(y, si, o);
      size_t nsi = si + 1;
      d1 = sliceBackward[si].d1 * (1 - o) + sliceBackward[nsi].d1 * o;
      d2 = sliceBackward[si].d2 * (1 - o) + sliceBackward[nsi].d2 * o;
      tpos = sliceBackward[si].centerPos * (1 - o) + sliceBackward[nsi].centerPos * o;
    }
    return tpos;
  }

  public Slice getSlice(float y) {
    size_t si;
    float o;
    if (y >= -shipIdx - shipOfs) {
      calcIndex(y, si, o);
      return slice[si];
    } else {
      calcIndexBackward(y, si, o);
      return sliceBackward[si];
    }
  }

  public float checkInCourse(vec2 p) {
    Slice sl = getSlice(p.y);
    if (sl.isNearlyRound())
      return 0;
    float ld = sl.getLeftEdgeDeg();
    float rd = sl.getRightEdgeDeg();
    int rsl = checkDegInside(p.x, ld, rd);
    if (rsl == 0) {
      return 0;
    } else {
      float rad = sl.state.rad;
      float ofs;
      if (rsl == 1)
        ofs = p.x - rd;
      else
        ofs = ld - p.x;
      if (ofs >= PI * 2)
        ofs -= PI * 2;
      else if (ofs < 0)
        ofs += PI * 2;
      return ofs * rad * rsl;
    }
  }

  public static int checkDegInside(float d, float ld, float rd) {
    int rsl = 0;
    if (rd <= ld) {
      if (d > rd && d < ld) {
        if (d < (rd + ld) / 2)
          rsl = 1;
        else
          rsl = -1;
      }
    } else {
      if (d < ld || d > rd) {
        float cd = (ld + rd) / 2 + PI;
        if (cd >= PI * 2)
          cd -= PI * 2;
        if (cd >= PI) {
          if (d < cd && d > rd)
            rsl = 1;
          else
            rsl = -1;
        } else {
          if (d > cd && d < ld)
            rsl = -1;
          else
            rsl = 1;
        }
      }
    }
    return rsl;
  }

  public float getRadius(float z) {
    size_t si;
    float o;
    calcIndex(z, si, o);
    size_t nsi = si + 1;
    return slice[si].state.rad * (1.0f - o) + slice[nsi].state.rad * o;
  }

  private void calcIndex(in float z, out size_t idx, out float ofs) {
    idx = slice.length + 99999;
    for (size_t i = 1; i < slice.length; i++) {
      if (z < slice[i].depth) {
        idx = i - 1;
        ofs = (z - slice[idx].depth) / (slice[idx + 1].depth - slice[idx].depth);
        break;
      }
    }
    if (idx < 0) {
      idx = 0;
      ofs = 0;
    } else if (idx >= slice.length - 1) {
      idx = slice.length - 2;
      ofs = 0.99;
    }
    if (ofs.isNaN)
      ofs = 0;
    else if (ofs >= 1)
      ofs = 0.99;
  }

  private void calcIndexBackward(in float z, out size_t idx, out float ofs) {
    idx = sliceBackward.length + 99999;
    for (size_t i = 1; i < sliceBackward.length; i++) {
      if (z > sliceBackward[i].depth) {
        idx = i - 1;
        ofs = (sliceBackward[idx].depth - z) / (sliceBackward[idx + 1].depth - sliceBackward[idx].depth);
        break;
      }
    }
    if (idx < 0) {
      idx = 0;
      ofs = 0;
    } else if (idx >= sliceBackward.length - 1) {
      idx = sliceBackward.length - 2;
      ofs = 0.99;
    }
    if (ofs.isNaN)
      ofs = 0;
    else if (ofs >= 1)
      ofs = 0.99;
  }

  public bool checkInScreen(vec2 p, Ship ship) {
    return checkInScreen(p, ship, 0.03f, 28);
  }

  private bool checkInScreen(vec2 p, Ship ship, float v, float ofs) {
    float xr = fabs(p.x - ship.eyePos.x);
    if (xr > PI)
      xr = PI * 2 - xr;
    xr *= getRadius(0) / SliceState.DEFAULT_RAD;
    v *= (p.y + ofs);
    if (xr > v)
      return false;
    else
      return true;
  }

  public bool checkInSight(float y) {
    float oy = y - torusIdx;
    if (oy < 0)
      oy += getTorusLength();
    if (oy > 0 && oy < sightDepth - 1)
      return true;
    else
      return false;
  }

  public int getTorusLength() {
    return torus.sliceNum;
  }

  public void draw(mat4 view) {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    float lineBn = 0.4, polyBn = 0, lightBn = 0.5 - Slice.darkLineRatio * 0.2f;
    slice[slice.length - 1].setPointPos();
    for (size_t i = slice.length - 1; i >= 1; i--) {
      slice[i - 1].setPointPos();
      slice[i].draw(slice[i - 1], lineBn, polyBn, lightBn, this);
      lineBn *= 1.02;
      if (lineBn > 1)
        lineBn = 1;
      lightBn *= 1.02;
      if (lightBn > 1)
        lightBn = 1;
      if (i < slice.length / 2) {
        if (polyBn <= 0)
          polyBn = 0.2;
        polyBn *= 1.03;
        if (polyBn > 1)
          polyBn = 1;
      }
      if (i < slice.length * 0.75f) {
        lineBn *= 1.0f  - Slice.darkLineRatio * 0.05f;
        lightBn *= 1.0f + Slice.darkLineRatio * 0.02f;
      }
    }
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }

  public void drawBackward(mat4 view) {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    float lineBn = 0.4, polyBn = 0, lightBn = 0.5 - Slice.darkLineRatio * 0.2f;
    sliceBackward[sliceBackward.length - 1].setPointPos();
    for (size_t i = sliceBackward.length - 1; i >= 1; i--) {
      sliceBackward[i - 1].setPointPos();
      sliceBackward[i].draw(sliceBackward[i - 1], lineBn, polyBn, lightBn, this);
      lineBn *= 1.02;
      if (lineBn > 1)
        lineBn = 1;
      lightBn *= 1.02;
      if (lightBn > 1)
        lightBn = 1;
      if (i < slice.length / 2) {
        if (polyBn <= 0)
          polyBn = 0.2;
        polyBn *= 1.03;
        if (polyBn > 1)
          polyBn = 1;
      }
      if (i < slice.length * 0.75f) {
        lineBn *= 1.0f  - Slice.darkLineRatio * 0.05f;
        lightBn *= 1.0f + Slice.darkLineRatio * 0.02f;
      }
    }
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
  }
}

/**
 * A slice of the tunnel.
 */
public class Slice {
 public:
  static final float DEPTH = 5;
  static float lineR, lineG, lineB;
  static float polyR, polyG, polyB;
  static bool darkLine;
  static float darkLineRatio;
 private:
  SliceState _state;
  float _d1, _d2;
  float _pointFrom;
  vec3 _centerPos;
  float pointRatio;
  vec3[] pointPos;
  vec3 radOfs;
  vec3 polyPoint;
  float _depth;

  public this() {
    _state = new SliceState;
    _centerPos = vec3(0);
    pointPos = new vec3[SliceState.MAX_POINT_NUM];
    foreach (ref vec3 pp; pointPos)
      pp = vec3(0);
    radOfs = vec3(0);
    polyPoint = vec3(0);
  }

  public void setFirst(float pf, SliceState state, float dpt) {
    _centerPos = vec3(0);
    _d1 = _d2 = 0;
    _pointFrom = pf;
    _state.set(state);
    _depth = dpt;
    pointRatio = 1;
  }

  public void set(Slice prevSlice, SliceState state, float depthRatio, float dpt) {
    _d1 = prevSlice.d1 + state.md1 * depthRatio;
    _d2 = prevSlice.d2 + state.md2 * depthRatio;
    _centerPos = vec3(0, 0, DEPTH * depthRatio);
    _centerPos.rollY(_d1);
    _centerPos.rollX(_d2);
    _centerPos += prevSlice.centerPos;
    pointRatio = 1 + (fabs(depthRatio) - 1) * 0.02f;
    _pointFrom = prevSlice.pointFrom + state.mp * depthRatio;
    _pointFrom %= state.pointNum;
    if (_pointFrom < 0)
      _pointFrom += state.pointNum;
    _state.set(state);
    _depth = dpt;
  }

  public void draw(Slice prevSlice, float lineBn, float polyBn, float lightBn, Tunnel tunnel) {
    float pi = _pointFrom;
    float width = _state.courseWidth;
    float prevPi;
    bool isFirst = true;
    bool polyFirst = true;
    bool roundSlice = false;
    if (_state.courseWidth == _state.pointNum)
      roundSlice = true;
    for (;;) {
      if (!isFirst) {
        int psPi = cast(int) (pi * prevSlice.state.pointNum / _state.pointNum);
        int psPrevPi = cast(int) (prevPi * prevSlice.state.pointNum / _state.pointNum);
        Screen.setColor(lineR * lineBn, lineG * lineBn, lineB * lineBn);
        glBegin(GL_LINE_STRIP);
        Screen.glVertex(pointPos[cast(int) pi]);
        Screen.glVertex(prevSlice.pointPos[psPi]);
        Screen.glVertex(prevSlice.pointPos[psPrevPi]);
        glEnd();
        if (polyBn > 0) {
          if (roundSlice || (!polyFirst && width > 0)) {
            Screen.setColor(polyR, polyG, polyB, polyBn);
            glBegin(GL_TRIANGLE_FAN);
            polyPoint.blend(pointPos[cast(int) prevPi], prevSlice.pointPos[psPi], 0.9);
            Screen.glVertex(polyPoint);
            polyPoint.blend(pointPos[cast(int) pi], prevSlice.pointPos[psPrevPi], 0.9);
            Screen.glVertex(polyPoint);
            Screen.setColor(polyR, polyG, polyB, polyBn / 2);
            polyPoint.blend(pointPos[cast(int) prevPi], prevSlice.pointPos[psPi], 0.1);
            Screen.glVertex(polyPoint);
            polyPoint.blend(pointPos[cast(int) pi], prevSlice.pointPos[psPrevPi], 0.1);
            Screen.glVertex(polyPoint);
            glEnd();
          } else {
            polyFirst = false;
          }
        }
      } else {
        isFirst = false;
      }
      prevPi = pi;
      pi += pointRatio;
      while (pi >= _state.pointNum)
        pi -= _state.pointNum;
      if (width <= 0)
        break;
      width -= pointRatio;
    }
    if (_state.courseWidth < _state.pointNum) {
      pi = _pointFrom;
      int psPi = cast(int) (pi * prevSlice.state.pointNum / _state.pointNum);
      Screen.setColor(lineBn / 3 * 2, lineBn / 3 * 2, lineBn);
      glBegin(GL_LINE_STRIP);
      Screen.glVertex(pointPos[cast(int) pi]);
      Screen.glVertex(prevSlice.pointPos[psPi]);
      glEnd();
    }
    if (!roundSlice && lightBn > 0.2f) {
      drawSideLight(getLeftEdgeDeg() - 0.07f, lightBn);
      drawSideLight(getRightEdgeDeg() + 0.07f, lightBn);
    }
    if (_state.ring)
      if (lightBn > 0.2f)
        _state.ring.draw(lightBn * 0.7f, tunnel);
  }

  public void setPointPos() {
    float d = 0, md = PI * 2 / (_state.pointNum - 1);
    foreach (vec3 pp; pointPos) {
      radOfs = vec3(0, _state.rad * Tunnel.RAD_RATIO, 0);
      radOfs.rollZ(d);
      radOfs.rollY(_d1);
      radOfs.rollX(_d2);
      pp = radOfs + _centerPos;
      d += md;
    }
  }

  private void drawSideLight(float deg, float lightBn) {
    radOfs = vec3(0, _state.rad, 0);
    radOfs.rollZ(deg);
    radOfs.rollY(_d1);
    radOfs.rollX(_d2);
    radOfs += _centerPos;
    Screen.setColor(1 * lightBn, 1 * lightBn, 0.6 * lightBn);
    glBegin(GL_LINE_LOOP);
    glVertex3f(radOfs.x - 0.5, radOfs.y - 0.5, radOfs.z);
    glVertex3f(radOfs.x + 0.5, radOfs.y - 0.5, radOfs.z);
    glVertex3f(radOfs.x + 0.5, radOfs.y + 0.5, radOfs.z);
    glVertex3f(radOfs.x - 0.5, radOfs.y + 0.5, radOfs.z);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    Screen.setColor(0.5 * lightBn, 0.5 * lightBn, 0.3 * lightBn);
    glVertex3f(radOfs.x, radOfs.y, radOfs.z);
    Screen.setColor(0.9 * lightBn, 0.9 * lightBn, 0.6 * lightBn);
    glVertex3f(radOfs.x - 0.5, radOfs.y - 0.5, radOfs.z);
    glVertex3f(radOfs.x - 0.5, radOfs.y + 0.5, radOfs.z);
    glVertex3f(radOfs.x + 0.5, radOfs.y + 0.5, radOfs.z);
    glVertex3f(radOfs.x + 0.5, radOfs.y - 0.5, radOfs.z);
    glVertex3f(radOfs.x - 0.5, radOfs.y - 0.5, radOfs.z);
    glEnd();
  }

  public bool isNearlyRound() {
    if (_state.courseWidth >= _state.pointNum - 1)
      return true;
    else
      return false;
  }

  public float getLeftEdgeDeg() {
    return _pointFrom * PI * 2 / _state.pointNum;
  }

  public float getRightEdgeDeg() {
    float rd = (_pointFrom + _state.courseWidth) * PI * 2 / _state.pointNum;
    if (rd >= PI * 2)
      rd -= PI * 2;
    return rd;
  }

  public SliceState state() {
    return _state;
  }

  public float d1() {
    return _d1;
  }

  public float d2() {
    return _d2;
  }

  public vec3 centerPos() {
    return _centerPos;
  }

  public float pointFrom() {
    return _pointFrom;
  }

  public float depth() {
    return _depth;
  }
}

/**
 * Torus(Circuit data).
 */
public class Torus {
 private:
  static const int LENGTH = 5000;
  int _sliceNum;
  TorusPart[] torusPart;
  Rand rand;
  size_t tpIdx;
  Ring[] ring;

  public this() {
    rand = new Rand;
    ring = null;
  }

  public void create(long seed) {
    rand.setSeed(seed);
    tpIdx = 0;
    torusPart = null;
    _sliceNum = 0;
    int tl = LENGTH;
    SliceState prev = new SliceState;
    while (tl > 0) {
      TorusPart tp = new TorusPart;
      int lgt = 64 + rand.nextInt(30);
      tp.create(prev, _sliceNum, lgt, rand);
      prev = tp.sliceState;
      torusPart ~= tp;
      tl -= tp.sliceNum;
      _sliceNum += tp.sliceNum;
    }
    torusPart[0].sliceState.init();
    torusPart[torusPart.length - 1].sliceState.init();
    ring = null;
    int ri = 5;
    while (ri < _sliceNum - 100) {
      SliceState ss = getSliceState(ri);
      if (ri == 5)
        ring ~= new Ring(ri, ss, 1);
      else
        ring ~= new Ring(ri, ss);
      ri += 100 + rand.nextInt(200);
    }
  }

  public void close() {
    if (ring)
      foreach (Ring r; ring)
        r.close();
  }

  public TorusPart getTorusPart(size_t idx) {
    for (size_t i = 0; i < torusPart.length; i++) {
      if (torusPart[tpIdx].contains(idx))
        break;
      tpIdx++;
      if (tpIdx >= torusPart.length)
        tpIdx = 0;
    }
    return torusPart[tpIdx];
  }

  public SliceState getSliceState(size_t idx) {
    TorusPart tp = getTorusPart(idx);
    size_t prvTpIdx = tpIdx - 1;
    if (prvTpIdx < 0 || tpIdx == 0)
      prvTpIdx = torusPart.length - 1;
    SliceState ss = tp.createBlendedSliceState(torusPart[prvTpIdx].sliceState, idx);
    return ss;
  }

  public SliceState getSliceStateWithRing(size_t idx, size_t pidx) {
    SliceState ss = getSliceState(idx);
    ss.ring = null;
    foreach (Ring r; ring) {
      if (idx > pidx) {
        if (r.idx <= idx && r.idx > pidx) {
          ss.ring = r;
          break;
        }
      } else {
        if (r.idx <= idx || r.idx > pidx) {
          ss.ring = r;
          break;
        }
      }
    }
    if (ss.ring)
      ss.ring.move();
    return ss;
  }

  public int sliceNum() {
    return _sliceNum;
  }
}

public class TorusPart {
 private:
  int _sliceNum;
  SliceState _sliceState;
  int sliceIdxFrom;
  int sliceIdxTo;
  SliceState blendedSliceState;
  static const float BLEND_DISTANCE = 64;

  public this() {
    _sliceState = new SliceState;
    blendedSliceState = new SliceState;
  }

  public void create(SliceState prev, int sliceIdx, int sn, Rand rand) {
    _sliceState.set(prev);
    _sliceState.changeDeg(rand);
    if (fabs(prev._mp) >= 1) {
      if (rand.nextInt(2) == 0) {
        if (prev._mp >= 1) {
          _sliceState.changeToTightCurve(rand, -1);
        } else {
          _sliceState.changeToTightCurve(rand, 1);
        }
      } else {
        _sliceState.changeToStraight();
      }
    } else if (prev.courseWidth == prev.pointNum || rand.nextInt(2) == 0) {
      switch (rand.nextInt(3)) {
      case 0:
        _sliceState.changeRad(rand);
        break;
      case 1:
        _sliceState.changeWidth(rand);
        break;
      case 2:
        _sliceState.changeWidthToFull();
        break;
      default:
        assert(0);
      }
    } else {
      switch (rand.nextInt(4)) {
      case 0:
        _sliceState.changeToTightCurve(rand);
        break;
      case 2:
        _sliceState.changeToEasyCurve(rand);
        break;
      default:
        _sliceState.changeToStraight();
        break;
      }
    }
    _sliceNum = sn;
    sliceIdxFrom = sliceIdx;
    sliceIdxTo = sliceIdx + _sliceNum;
  }

  public bool contains(size_t idx) {
    if (idx >= sliceIdxFrom && idx < sliceIdxTo)
      return true;
    else
      return false;
  }

  public SliceState createBlendedSliceState(SliceState blendee, size_t idx) {
    size_t dst = idx - sliceIdxFrom;
    float blendRatio = cast(float) dst / BLEND_DISTANCE;
    if (blendRatio >= 1)
      return _sliceState;
    blendedSliceState.blend(_sliceState, blendee, blendRatio);
    return blendedSliceState;
  }

  public int sliceNum() {
    return _sliceNum;
  }

  public SliceState sliceState() {
    return _sliceState;
  }
}

public class SliceState {
 public:
  static final int MAX_POINT_NUM = 36;
  static final int DEFAULT_POINT_NUM = 24;
  static final float DEFAULT_RAD = 21;
 private:
  float _md1, _md2;
  float _rad;
  int _pointNum;
  float _courseWidth;
  float _mp;
  Ring _ring;

  public this() {
    init();
  }

  public void init() {
    _md1 = _md2 = 0;
    _rad = DEFAULT_RAD;
    _pointNum = DEFAULT_POINT_NUM;
    _courseWidth = _pointNum;
    _mp = 0;
    _ring = null;
  }

  public void changeDeg(Rand rand) {
    _md1 = rand.nextSignedFloat(0.005);
    _md2 = rand.nextSignedFloat(0.005);
  }

  public void changeRad(Rand rand) {
    _rad = DEFAULT_RAD + rand.nextSignedFloat(DEFAULT_RAD * 0.3f);
    int ppn = _pointNum;
    _pointNum = cast(int) (_rad * DEFAULT_POINT_NUM / DEFAULT_RAD);
    if (ppn == _courseWidth)
      changeWidthToFull();
    else
      _courseWidth = _courseWidth * _pointNum / ppn;
  }

  public void changeWidth(Rand rand) {
    _courseWidth = rand.nextInt(_pointNum / 4) + _pointNum * 0.36f;
  }

  public void changeWidthToFull() {
    _courseWidth = _pointNum;
  }

    public void changeToStraight() {
    _mp = 0;
  }

  public void changeToEasyCurve(Rand rand) {
    _mp = rand.nextFloat(0.05) + 0.04;
    if (rand.nextInt(2) == 0)
      _mp = -_mp;
  }

  public void changeToTightCurve(Rand rand) {
    changeToTightCurve(rand, rand.nextInt(2) * 2 - 1);
  }

  public void changeToTightCurve(Rand rand, int dir) {
    _mp = (rand.nextFloat(0.04) + 0.1) * dir;
  }

  public void blend(SliceState s1, SliceState s2, float ratio) {
    _md1 = s1.md1 * ratio + s2.md1 * (1 - ratio);
    _md2 = s1.md2 * ratio + s2.md2 * (1 - ratio);
    _rad = s1.rad * ratio + s2.rad * (1 - ratio);
    _pointNum = cast(int) (s1.pointNum * ratio + s2.pointNum * (1 - ratio));
    if (s1.courseWidth == s1._pointNum && s2.courseWidth == s2._pointNum)
      _courseWidth = _pointNum;
    else
      _courseWidth = s1.courseWidth * ratio + s2.courseWidth * (1 - ratio);
    _mp = s1.mp;
  }

  public void set(SliceState s) {
    _md1 = s.md1;
    _md2 = s.md2;
    _rad = s.rad;
    _pointNum = s.pointNum;
    _courseWidth = s.courseWidth;
    _mp = s.mp;
    _ring = s.ring;
  }

  public float md1() {
    return _md1;
  }

  public float md2() {
    return _md2;
  }

  public float rad() {
    return _rad;
  }

  public int pointNum() {
    return _pointNum;
  }

  public float courseWidth() {
    return _courseWidth;
  }

  public float mp() {
    return _mp;
  }

  public Ring ring() {
    return _ring;
  }

  public Ring ring(Ring v) {
    return _ring = v;
  }
}

public class Ring {
 private:
  static const float[][] COLOR_RGB = [[0.5, 1, 0.9], [1, 0.9, 0.5]];
  size_t _idx;
  DisplayList displayList;
  int cnt;
  int clr;
  int type;

  public this(size_t idx, SliceState ss, int type = 0) {
    _idx = idx;
    cnt = 0;
    this.type = type;
    float r = ss.rad;
    switch (type) {
    case 0:
      createNormalRing(r);
      break;
    case 1:
      createFinalRing(r);
      break;
    default:
      assert(0);
    }
  }

  private void createNormalRing(float r) {
    displayList = new DisplayList(1);
    displayList.beginNewList();
    drawRing(r, 1.2, 1.4, 16);
    displayList.endNewList();
  }

  private void createFinalRing(float r) {
    displayList = new DisplayList(2);
    displayList.beginNewList();
    drawRing(r, 1.2, 1.5, 14);
    displayList.nextNewList();
    drawRing(r, 1.6, 1.9, 14);
    displayList.endNewList();
  }

  private void drawRing(float r, float rr1, float rr2, int num) {
    float d = 0, md = 0.2;
    for (int i = 0; i < num; i++) {
      glBegin(GL_LINE_LOOP);
      vec3 p1 = vec3(sin(d) * r * rr1, cos(d) * r * rr1, 0);
      vec3 p2 = vec3(sin(d) * r * rr2, cos(d) * r * rr2, 0);
      vec3 p3 = vec3(sin(d + md) * r * rr2, cos(d + md) * r * rr2, 0);
      vec3 p4 = vec3(sin(d + md) * r * rr1, cos(d + md) * r * rr1, 0);
      vec3 cp = vec3(0);
      cp += p1;
      cp += p2;
      cp += p3;
      cp += p4;
      cp *= 0.25;
      vec3 np1 = vec3(0);
      vec3 np2 = vec3(0);
      vec3 np3 = vec3(0);
      vec3 np4 = vec3(0);
      np1.blend(p1, cp, 0.7);
      np2.blend(p2, cp, 0.7);
      np3.blend(p3, cp, 0.7);
      np4.blend(p4, cp, 0.7);
      Screen.glVertex(np1);
      Screen.glVertex(np2);
      Screen.glVertex(np3);
      Screen.glVertex(np4);
      glEnd();
      d += md;
    }
  }

  public void close() {
    displayList.close();
  }

  public void move() {
    cnt++;
  }

  public void draw(float a, Tunnel tunnel) {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    float d1, d2;
    vec3 p = tunnel.getCenterPos(_idx, d1 ,d2);
    Screen.setColor(COLOR_RGB[type][0] * a,
                    COLOR_RGB[type][1] * a,
                    COLOR_RGB[type][2] * a);
    glPushMatrix();
    glTranslatef(p.x, p.y, p.z);
    glRotatef(cnt * 1.0f, 0, 0, 1);
    glRotatef(d1, 0, 1, 0);
    glRotatef(d2, 1, 0, 0);
    displayList.call(0);
    glPopMatrix();
    if (type == 1) {
      glPushMatrix();
      glTranslatef(p.x, p.y, p.z);
      glRotatef(cnt * -1.0f, 0, 0, 1);
      glRotatef(d1, 0, 1, 0);
      glRotatef(d2, 1, 0, 0);
      displayList.call(1);
      glPopMatrix();
    }
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }

  public size_t idx() {
    return _idx;
  }
}
