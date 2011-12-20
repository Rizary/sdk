// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void testEmptyListInputStream() {
  InputStream stream = new ListInputStream([]);
  ReceivePort donePort = new ReceivePort();

  void onData() {
    throw "On data expected";
  }

  void onClose() {
    donePort.toSendPort().send(null);
  }

  stream.dataHandler = onData;
  stream.closeHandler = onClose;

  donePort.receive((x,y) => donePort.close());
}

void testEmptyDynamicListInputStream() {
  InputStream stream = new DynamicListInputStream();
  ReceivePort donePort = new ReceivePort();

  void onData() {
    throw "On data expected";
  }

  void onClose() {
    donePort.toSendPort().send(null);
  }

  stream.dataHandler = onData;
  stream.closeHandler = onClose;
  stream.markEndOfStream();

  donePort.receive((x,y) => donePort.close());
}

void testListInputStream1() {
  List<int> data = [0x00, 0x01, 0x10, 0x11, 0x7e, 0x7f, 0x80, 0x81, 0xfe, 0xff];
  InputStream stream = new ListInputStream(data);
  int count = 0;
  ReceivePort donePort = new ReceivePort();

  void onData() {
    List<int> x = stream.read(1);
    Expect.equals(1, x.length);
    Expect.equals(data[count++], x[0]);
  }

  void onClose() {
    Expect.equals(data.length, count);
    donePort.toSendPort().send(count);
  }

  stream.dataHandler = onData;
  stream.closeHandler = onClose;

  donePort.receive((x,y) => donePort.close());
}

void testListInputStream2() {
  List<int> data = [0x00, 0x01, 0x10, 0x11, 0x7e, 0x7f, 0x80, 0x81, 0xfe, 0xff];
  InputStream stream = new ListInputStream(data);
  int count = 0;
  ReceivePort donePort = new ReceivePort();

  void onData() {
    List<int> x = new List<int>(2);
    var bytesRead = stream.readInto(x);
    Expect.equals(2, bytesRead);
    Expect.equals(data[count++], x[0]);
    Expect.equals(data[count++], x[1]);
  }

  void onClose() {
    Expect.equals(data.length, count);
    donePort.toSendPort().send(count);
  }

  stream.dataHandler = onData;
  stream.closeHandler = onClose;

  donePort.receive((x,y) => donePort.close());
}

void testDynamicListInputStream1() {
  List<int> data = [0x00, 0x01, 0x10, 0x11, 0x7e, 0x7f, 0x80, 0x81, 0xfe, 0xff];
  InputStream stream = new DynamicListInputStream();
  int count = 0;
  ReceivePort donePort = new ReceivePort();

  void onData() {
    List<int> x = stream.read(1);
    Expect.equals(1, x.length);
    x = stream.read();
    Expect.equals(9, x.length);
    count++;
    if (count < 10) {
      stream.write(data);
    } else {
      stream.markEndOfStream();
    }
  }

  void onClose() {
    Expect.equals(data.length, count);
    donePort.toSendPort().send(count);
  }

  stream.write(data);
  stream.dataHandler = onData;
  stream.closeHandler = onClose;

  donePort.receive((x,y) => donePort.close());
}

main() {
  testEmptyListInputStream();
  testEmptyDynamicListInputStream();
  testListInputStream1();
  testListInputStream2();
  testDynamicListInputStream1();
}
