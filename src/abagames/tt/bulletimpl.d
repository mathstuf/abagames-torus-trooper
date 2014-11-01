/*
 * $Id: bulletimpl.d,v 1.2 2005/01/01 12:40:27 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.bulletimpl;

private import std.math;
private import bml = bulletml.bulletml;
private import abagames.util.bulletml.bullet;
private import abagames.util.vector;
private import abagames.tt.bulletactor;
private import abagames.tt.bullettarget;
private import abagames.tt.shape;

/**
 * Bullet params of parsers, shape, the vertical/horizontal reverse moving, target, rootBullet.
 */
public class BulletImpl: Bullet {
 public:
  ParserParam[] parserParam;
  int parserIdx;
  Drawable shape, disapShape;
  float xReverse, yReverse;
  bool longRange;
  BulletTarget target;
  BulletActor rootBullet;
 private:

  public this(int id) {
    super(id);
  }

  public void setParamFirst(ParserParam[] parserParam,
                            Drawable shape, Drawable disapShape,
                            float xReverse, float yReverse, bool longRange,
                            BulletTarget target, BulletActor rootBullet) {
    this.parserParam = parserParam;
    this.shape = shape;
    this.disapShape = disapShape;
    this.xReverse = xReverse;
    this.yReverse = yReverse;
    this.longRange = longRange;
    this.target = target;
    this.rootBullet = rootBullet;
    parserIdx = 0;
  }

  public void setParam(BulletImpl bi) {
    parserParam = bi.parserParam;
    shape = bi.shape;
    disapShape = bi.disapShape;
    xReverse = bi.xReverse;
    yReverse = bi.yReverse;
    target = bi.target;
    //rootBullet = bi.rootBullet;
    rootBullet = null;
    parserIdx = bi.parserIdx;
    longRange = bi.longRange;
  }

  public bool gotoNextParser() {
    parserIdx++;
    if (parserIdx >= parserParam.length) {
      parserIdx--;
      return false;
    } else {
      return true;
    }
  }

  public double getAimDirection() {
    Vector b = pos;
    Vector t = activeTarget;
    float xrev = xReverse;
    float yrev = yReverse;
    float ox = t.x - b.x;
    if (ox > PI)
      ox -= PI * 2;
    else if (ox < -PI)
      ox += PI * 2;
    return rtod((atan2(ox, t.y - b.y) * xrev + PI / 2) * yrev - PI / 2);
  }

  public bml.ResolvedBulletML getParser() {
    return parserParam[parserIdx].parser;
  }

  public void resetParser() {
    parserIdx = 0;
  }

  public override float rank() {
    ParserParam pp = parserParam[parserIdx];
    //float r = pp.rank + (rootBullet.rootRank - 1) * pp.rootRankEffect * pp.rank;
    float r = pp.rank;
    if (r > 1)
      r = 1;
    return r;
  }

  public float getSpeedRank() {
    return parserParam[parserIdx].speed;
  }
}

public class ParserParam {
 public:
  bml.ResolvedBulletML parser;
  float rank;
  float rootRankEffect;
  float speed;

  public this(bml.ResolvedBulletML p, float r, float re, float s) {
    parser = p;
    rank = r;
    rootRankEffect = re;
    speed = s;
  }
}
