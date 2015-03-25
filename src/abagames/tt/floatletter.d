/*
 * $Id: floatletter.d,v 1.2 2005/01/01 12:40:27 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.floatletter;

private import std.math;
private import gl3n.linalg;
private import abagames.util.actor;
private import abagames.util.rand;
private import abagames.util.support.gl;
private import abagames.tt.letter;
private import abagames.tt.tunnel;
private import abagames.tt.screen;

/**
 * Floating letters(display the multiplier).
 */
public class FloatLetter: Actor {
 private:
  static Rand rand;
  Tunnel tunnel;
  vec3 pos;
  float mx, my;
  float d;
  float size;
  string msg;
  int cnt;
  float alpha;

  public static this() {
    rand = new Rand;
  }

  public static void setRandSeed(long seed) {
    rand.setSeed(seed);
  }

  public override void init(Object[] args) {
    tunnel = cast(Tunnel) args[0];
    pos = vec3(0);
  }

  public void set(string m, vec2 p, float s, int c = 120) {
    pos = vec3(p, 1);
    mx = rand.nextSignedFloat(0.001);
    my = -rand.nextFloat(0.2) + 0.2f;
    d = p.x;
    size = s;
    msg = m;
    cnt = c;
    alpha = 0.8f;
    exists = true;
  }

  public override void move() {
    pos.x += mx * pos.y;
    pos.y += my;
    pos.z -= 0.03f * pos.y;
    cnt--;
    if (cnt < 0)
      exists = false;
    if (alpha >= 0.03f)
      alpha -= 0.03f;
  }

  public override void draw(mat4 view) {
    vec3 sp = tunnel.getPos(pos);

    mat4 model = mat4.identity;
    model.translate(0, 0, sp.z);

    Letter.setColor(vec4(1, 1, 1, 1));
    Letter.drawString(view * model, msg, sp.x, sp.y, size, Letter.Direction.TO_RIGHT, Letter.LINE_COLOR, false, d  * 180 / PI);
    Letter.setColor(vec4(1, 1, 1, alpha));
    Letter.drawString(view * model, msg, sp.x, sp.y, size, Letter.Direction.TO_RIGHT, Letter.POLY_COLOR, false, d  * 180 / PI);
  }
}

public class FloatLetterPool: ActorPool!(FloatLetter) {
  public this(int n, Object[] args) {
    super(n, args);
  }
}
