// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.tooltip;

import core.sys.windows.windows;
import core.sys.windows.commctrl;
import core.stdc.stdlib;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.exception;
import dfl.internal.dlib;
import dfl.internal.utf;

class ToolTip {
   package this(DWORD style) {
      _initCommonControls(ICC_TREEVIEW_CLASSES); // Includes tooltip.

      hwtt = CreateWindowExA(WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
         _TOOLTIPS_CLASSA.ptr, "", style, 0, 0, 50, 50, null, null, null, null);
      if (!hwtt) {
         throw new DflException("Unable to create tooltip");
      }
   }

   this() {
      this(cast(DWORD) WS_POPUP);
   }

   ~this() {
      removeAll(); // Fixes ref count.
      DestroyWindow(hwtt);
   }

   final @property HWND handle() {
      return hwtt;
   }

   final @property void active(bool byes) {
      SendMessageA(hwtt, TTM_ACTIVATE, byes, 0); // ?
      _active = byes;
   }

   final @property bool active() {
      return _active;
   }

   // Sets autoPopDelay, initialDelay and reshowDelay.
   final @property void automaticDelay(DWORD ms) {
      SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_AUTOMATIC, ms);
   }

   /+

   final @property DWORD automaticDelay() {
   }
   +/

   final @property void autoPopDelay(DWORD ms) {
      SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_AUTOPOP, ms);
   }

   /+

   final @property DWORD autoPopDelay() {
   }
   +/

   final @property void initialDelay(DWORD ms) {
      SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_INITIAL, ms);
   }

   /+

   final @property DWORD initialDelay() {
   }
   +/

   final @property void reshowDelay(DWORD ms) {
      SendMessageA(hwtt, TTM_SETDELAYTIME, TTDT_RESHOW, ms);
   }

   /+

   final @property DWORD reshowDelay() {
   }
   +/

   final @property void showAlways(bool byes) {
      LONG wl;
      wl = GetWindowLongA(hwtt, GWL_STYLE);
      if (byes) {
         if (wl & TTS_ALWAYSTIP) {
            return;
         }
         wl |= TTS_ALWAYSTIP;
      } else {
         if (!(wl & TTS_ALWAYSTIP)) {
            return;
         }
         wl &= ~TTS_ALWAYSTIP;
      }
      SetWindowLongA(hwtt, GWL_STYLE, wl);
   }

   final @property bool showAlways() {
      return (GetWindowLongA(hwtt, GWL_STYLE) & TTS_ALWAYSTIP) != 0;
   }

   // Remove all tooltip text associated with this instance.
   final void removeAll() {
      TOOLINFOA tool;
      tool.cbSize = TOOLINFOA.sizeof;
      while (SendMessageA(hwtt, TTM_ENUMTOOLSA, 0, cast(LPARAM)&tool)) {
         SendMessageA(hwtt, TTM_DELTOOLA, 0, cast(LPARAM)&tool);
         Application.refCountDec(cast(void*) this);
      }
   }

   // WARNING: possible buffer overflow.
   final Dstring getToolTip(Control ctrl) {
      Dstring result;
      TOOLINFOA tool;
      tool.cbSize = TOOLINFOA.sizeof;
      tool.uFlags = TTF_IDISHWND;
      tool.hwnd = ctrl.handle;
      tool.uId = cast(UINT) ctrl.handle;

      if (dfl.internal.utf.useUnicode) {
         tool.lpszText = cast(typeof(tool.lpszText)) malloc((MAX_TIP_TEXT_LENGTH + 1) * wchar
            .sizeof);
         if (!tool.lpszText) {
            throw new OomException;
         }
         scope (exit)
            free(tool.lpszText);
         tool.lpszText[0 .. 2] = 0;
         SendMessageA(hwtt, TTM_GETTEXTW, 0, cast(LPARAM)&tool);
         if (!(cast(wchar*) tool.lpszText)[0]) {
            result = null;
         } else {
            result = fromUnicodez(cast(wchar*) tool.lpszText);
         }
      } else {
         tool.lpszText = cast(typeof(tool.lpszText)) malloc(MAX_TIP_TEXT_LENGTH + 1);
         if (!tool.lpszText) {
            throw new OomException;
         }
         scope (exit)
            free(tool.lpszText);
         tool.lpszText[0] = 0;
         SendMessageA(hwtt, TTM_GETTEXTA, 0, cast(LPARAM)&tool);
         if (!tool.lpszText[0]) {
            result = null;
         } else {
            result = fromAnsiz(tool.lpszText); // Assumes fromAnsiz() copies.
         }
      }
      return result;
   }

   final void setToolTip(Control ctrl, Dstring text)
   in {
      try {
         ctrl.createControl();
      }
      catch (DThrowable o) {
         assert(0); // If -ctrl- is a child, make sure the parent is set before setting tool tip text.
         //throw o;
      }
   }
   body {
      TOOLINFOA tool;
      tool.cbSize = TOOLINFOA.sizeof;
      tool.uFlags = TTF_IDISHWND;
      tool.hwnd = ctrl.handle;
      tool.uId = cast(UINT) ctrl.handle;

      if (!text.length) {
         if (SendMessageA(hwtt, TTM_GETTOOLINFOA, 0, cast(LPARAM)&tool)) {
            // Remove.

            SendMessageA(hwtt, TTM_DELTOOLA, 0, cast(LPARAM)&tool);

            Application.refCountDec(cast(void*) this);
         }
         return;
      }

      // Hack to help prevent getToolTip() overflow.
      if (text.length > MAX_TIP_TEXT_LENGTH) {
         text = text[0 .. MAX_TIP_TEXT_LENGTH];
      }

      if (SendMessageA(hwtt, TTM_GETTOOLINFOA, 0, cast(LPARAM)&tool)) {
         // Update.

         if (dfl.internal.utf.useUnicode) {
            tool.lpszText = cast(typeof(tool.lpszText)) toUnicodez(text);
            SendMessageA(hwtt, TTM_UPDATETIPTEXTW, 0, cast(LPARAM)&tool);
         } else {
            tool.lpszText = cast(typeof(tool.lpszText)) unsafeAnsiz(text);
            SendMessageA(hwtt, TTM_UPDATETIPTEXTA, 0, cast(LPARAM)&tool);
         }
      } else {
         // Add.

         /+
         // TOOLINFOA.rect is ignored if TTF_IDISHWND.
         tool.rect.left = 0;
         tool.rect.top = 0;
         tool.rect.right = ctrl.clientSize.width;
         tool.rect.bottom = ctrl.clientSize.height;
         +/
         tool.uFlags |= TTF_SUBCLASS; // Not a good idea ?
         LRESULT lr;
         if (dfl.internal.utf.useUnicode) {
            tool.lpszText = cast(typeof(tool.lpszText)) toUnicodez(text);
            lr = SendMessageA(hwtt, TTM_ADDTOOLW, 0, cast(LPARAM)&tool);
         } else {
            tool.lpszText = cast(typeof(tool.lpszText)) unsafeAnsiz(text);
            lr = SendMessageA(hwtt, TTM_ADDTOOLA, 0, cast(LPARAM)&tool);
         }

         if (lr) {
            Application.refCountInc(cast(void*) this);
         }
      }
   }

private:
   enum _TOOLTIPS_CLASSA = "tooltips_class32";
   enum size_t MAX_TIP_TEXT_LENGTH = 2045;

   HWND hwtt; // Tooltip control handle.
   bool _active = true;
}
