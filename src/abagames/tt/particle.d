/*
 * $Id: particle.d,v 1.3 2005/01/01 12:40:28 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.particle;

private import std.math;
private import abagames.util.actor;
private import abagames.util.support.gl;
private import gl3n.linalg;
private import abagames.util.rand;
private import abagames.util.sdl.luminous;
private import abagames.tt.tunnel;
private import abagames.tt.ship;
private import abagames.tt.screen;

/**
 * Particles.
 */
public class Particle: LuminousActor {
 public:
  static enum PType {
    SPARK, STAR, FRAGMENT, JET,
  };
 private:
  static const float GRAVITY = 0.02;
  static const float SIZE = 0.3;
  static Rand rand;
  Tunnel tunnel;
  Ship ship;
  vec3 pos;
  vec3 vel;
  vec3 sp, psp;
  vec3 rsp, rpsp;  // Mirror point.
  vec2 icp;
  float r, g, b;
  float lumAlp;
  int cnt;
  bool inCourse;
  int type;
  float d1, d2, md1, md2;
  float width, height;

  public static this() {
    rand = new Rand;
  }

  public static void setRandSeed(long seed) {
    rand.setSeed(seed);
  }

  public override void init(Object[] args) {
    tunnel = cast(Tunnel) args[0];
    ship = cast(Ship) args[1];
    pos = vec3(0);
    vel = vec3(0);
    sp = vec3(0);
    psp = vec3(0);
    rsp = vec3(0);
    rpsp = vec3(0);
    icp = vec2(0);
  }

  public void set(vec2 p, float z, float d, float mz, float speed,
                  float r, float g, float b, int c = 16,
                  int t = PType.SPARK, float w = 0, float h = 0) {
    pos = vec3(p, z);
    float sb = rand.nextFloat(0.8) + 0.4;
    vel.x = sin(d) * speed * sb;
    vel.y = cos(d) * speed * sb;
    vel.z = mz;
    this.r = r;
    this.g = g;
    this.b = b;
    cnt = c + rand.nextInt(c / 2);
    type = t;
    lumAlp = 0.8 + rand.nextFloat(0.2);
    if (type == PType.STAR)
      inCourse = false;
    else
      inCourse = true;
    if (type == PType.FRAGMENT) {
      d1 = d2 = 0;
      md1 = rand.nextSignedFloat(12);
      md2 = rand.nextSignedFloat(12);
      width = w;
      height = h;
    }
    checkInCourse();
    calcScreenPos();
    exists = true;
  }

  public override void move() {
    cnt--;
    //if (cnt < 0 || (type == PType.STAR && sp.z < -2)) {
    if (cnt < 0 || pos.y < -2) {
      exists = false;
      return;
    }
    psp = sp;
    if (inCourse) {
      rpsp = rsp;
    }
    pos += vel;
    if (type == PType.FRAGMENT)
      pos.y -= ship.speed / 2;
    else if (type == PType.SPARK)
      pos.y -= ship.speed * 0.33f;
    else
      pos.y -= ship.speed;
    if (type != PType.STAR) {
      if (type == PType.FRAGMENT)
        vel.z -= GRAVITY / 2;
      else
        vel.z -= GRAVITY;
      if (inCourse && pos.z < 0) {
        if (type == PType.FRAGMENT)
          vel.z *= -0.6;
        else
          vel.z *= -0.8;
        vel *= 0.9;
        pos.z += vel.z * 2;
        checkInCourse();
      }
    }
    if (type == PType.FRAGMENT) {
      d1 += md1;
      d2 += md2;
      md1 *= 0.98f;
      md2 *= 0.98f;
      width *= 0.98f;
      height *= 0.98f;
    }
    lumAlp *= 0.98;
    calcScreenPos();
  }

  private void calcScreenPos() {
    vec3 p = tunnel.getPos(pos);
    sp = p;
    if (inCourse) {
      pos.z = -pos.z;
      p = tunnel.getPos(pos);
      rsp = p;
      pos.z = -pos.z;
    }
  }

  private void checkInCourse() {
    icp = pos.xy;
    if (tunnel.checkInCourse(icp) != 0)
      inCourse = false;
  }

  public override void draw(mat4 view) {
    switch (type) {
    case PType.SPARK:
    case PType.JET:
      drawSpark(view);
      break;
    case PType.STAR:
      drawStar(view);
      break;
    case PType.FRAGMENT:
      drawFragment(view);
      break;
    default:
      assert(0);
    }
  }

  private void drawSpark(mat4 view) {
    glBegin(GL_TRIANGLE_FAN);
    Screen.setColor(r, g, b, 0.5);
    Screen.glVertex(psp);
    Screen.setColor(r, g, b, 0);
    glVertex3f(sp.x - SIZE, sp.y - SIZE, sp.z);
    glVertex3f(sp.x + SIZE, sp.y - SIZE, sp.z);
    glVertex3f(sp.x + SIZE, sp.y + SIZE, sp.z);
    glVertex3f(sp.x - SIZE, sp.y + SIZE, sp.z);
    glVertex3f(sp.x - SIZE, sp.y - SIZE, sp.z);
    glEnd();
    if (inCourse) {
      glBegin(GL_TRIANGLE_FAN);
      Screen.setColor(r, g, b, 0.2);
      Screen.glVertex(rpsp);
      Screen.setColor(r, g, b, 0);
      glVertex3f(rsp.x - SIZE, rsp.y - SIZE, sp.z);
      glVertex3f(rsp.x + SIZE, rsp.y - SIZE, sp.z);
      glVertex3f(rsp.x + SIZE, rsp.y + SIZE, sp.z);
      glVertex3f(rsp.x - SIZE, rsp.y + SIZE, sp.z);
      glVertex3f(rsp.x - SIZE, rsp.y - SIZE, sp.z);
      glEnd();
    }
  }

  private void drawStar(mat4 view) {
    glBegin(GL_LINES);
    Screen.setColor(r, g, b, 1);
    Screen.glVertex(psp);
    Screen.setColor(r, g, b, 0.2);
    Screen.glVertex(sp);
    glEnd();
  }

  private void drawFragment(mat4 view) {
    mat4 model = mat4.identity;
    model.rotate(-d2 / 180 * PI, vec3(0, 1, 0));
    model.rotate(-d1 / 180 * PI, vec3(0, 0, 1));
    model.translate(sp.x, sp.y, sp.z);

    glPushMatrix();
    glTranslatef(sp.x, sp.y, sp.z);
    glRotatef(d1, 0, 0, 1);
    glRotatef(d2, 0, 1, 0);
    glBegin(GL_LINE_LOOP);
    Screen.setColor(r, g, b, 0.5);
    glVertex3f(width, 0, height);
    glVertex3f(-width, 0, height);
    glVertex3f(-width, 0, -height);
    glVertex3f(width, 0, -height);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    Screen.setColor(r, g, b, 0.2);
    glVertex3f(width, 0, height);
    glVertex3f(-width, 0, height);
    glVertex3f(-width, 0, -height);
    glVertex3f(width, 0, -height);
    glEnd();
    glPopMatrix();
  }

  public override void drawLuminous(mat4 view) {
    if (lumAlp < 0.2 || type != PType.SPARK) return;
    glBegin(GL_TRIANGLE_FAN);
    Screen.setColor(r, g, b, lumAlp * 0.6);
    Screen.glVertex(psp);
    Screen.setColor(r, g, b, 0);
    glVertex3f(sp.x - SIZE, sp.y - SIZE, sp.z);
    glVertex3f(sp.x + SIZE, sp.y - SIZE, sp.z);
    glVertex3f(sp.x + SIZE, sp.y + SIZE, sp.z);
    glVertex3f(sp.x - SIZE, sp.y + SIZE, sp.z);
    glVertex3f(sp.x - SIZE, sp.y - SIZE, sp.z);
    glEnd();
  }
}

public class ParticlePool: LuminousActorPool!(Particle) {
  public this(int n, Object[] args) {
    super(n, args);
  }
}
