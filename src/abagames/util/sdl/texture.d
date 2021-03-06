/*
 * $Id: texture.d,v 1.1.1.1 2004/11/10 13:45:22 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.texture;

private import std.string;
private import derelict.sdl2.sdl;
private import abagames.util.support.gl;
private import abagames.util.support.paths;
private import abagames.util.sdl.sdlexception;

/**
 * Manage OpenGL textures.
 */
public class Texture {
 public:
  static string imagesDir = "images/";
 private:
  GLuint num;

  public this(string name) {
    string path = assetStoragePath();
    path ~= "/" ~ imagesDir ~ name;
    SDL_Surface *surface;
    surface = SDL_LoadBMP(std.string.toStringz(path));
    if (!surface)
      throw new SDLInitFailedException("Unable to load: " ~ path);
    glGenTextures(1, &num);
    glBindTexture(GL_TEXTURE_2D, num);
    glTexImage2D(GL_TEXTURE_2D, 0, 3, surface.w, surface.h, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, surface.pixels);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    /*gluBuild2DMipmaps(GL_TEXTURE_2D, 3, surface.w, surface.h,
      GL_RGB, GL_UNSIGNED_BYTE, surface.pixels);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);*/
  }

  public void deleteTexture() {
    glDeleteTextures(1, &num);
  }

  public void bind() {
    glBindTexture(GL_TEXTURE_2D, num);
  }
}
