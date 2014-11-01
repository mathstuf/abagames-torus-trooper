/*
 * $Id: screen3d.d,v 1.2 2005/01/01 12:40:28 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.screen3d;

private import std.conv;
private import std.string;
private import derelict.sdl2.sdl;
private import derelict.opengl3.gl;
private import abagames.util.vector;
private import abagames.util.sdl.screen;
private import abagames.util.sdl.sdlexception;

/**
 * SDL screen handler(3D, OpenGL).
 */
public class Screen3D: Screen {
 public:
  static float brightness = 1;
  static int width = 640;
  static int height = 480;
  static bool windowMode = false;
  static float nearPlane = 0.1;
  static float farPlane = 1000;

 private:
  SDL_Window* _window = null;

  protected abstract void init();
  protected abstract void close();

  public void initSDL() {
    // Initialize Derelict.
    DerelictSDL2.load();
    DerelictGL.load(); // We use deprecated features.
    // Initialize SDL.
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
      throw new SDLInitFailedException(
        "Unable to initialize SDL: " ~ to!string(SDL_GetError()));
    }
    // Create an OpenGL screen.
    Uint32 videoFlags;
    int winheight = height;
    int winwidth = width;
    if (windowMode) {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;
    } else {
      winheight = 0;
      winwidth = 0;
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN_DESKTOP;
    }
    _window = SDL_CreateWindow("",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        winwidth, winheight, videoFlags);
    if (_window == null) {
      throw new SDLInitFailedException(
        ("Unable to create SDL screen: " ~ to!string(SDL_GetError())));
    }
    SDL_GL_CreateContext(_window);
    DerelictGL.reload();
    glViewport(0, 0, width, height);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    resized(width, height);
    SDL_ShowCursor(SDL_DISABLE);
    init();
  }

  // Reset viewport when the screen is resized.

  public void screenResized() {
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    //gluPerspective(45.0f, cast(GLfloat) width / cast(GLfloat) height, nearPlane, farPlane);
    glFrustum(-nearPlane,
              nearPlane,
              -nearPlane * cast(GLfloat) height / cast(GLfloat) width,
              nearPlane * cast(GLfloat) height / cast(GLfloat) width,
              0.1f, farPlane);
    glMatrixMode(GL_MODELVIEW);
  }

  public void resized(int width, int height) {
    this.width = width;
    this.height = height;
    screenResized();
  }

  public void closeSDL() {
    close();
    SDL_ShowCursor(SDL_ENABLE);
  }

  public void flip() {
    handleError();
    SDL_GL_SwapWindow(_window);
  }

  public void clear() {
    glClear(GL_COLOR_BUFFER_BIT);
  }

  public void handleError() {
    GLenum error = glGetError();
    if (error == GL_NO_ERROR)
      return;
    closeSDL();
    throw new Exception("OpenGL error(" ~ to!string(error) ~ ")");
  }

  protected void setCaption(string name) {
    SDL_SetWindowTitle(_window, std.string.toStringz(name));
  }

  public static void setColor(float r, float g, float b, float a = 1) {
    glColor4f(r * brightness, g * brightness, b * brightness, a);
  }

  public static void setClearColor(float r, float g, float b, float a = 1) {
    glClearColor(r * brightness, g * brightness, b * brightness, a);
  }

  public static void glVertex(Vector3 v) {
    glVertex3f(v.x, v.y, v.z);
  }

  public static void glTranslate(Vector3 v) {
    glTranslatef(v.x, v.y, v.z);
  }
}
