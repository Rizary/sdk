// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_LONGJUMP_H_
#define RUNTIME_VM_LONGJUMP_H_

#include <setjmp.h>

#include "vm/allocation.h"
#include "vm/isolate.h"

namespace dart {

class Error;

class LongJumpScope : public StackResource {
 public:
  LongJumpScope()
      : StackResource(Thread::Current()),
        top_(NULL),
        base_(thread()->long_jump_base()) {
    thread()->set_long_jump_base(this);
  }

  ~LongJumpScope() {
    ASSERT(thread() == Thread::Current());
    thread()->set_long_jump_base(base_);
  }

  jmp_buf* Set();
  DART_NORETURN void Jump(int value, const Error& error);

 private:
  jmp_buf environment_;
  StackResource* top_;
  LongJumpScope* base_;

  DISALLOW_COPY_AND_ASSIGN(LongJumpScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_LONGJUMP_H_
