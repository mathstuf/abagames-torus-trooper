/*
 * $Id: bullettarget.d,v 1.1.1.1 2004/11/10 13:45:22 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.bullettarget;

private import gl3n.linalg;

/**
 * Target that is aimed by bullets.
 */
public interface BulletTarget {
 public:
  vec2 getTargetPos();
}

public class VirtualBulletTarget: BulletTarget {
 public:
  vec2 pos;
 private:

  public this() {
    pos = vec2(0);
  }

  public vec2 getTargetPos() {
    return pos;
  }
}
