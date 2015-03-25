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
private import abagames.util.sdl.shaderprogram;
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
  static ShaderProgram sparkProgram;
  static GLuint sparkVao;
  static ShaderProgram starProgram;
  static GLuint starVao;
  static ShaderProgram fragmentProgram;
  static GLuint fragmentVao;
  static GLuint vbo;
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

  public override void close() {
    if (sparkProgram !is null) {
      glDeleteVertexArrays(1, &sparkVao);
      glDeleteVertexArrays(1, &starVao);
      glDeleteVertexArrays(1, &fragmentVao);
      glDeleteBuffers(1, &vbo);
      sparkProgram.close();
      starProgram.close();
      fragmentProgram.close();
      sparkProgram = null;
      starProgram = null;
      fragmentProgram = null;
    }
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

    if (sparkProgram !is null) {
      return;
    }

    glGenBuffers(1, &vbo);

    static const float[] BUF = [
      /*
      alphaFactor, offset,       factor,    padding */
      1,            0,     0,     1, 0,  1, 0, 0,
      0,           -SIZE, -SIZE, -1, 0,  1, 0, 0,
      0,            SIZE, -SIZE, -1, 0, -1, 0, 0,
      0,            SIZE,  SIZE,  1, 0, -1, 0, 0,
      0,           -SIZE, +SIZE,  0, 0,  0, 0, 0,
      0,           -SIZE, -SIZE,  0, 0,  0, 0, 0
    ];
    enum ALPHAFACTOR = 0;
    enum OFFSET = 1;
    enum FACTOR = 3;
    enum BUFSZ = 8;

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, BUF.length * float.sizeof, BUF.ptr, GL_STATIC_DRAW);

    sparkProgram = new ShaderProgram;
    sparkProgram.setVertexShader(
      "uniform mat4 projmat;\n"
      "uniform vec3 prevpos;\n"
      "uniform vec3 curpos;\n"
      "\n"
      "attribute float alphaFactor;\n"
      "attribute vec2 offset;\n"
      "\n"
      "varying float f_alphaFactor;\n"
      "\n"
      "void main() {\n"
      "  vec3 pos = (alphaFactor > 0.) ? prevpos : curpos;\n"
      "  gl_Position = projmat * vec4(pos + vec3(offset, 0.), 1);\n"
      "  f_alphaFactor = alphaFactor;\n"
      "}\n"
    );
    sparkProgram.setFragmentShader(
      "uniform vec3 color;\n"
      "uniform float brightness;\n"
      "uniform float alpha;\n"
      "\n"
      "varying float f_alphaFactor;\n"
      "\n"
      "void main() {\n"
      "  gl_FragColor = vec4(color * brightness, alpha * f_alphaFactor);\n"
      "}\n"
    );
    GLint alphaFactorLoc = 0;
    GLint offsetLoc = 1;
    sparkProgram.bindAttribLocation(alphaFactorLoc, "alphaFactor");
    sparkProgram.bindAttribLocation(offsetLoc, "offset");
    sparkProgram.link();
    sparkProgram.use();

    glGenVertexArrays(1, &sparkVao);
    glBindVertexArray(sparkVao);

    vertexAttribPointer(alphaFactorLoc, 1, BUFSZ, ALPHAFACTOR);
    glEnableVertexAttribArray(alphaFactorLoc);

    vertexAttribPointer(offsetLoc, 2, BUFSZ, OFFSET);
    glEnableVertexAttribArray(offsetLoc);

    starProgram = new ShaderProgram;
    starProgram.setVertexShader(
      "uniform mat4 projmat;\n"
      "uniform vec3 prevpos;\n"
      "uniform vec3 curpos;\n"
      "\n"
      "attribute float alphaFactor;\n"
      "\n"
      "varying float f_alphaFactor;\n"
      "\n"
      "void main() {\n"
      "  vec3 pos = (alphaFactor > 0.) ? prevpos : curpos;\n"
      "  gl_Position = projmat * vec4(pos, 1);\n"
      "  f_alphaFactor = alphaFactor;\n"
      "}\n"
    );
    starProgram.setFragmentShader(
      "uniform vec3 color;\n"
      "uniform float brightness;\n"
      "\n"
      "varying float f_alphaFactor;\n"
      "\n"
      "void main() {\n"
      "  gl_FragColor = vec4(color * brightness, (f_alphaFactor > 0.) ? 1. : 0.2);\n"
      "}\n"
    );
    starProgram.bindAttribLocation(alphaFactorLoc, "alphaFactor");
    starProgram.link();
    starProgram.use();

    glGenVertexArrays(1, &starVao);
    glBindVertexArray(starVao);

    vertexAttribPointer(alphaFactorLoc, 1, BUFSZ, ALPHAFACTOR);
    glEnableVertexAttribArray(alphaFactorLoc);

    fragmentProgram = new ShaderProgram;
    fragmentProgram.setVertexShader(
      "uniform mat4 projmat;\n"
      "uniform mat4 modelmat;\n"
      "uniform vec3 size;\n"
      "\n"
      "attribute vec3 factor;\n"
      "\n"
      "void main() {\n"
      "  gl_Position = projmat * modelmat * vec4(factor * size, 1);\n"
      "}\n"
    );
    fragmentProgram.setFragmentShader(
      "uniform vec3 color;\n"
      "uniform float brightness;\n"
      "uniform float alpha;\n"
      "\n"
      "void main() {\n"
      "  gl_FragColor = vec4(color * brightness, alpha);\n"
      "}\n"
    );
    GLint factorLoc = 0;
    fragmentProgram.bindAttribLocation(factorLoc, "factorLoc");
    fragmentProgram.link();
    fragmentProgram.use();

    glGenVertexArrays(1, &fragmentVao);
    glBindVertexArray(fragmentVao);

    vertexAttribPointer(factorLoc, 2, BUFSZ, FACTOR);
    glEnableVertexAttribArray(factorLoc);

    fragmentProgram.clear();
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
    sparkProgram.use();

    sparkProgram.setUniform("projmat", view);
    sparkProgram.setUniform("brightness", Screen.brightness);
    sparkProgram.setUniform("color", r, g, b);

    sparkProgram.setUniform("alpha", 0.5);
    sparkProgram.setUniform("prevpos", psp);
    sparkProgram.setUniform("curpos", sp);

    sparkProgram.useVao(sparkVao);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 6);

    if (inCourse) {
      sparkProgram.setUniform("alpha", 0.2);
      sparkProgram.setUniform("prevpos", rpsp);
      sparkProgram.setUniform("curpos", rsp);

      glDrawArrays(GL_TRIANGLE_FAN, 0, 6);
    }

    sparkProgram.clear();
  }

  private void drawStar(mat4 view) {
    starProgram.use();

    starProgram.setUniform("projmat", view);
    starProgram.setUniform("brightness", Screen.brightness);
    starProgram.setUniform("color", r, g, b);

    starProgram.setUniform("prevpos", psp);
    starProgram.setUniform("curpos", sp);

    starProgram.useVao(starVao);

    glDrawArrays(GL_LINES, 0, 2);

    starProgram.clear();
  }

  private void drawFragment(mat4 view) {
    mat4 model = mat4.identity;
    model.rotate(-d2 / 180 * PI, vec3(0, 1, 0));
    model.rotate(-d1 / 180 * PI, vec3(0, 0, 1));
    model.translate(sp.x, sp.y, sp.z);

    fragmentProgram.use();

    fragmentProgram.setUniform("projmat", view);
    fragmentProgram.setUniform("modelmat", model);
    fragmentProgram.setUniform("brightness", Screen.brightness);
    fragmentProgram.setUniform("color", r, g, b);
    fragmentProgram.setUniform("size", width, 0, height);

    fragmentProgram.useVao(fragmentVao);

    fragmentProgram.setUniform("alpha", 0.5);
    glDrawArrays(GL_LINE_LOOP, 0, 4);

    fragmentProgram.setUniform("alpha", 0.2);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

    fragmentProgram.clear();
  }

  public override void drawLuminous(mat4 view) {
    if (lumAlp < 0.2 || type != PType.SPARK) return;
    sparkProgram.use();

    sparkProgram.setUniform("projmat", view);
    sparkProgram.setUniform("brightness", Screen.brightness);
    sparkProgram.setUniform("color", r, g, b);

    sparkProgram.setUniform("alpha", lumAlp * 0.6);
    sparkProgram.setUniform("prevpos", psp);
    sparkProgram.setUniform("curpos", sp);

    sparkProgram.useVao(sparkVao);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 6);

    sparkProgram.clear();
  }
}

public class ParticlePool: LuminousActorPool!(Particle) {
  public this(int n, Object[] args) {
    super(n, args);
  }
}
