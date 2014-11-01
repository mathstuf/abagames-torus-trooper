/*
 * $Id: bulletactorpool.d,v 1.4 2005/01/02 05:49:31 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.bulletactorpool;

private import std.math;
private import bml = bulletml.bulletml;
private import abagames.util.actor;
private import abagames.util.vector;
private import abagames.util.bulletml.bullet;
private import abagames.util.bulletml.bulletsmanager;
private import abagames.util.sdl.luminous;
private import abagames.tt.bulletactor;
private import abagames.tt.bulletimpl;
private import abagames.tt.bullettarget;
private import abagames.tt.tunnel;
private import abagames.tt.ship;
private import abagames.tt.shot;
private import abagames.tt.enemy;
private import abagames.tt.shape;

/**
 * Bullet actor pool that works as BulletsManager.
 */
public class BulletActorPool: ActorPool!(BulletActor), BulletsManager {
 private:
  int cnt;

  public this(int n, Object[] args) {
    super(n, args);
    Bullet.setBulletsManager(this);
    cnt = 0;
  }

  public void addBullet(Bullet parent, float deg, float speed) {
    //if ((cast(BulletImpl) Bullet.now).rootBullet.rootRank <= 0)
      //return;
    BulletActor rb = (cast(BulletImpl) parent).rootBullet;
    if (rb)
      if (rb.rootRank <= 0)
        return;
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return;
    BulletImpl nbi = ba.bullet;
    nbi.setParam(cast(BulletImpl) parent);
    if (nbi.gotoNextParser()) {
      bml.BulletMLRunner runner = bml.createRunner(nbi, nbi.getParser());
      ba.set(runner, Bullet.now.pos.x, Bullet.now.pos.y, deg, speed);
      ba.setMorphSeed();
    } else {
      ba.set(parent.pos.x, parent.pos.y, deg, speed * ba.bullet.getSpeedRank());
    }
  }

  public void addBullet(Bullet parent, const bml.ResolvedBulletML state, float deg, float speed) {
    BulletActor rb = (cast(BulletImpl) parent).rootBullet;
    if (rb)
      if (rb.rootRank <= 0)
        return;
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return;
    BulletImpl nbi = ba.bullet;
    bml.BulletMLRunner runner = bml.createRunner(nbi, state);
    nbi.setParam(cast(BulletImpl) parent);
    ba.set(runner, parent.pos.x, parent.pos.y, deg, speed);
  }

  public BulletActor addTopBullet(ParserParam[] parserParam,
                                  float x, float y, float deg, float speed,
                                  Drawable shape, Drawable disapShape,
                                  float xReverse, float yReverse, bool longRange,
                                  BulletTarget target,
                                  int prevWait, int postWait) {
    BulletActor ba = getInstance();
    if (!ba)
      return null;
    BulletImpl nbi = ba.bullet;
    nbi.setParamFirst(parserParam, shape, disapShape,
                      xReverse, yReverse, longRange, target, ba);
    bml.BulletMLRunner runner = bml.createRunner(nbi, nbi.getParser());
    ba.set(runner, x, y, deg, speed);
    ba.setWait(prevWait, postWait);
    ba.setTop();
    return ba;
  }

  public BulletActor addMoveBullet(bml.ResolvedBulletML parser, float speed,
                                   float x, float y, float deg, BulletTarget target) {
    BulletActor ba = getInstance();
    if (!ba)
      return null;
    BulletImpl bi = ba.bullet;
    bi.setParamFirst(null, null, null, 1, 1, false, target, ba);
    bml.BulletMLRunner runner = bml.createRunner(bi, bi.getParser());
    ba.set(runner, x, y, deg, speed);
    ba.setInvisible();
    return ba;
  }

  public override void move() {
    super.move();
    cnt++;
  }

  public void draw() {
    foreach (BulletActor ba; actor)
      if (ba.exists)
        ba.draw();
  }

  public int getTurn() {
    return cnt;
  }

  public void killMe(Bullet bullet) {
    assert((cast(BulletActor) actor[bullet.id]).bullet.id == bullet.id);
    (cast(BulletActor) actor[bullet.id]).remove();
  }

  public override void clear() {
    foreach (BulletActor ba; actor)
      if (ba.exists)
        ba.removeForced();
    actorIdx = 0;
    cnt = 0;
  }

  public void clearVisible() {
    foreach (BulletActor ba; actor)
      if (ba.exists)
        ba.startDisappear();
  }

  public void checkShotHit(Vector pos, Collidable shape, Shot shot) {
    foreach (BulletActor ba; actor)
      if (ba.exists)
        ba.checkShotHit(pos, shape, shot);
  }
}
