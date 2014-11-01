/*
 * $Id: boot.d,v 1.2 2005/01/01 12:40:27 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.tt.boot;

private import std.string;
private import std.stream;
private import std.c.stdlib;
private import abagames.util.logger;
private import abagames.util.tokenizer;
private import abagames.util.sdl.mainloop;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.recordablepad;
private import abagames.util.sdl.sound;
private import abagames.tt.screen;
private import abagames.tt.gamemanager;
private import abagames.tt.prefmanager;

/**
 * Boot the game.
 */
private:
Screen screen;
Pad input;
GameManager gameManager;
PrefManager prefManager;
MainLoop mainLoop;

// Boot as the general executable.
public int main(string[] args) {
  return boot(args);
}

public int boot(string[] args) {
  screen = new Screen;
  input = new RecordablePad;
  gameManager = new GameManager;
  prefManager = new PrefManager;
  mainLoop = new MainLoop(screen, input, gameManager, prefManager);
  try {
    parseArgs(args);
  } catch (Exception e) {
    Logger.info(e.toString());
    return EXIT_FAILURE;
  }
  try {
    mainLoop.loop();
  } catch (Throwable o) {
    Logger.info(o.toString());
    try {
      gameManager.saveErrorReplay();
    } catch (Throwable o1) {
      Logger.info(o1.toString());
    }
    throw o;
  }
  return EXIT_SUCCESS;
}

private void parseArgs(string[] commandArgs) {
  string[] args = readOptionsIniFile();
  for (int i = 1; i < commandArgs.length; i++)
    args ~= commandArgs[i];
  string progName = commandArgs[0];
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
    case "-brightness":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float b = cast(float) atoi(args[i].ptr) / 100;
      if (b < 0 || b > 1) {
        usage(args[0]);
        throw new Exception("Invalid options");
      }
      Screen.brightness = b;
      break;
    case "-luminosity":
    case "-luminous":
      if (i >= args.length - 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      float l = cast(float) atoi(args[i].ptr) / 100;
      if (l < 0 || l > 1) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      Screen.luminous = l;
      break;
    case "-window":
      Screen.windowMode = true;
      break;
    case "-res":
      if (i >= args.length - 2) {
        usage(progName);
        throw new Exception("Invalid options");
      }
      i++;
      int w = atoi(args[i].ptr);
      i++;
      int h = atoi(args[i].ptr);
      Screen.width = w;
      Screen.height = h;
      break;
    case "-nosound":
      SoundManager.noSound = true;
      break;
    case "-reverse":
      (cast (Pad) input).buttonReversed = true;
      break;
    case "-accframe":
      mainLoop.accframe = 1;
      break;
    default:
      usage(progName);
      throw new Exception("Invalid options");
    }
  }
}

private const string OPTIONS_INI_FILE = "options.ini";

private string[] readOptionsIniFile() {
  try {
    return Tokenizer.readFile(OPTIONS_INI_FILE, " ");
  } catch (Throwable e) {
    return null;
  }
}

private void usage(string progName) {
  Logger.error
    ("Usage: " ~ progName ~ " [-brightness [0-100]] [-luminosity [0-100]] [-window] [-res x y] [-nosound]");
}
