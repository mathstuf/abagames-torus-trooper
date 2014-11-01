/*
 * $Id: math.d,v 1.1.1.1 2004/11/10 13:45:22 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.math;

private import std.math;
private import gl3n.linalg;

real fastdist(vec2 v1, vec2 v2 = vec2(0)) {
  float ax = fabs(v1.x - v2.x);
  float ay = fabs(v1.y - v2.y);
  if (ax > ay)
    return ax + ay / 2;
  else
    return ay + ax / 2;
}

void rollX(ref vec3 v, float d) {
  float ty = v.y * cos(d) - v.z * sin(d);
  v.z = v.y * sin(d) + v.z * cos(d);
  v.y = ty;
}

void rollY(ref vec3 v, float d) {
  float tx = v.x * cos(d) - v.z * sin(d);
  v.z = v.x * sin(d) + v.z * cos(d);
  v.x = tx;
}

void rollZ(ref vec3 v, float d) {
  float tx = v.x * cos(d) - v.y * sin(d);
  v.y = v.x * sin(d) + v.y * cos(d);
  v.x = tx;
}

void blend(ref vec3 v, vec3 v1, vec3 v2, float ratio) {
  v = v1 * ratio + v2 * (1f - ratio);
}
