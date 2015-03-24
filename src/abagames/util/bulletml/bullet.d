/*
 * $Id: bullet.d,v 1.2 2005/01/01 12:40:28 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.bulletml.bullet;

private import std.math;
private import bml = bulletml.bulletml;
private import gl3n.linalg;
private import abagames.util.rand;
private import abagames.util.bulletml.bulletsmanager;

/**
 * Bullet controlled by BulletML.
 */
public class Bullet: bml.BulletManager {
 public:
  static vec2 activeTarget;
  vec2 pos, acc;
  float deg;
  float speed;
  int id;
 private:
  static Rand randSource;
  static BulletsManager manager;
  static const float VEL_SS_SDM_RATIO = 62.0 / 10;
  static const float VEL_SDM_SS_RATIO = 10.0 / 62;
  bml.BulletMLRunner runner;
  float _rank;

  public static this() {
    randSource = new Rand;
  }

  public static void setRandSeed(long s) {
    randSource.setSeed(s);
  }

  public static void setBulletsManager(BulletsManager bm) {
    manager = bm;
    activeTarget = vec2(0);
  }

  public this(int id) {
    pos = vec2(0);
    acc = vec2(0);
    this.id = id;
  }

  public void set(string name, bml.Value val) {
    assert(0);
  }

  public void remove(string name) {
    assert(0);
  }

  public bml.Value get(string name) {
    if (name == "rank") {
      return rank();
    } else if (name == "rand") {
      return rand();
    }

    assert(0);
  }

  public bml.Value rank() {
    return _rank;
  }

  public bml.Value rand() {
    return randSource.nextFloat(1);
  }

  public void createSimpleBullet(double deg, double speed) {
    manager.addBullet(this, dtor(deg), speed * VEL_SDM_SS_RATIO);
  }

  public void createBullet(const bml.ResolvedBulletML state, double deg, double speed) {
    manager.addBullet(this, state, dtor(deg), speed * VEL_SDM_SS_RATIO);
  }

  public uint getTurn() {
    return manager.getTurn();
  }

  public double getDirection() {
    return rtod(deg);
  }

  public double getAimDirection() {
    vec2 b = pos;
    vec2 t = activeTarget;
    return rtod(std.math.atan2(t.x - b.x, t.y - b.y));
  }

  public double getSpeed() {
    return speed * VEL_SS_SDM_RATIO;
  }

  public double getDefaultSpeed() {
    return 1;
  }

  public void vanish() {
    kill();
  }

  public void changeDirection(double d) {
    deg = dtor(d);
  }

  public void changeSpeed(double s) {
    speed = s * VEL_SDM_SS_RATIO;
  }

  public void accelX(double sx) {
    acc.x = sx * VEL_SDM_SS_RATIO;
  }

  public void accelY(double sy) {
    acc.y = sy * VEL_SDM_SS_RATIO;
  }

  public double getSpeedX() {
    return acc.x;
  }

  public double getSpeedY() {
    return acc.y;
  }

  public void set(float x, float y, float deg, float speed, float rank) {
    pos = vec2(x, y);
    acc = vec2(0);
    this.deg = deg;
    this.speed = speed;
    this.rank = rank;
    runner = null;
  }

  public void setRunner(bml.BulletMLRunner runner) {
    this.runner = runner;
  }

  public void set(bml.BulletMLRunner runner,
                  float x, float y, float deg, float speed, float rank) {
    set(x, y, deg, speed, rank);
    setRunner(runner);
  }

  public void move() {
    if (!runner.done()) {
      runner.run();
    }
  }

  public bool isEnd() {
    return runner.done();
  }

  public void kill() {
    manager.killMe(this);
  }

  public void remove() {
    if (runner) {
      runner = null;
    }
  }

  public float rank(float value) {
    return _rank = value;
  }

  protected float rtod(float a) {
    return a * 180 / std.math.PI;
  }

  protected float dtor(float a) {
    return a * std.math.PI / 180;
  }
}
