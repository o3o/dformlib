// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.timer;

import core.sys.windows.windows;
import dfl.exception;
import dfl.event;
import dfl.base;
import dfl.application;
import dfl.internal.dlib;

debug (APP_PRINT) {
   private import dfl.internal.clib;
}

class Timer {
   //EventHandler tick;
   Event!(Timer, EventArgs) tick;

   @property void enabled(bool on) {
      if (on) {
         start();
      } else {
         stop();
      }
   }

   @property bool enabled() {
      return timerId != 0;
   }

   final @property void interval(size_t timeout) {
      if (!timeout) {
         throw new DflException("Invalid timer interval");
      }

      if (this._timeout != timeout) {
         this._timeout = timeout;

         if (timerId) {
            // I don't know if this is the correct behavior.
            // Reset the timer for the new timeout...
            stop();
            start();
         }
      }
   }

   final @property size_t interval() {
      return _timeout;
   }

   final void start() {
      if (timerId) {
         return;
      }

      assert(_timeout > 0);

      timerId = SetTimer(null, 0, _timeout, &timerProc);
      if (!timerId) {
         throw new DflException("Unable to start timer");
      }
      allTimers[timerId] = this;
   }

   final void stop() {
      if (timerId) {
         //delete allTimers[timerId];
         allTimers.remove(timerId);
         KillTimer(null, timerId);
         timerId = 0;
      }
   }

   this() {
   }

   this(void delegate(Timer) dg) {
      this();
      if (dg) {
         this._dg = dg;
         tick ~= &_dgcall;
      }
   }

   this(void delegate(Object, EventArgs) dg) {
      assert(dg !is null);

      this();
      tick ~= dg;
   }

   this(void delegate(Timer, EventArgs) dg) {
      assert(dg !is null);

      this();
      tick ~= dg;
   }

   ~this() {
      dispose();
   }

protected:

   void dispose() {
      stop();
   }

   void onTick(EventArgs ea) {
      tick(this, ea);
   }

private:
   DWORD _timeout = 100;
   UINT timerId = 0;
   void delegate(Timer) _dg;

   void _dgcall(Object sender, EventArgs ea) {
      assert(_dg !is null);
      _dg(this);
   }
}

private:

Timer[UINT] allTimers;

extern (Windows) void timerProc(HWND hwnd, UINT uMsg, UINT idEvent, DWORD dwTime) nothrow {
   try {
      if (idEvent in allTimers) {
         allTimers[idEvent].onTick(EventArgs.empty);
      } else {
         debug (APP_PRINT)
            cprintf("Unknown timer 0x%X.\n", idEvent);
      }
   }
   catch (DThrowable e) {
      Application.onThreadException(e);
   }
}
