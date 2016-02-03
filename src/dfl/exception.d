module dfl.exception;

import dfl.internal.dlib;

class DflException: Exception {
   this(Dstring msg, string file = __FILE__, int line = __LINE__) {
      super(msg, file, line);
   }
}

