// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.colordialog;

import core.sys.windows.windows;
import dfl.commondialog;
import dfl.base;

import dfl.internal.utf;
import dfl.application;
import dfl.drawing;
import dfl.internal.dlib;

class ColorDialog : CommonDialog {
   this() {
      Application.ppin(cast(void*) this);

      cc.lStructSize = cc.sizeof;
      cc.Flags = INIT_FLAGS;
      cc.rgbResult = Color.empty.toArgb();
      cc.lCustData = cast(typeof(cc.lCustData)) cast(void*) this;
      cc.lpfnHook = cast(typeof(cc.lpfnHook))&ccHookProc;
      _initcust();
   }

   @property void allowFullOpen(bool byes) {
      if (byes) {
         cc.Flags &= ~CC_PREVENTFULLOPEN;
      } else {
         cc.Flags |= CC_PREVENTFULLOPEN;
      }
   }

   @property bool allowFullOpen() {
      return (cc.Flags & CC_PREVENTFULLOPEN) != CC_PREVENTFULLOPEN;
   }

   @property void anyColor(bool byes) {
      if (byes) {
         cc.Flags |= CC_ANYCOLOR;
      } else {
         cc.Flags &= ~CC_ANYCOLOR;
      }
   }

   @property bool anyColor() {
      return (cc.Flags & CC_ANYCOLOR) == CC_ANYCOLOR;
   }

   @property void solidColorOnly(bool byes) {
      if (byes) {
         cc.Flags |= CC_SOLIDCOLOR;
      } else {
         cc.Flags &= ~CC_SOLIDCOLOR;
      }
   }

   @property bool solidColorOnly() {
      return (cc.Flags & CC_SOLIDCOLOR) == CC_SOLIDCOLOR;
   }

   final @property void color(Color c) {
      cc.rgbResult = c.toRgb();
   }

   final @property Color color() {
      return Color.fromRgb(cc.rgbResult);
   }

   final @property void customColors(COLORREF[] colors) {
      if (colors.length >= _cust.length) {
         _cust[] = colors[0 .. _cust.length];
      } else {
         _cust[0 .. colors.length] = colors[];
      }
   }

   final @property COLORREF[] customColors() {
      return _cust;
   }

   @property void fullOpen(bool byes) {
      if (byes) {
         cc.Flags |= CC_FULLOPEN;
      } else {
         cc.Flags &= ~CC_FULLOPEN;
      }
   }

   @property bool fullOpen() {
      return (cc.Flags & CC_FULLOPEN) == CC_FULLOPEN;
   }

   @property void showHelp(bool byes) {
      if (byes) {
         cc.Flags |= CC_SHOWHELP;
      } else {
         cc.Flags &= ~CC_SHOWHELP;
      }
   }

   @property bool showHelp() {
      return (cc.Flags & CC_SHOWHELP) == CC_SHOWHELP;
   }

   override DialogResult showDialog() {
      return runDialog(GetActiveWindow()) ? DialogResult.OK : DialogResult.CANCEL;
   }

   override DialogResult showDialog(IWindow owner) {
      return runDialog(owner ? owner.handle : GetActiveWindow()) ? DialogResult.OK
         : DialogResult.CANCEL;
   }

   override void reset() {
      cc.Flags = INIT_FLAGS;
      cc.rgbResult = Color.empty.toArgb();
      _initcust();
   }

   protected override bool runDialog(HWND owner) {
      if (!_runDialog(owner)) {
         if (!CommDlgExtendedError()) {
            return false;
         }
         _cantrun();
      }
      return true;
   }

   private BOOL _runDialog(HWND owner) {
      if (cc.rgbResult == Color.empty.toArgb()) {
         cc.Flags &= ~CC_RGBINIT;
      } else {
         cc.Flags |= CC_RGBINIT;
      }
      cc.hwndOwner = owner;
      cc.lpCustColors = _cust.ptr;
      return ChooseColorA(&cc);
   }

   private:
   enum DWORD INIT_FLAGS = CC_ENABLEHOOK;

   CHOOSECOLORA cc;
   COLORREF[16] _cust;

   void _initcust() {
      COLORREF cdef;
      cdef = Color(0xFF, 0xFF, 0xFF).toRgb();
      foreach (ref COLORREF cref; _cust) {
         cref = cdef;
      }
   }
}

private extern (Windows) UINT ccHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
   enum PROP_STR = "DFL_ColorDialog";
   ColorDialog cd;
   UINT result = 0;

   try {
      if (msg == WM_INITDIALOG) {
         CHOOSECOLORA* cc;
         cc = cast(CHOOSECOLORA*) lparam;
         SetPropA(hwnd, PROP_STR.ptr, cast(HANDLE) cc.lCustData);
         cd = cast(ColorDialog) cast(void*) cc.lCustData;
      } else {
         cd = cast(ColorDialog) cast(void*) GetPropA(hwnd, PROP_STR.ptr);
      }

      if (cd) {
         result = cast(UINT) cd.hookProc(hwnd, msg, wparam, lparam);
      }
   }
   catch (DThrowable e) {
      Application.onThreadException(e);
   }

   return result;
}
