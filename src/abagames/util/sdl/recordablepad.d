/*
 * $Id: recordablepad.d,v 1.1 2005/01/01 12:40:28 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.recordablepad;

private import std.stream;
private import abagames.util.iterator;
private import abagames.util.sdl.pad;

/**
 * Pad that can record an input for a replay.
 */
public class RecordablePad: Pad {
 public:
  static const int REPLAY_END = -1;
  PadRecord padRecord;
 private:

  public void startRecord() {
    padRecord = new PadRecord;
    padRecord.clear();
  }

  public void record() {
    padRecord.add(lastDirState | lastButtonState);
  }

  public void startReplay(PadRecord pr) {
    padRecord = pr;
    padRecord.reset();
  }

  public int replay() {
    if (!padRecord.hasNext())
      return REPLAY_END;
    else
      return padRecord.next();
  }
}

public class PadRecord {
 private:
  struct Record {
    int series;
    int data;
  };
  Record[] record;
  int idx, series;

  public void clear() {
    record = null;
  }

  public void add(int d) {
    if (record && record[record.length - 1].data == d) {
      record[record.length - 1].series++;
    } else {
      Record r;
      r.series = 1;
      r.data = d;
      record ~= r;
    }
  }

  public void reset() {
    idx = 0;
    series = 0;
  }

  public bool hasNext() {
    if (idx >= record.length)
      return false;
    else
      return true;
  }

  public int next() {
    if (idx >= record.length)
      throw new Error("No more items");
    if (series <= 0)
      series = record[idx].series;
    int rsl = record[idx].data;
    series--;
    if (series <= 0)
      idx++;
    return rsl;
  }

  public void save(File fd) {
    fd.write(record.length);
    foreach (Record r; record) {
      fd.write(r.series);
      fd.write(r.data);
    }
  }

  public void load(File fd) {
    clear();
    int l, s, d;
    fd.read(l);
    for (int i = 0; i < l; i++) {
      fd.read(s);
      fd.read(d);
      Record r;
      r.series = s;
      r.data = d;
      record ~= r;
    }
  }
}
