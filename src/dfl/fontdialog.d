// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.fontdialog;

import core.sys.windows.windows;

import dfl.application;
import dfl.base;
import dfl.commondialog;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.exception;
import dfl.internal.dlib;
import dfl.internal.utf;

private extern (Windows) nothrow {
   alias ChooseFontWProc = BOOL function(LPCHOOSEFONTW lpcf);
}

class FontDialog : CommonDialog {
   this() {
      Application.ppin(cast(void*) this);

      cf.lStructSize = cf.sizeof;
      cf.Flags = INIT_FLAGS;
      cf.lpLogFont = cast(typeof(cf.lpLogFont))&lfw;
      cf.lCustData = cast(typeof(cf.lCustData)) cast(void*) this;
      cf.lpfnHook = &fondHookProc;
      cf.rgbColors = 0;
   }

   override void reset() {
      _fon = null;
      cf.Flags = INIT_FLAGS;
      cf.rgbColors = 0;
      cf.nSizeMin = 0;
      cf.nSizeMax = 0;
   }

   final @property void allowSimulations(bool byes) {
      if (byes) {
         cf.Flags &= ~CF_NOSIMULATIONS;
      } else {
         cf.Flags |= CF_NOSIMULATIONS;
      }
   }

   final @property bool allowSimulations() {
      if (cf.Flags & CF_NOSIMULATIONS) {
         return false;
      }
      return true;
   }

   final @property void allowVectorFonts(bool byes) {
      if (byes) {
         cf.Flags &= ~CF_NOVECTORFONTS;
      } else {
         cf.Flags |= CF_NOVECTORFONTS;
      }
   }

   final bool allowVectorFonts() {
      if (cf.Flags & CF_NOVECTORFONTS) {
         return false;
      }
      return true;
   }

   final @property void allowVerticalFonts(bool byes) {
      if (byes) {
         cf.Flags &= ~CF_NOVERTFONTS;
      } else {
         cf.Flags |= CF_NOVERTFONTS;
      }
   }

   final @property bool allowVerticalFonts() {
      if (cf.Flags & CF_NOVERTFONTS) {
         return false;
      }
      return true;
   }

   final @property void color(Color c) {
      cf.rgbColors = c.toRgb();
   }

   final @property Color color() {
      return Color.fromRgb(cf.rgbColors);
   }

   final @property void fixedPitchOnly(bool byes) {
      if (byes) {
         cf.Flags |= CF_FIXEDPITCHONLY;
      } else {
         cf.Flags &= ~CF_FIXEDPITCHONLY;
      }
   }

   final @property bool fixedPitchOnly() {
      if (cf.Flags & CF_FIXEDPITCHONLY) {
         return true;
      }
      return false;
   }

   final @property void font(Font f) {
      _fon = f;
   }

   final @property Font font() {
      if (!_fon) {
         _fon = Control.defaultFont; // ?
      }
      return _fon;
   }

   final @property void fontMustExist(bool byes) {
      if (byes) {
         cf.Flags |= CF_FORCEFONTEXIST;
      } else {
         cf.Flags &= ~CF_FORCEFONTEXIST;
      }
   }

   final @property bool fontMustExist() {
      if (cf.Flags & CF_FORCEFONTEXIST) {
         return true;
      }
      return false;
   }

   final @property void maxSize(int max) {
      if (max > 0) {
         if (max > cf.nSizeMin) {
            cf.nSizeMax = max;
         }
         cf.Flags |= CF_LIMITSIZE;
      } else {
         cf.Flags &= ~CF_LIMITSIZE;
         cf.nSizeMax = 0;
         cf.nSizeMin = 0;
      }
   }

   final @property int maxSize() {
      if (cf.Flags & CF_LIMITSIZE) {
         return cf.nSizeMax;
      }
      return 0;
   }

   final @property void minSize(int min) {
      if (min > cf.nSizeMax) {
         cf.nSizeMax = min;
      }
      cf.nSizeMin = min;
      cf.Flags |= CF_LIMITSIZE;
   }

   final @property int minSize() {
      if (cf.Flags & CF_LIMITSIZE) {
         return cf.nSizeMin;
      }
      return 0;
   }

   final @property void scriptsOnly(bool byes) {
      if (byes) {
         cf.Flags |= CF_SCRIPTSONLY;
      } else {
         cf.Flags &= ~CF_SCRIPTSONLY;
      }
   }

   final @property bool scriptsOnly() {
      if (cf.Flags & CF_SCRIPTSONLY) {
         return true;
      }
      return false;
   }

   final @property void showApply(bool byes) {
      if (byes) {
         cf.Flags |= CF_APPLY;
      } else {
         cf.Flags &= ~CF_APPLY;
      }
   }

   final @property bool showApply() {
      if (cf.Flags & CF_APPLY) {
         return true;
      }
      return false;
   }

   final @property void showHelp(bool byes) {
      if (byes) {
         cf.Flags |= CF_SHOWHELP;
      } else {
         cf.Flags &= ~CF_SHOWHELP;
      }
   }

   final @property bool showHelp() {
      if (cf.Flags & CF_SHOWHELP) {
         return true;
      }
      return false;
   }

   final @property void showEffects(bool byes) {
      if (byes) {
         cf.Flags |= CF_EFFECTS;
      } else {
         cf.Flags &= ~CF_EFFECTS;
      }
   }

   final @property bool showEffects() {
      if (cf.Flags & CF_EFFECTS) {
         return true;
      }
      return false;
   }

   override DialogResult showDialog() {
      return runDialog(GetActiveWindow()) ? DialogResult.OK : DialogResult.CANCEL;
   }

   override DialogResult showDialog(IWindow owner) {
      return runDialog(owner ? owner.handle : GetActiveWindow()) ? DialogResult.OK
         : DialogResult.CANCEL;
   }

   EventHandler apply;

   protected override LRESULT hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
      switch (msg) {
         case WM_COMMAND:
            switch (LOWORD(wparam)) {
               case CF_APPLY: // ?
                  _update();
                  onApply(EventArgs.empty);
                  break;

               default:
            }
            break;

         default:
      }

      return super.hookProc(hwnd, msg, wparam, lparam);
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
      BOOL result = FALSE;

      cf.hwndOwner = owner;

      if (dfl.internal.utf.useUnicode) {
         font._info(&lfw); // -font- gets default font if not set.

         enum NAME = "ChooseFontW";
         static ChooseFontWProc proc = null;

         if (!proc) {
            proc = cast(ChooseFontWProc) GetProcAddress(GetModuleHandleA("comdlg32.dll"),
                  NAME.ptr);
            if (!proc) {
               throw new Exception("Unable to load procedure " ~ NAME ~ ".");
            }
         }

         result = proc(&cfw);
      } else {
         font._info(&lfa); // -font- gets default font if not set.

         result = ChooseFontA(&cfa);
      }

      if (result) {
         _update();
         return result;
      }
      return FALSE;
   }

   private void _update() {
      LogFont lf;

      if (dfl.internal.utf.useUnicode) {
         Font.LOGFONTWtoLogFont(lf, &lfw);
      } else {
         Font.LOGFONTAtoLogFont(lf, &lfa);
      }

      _fon = new Font(Font._create(lf), true);
   }

   protected void onApply(EventArgs ea) {
      apply(this, ea);
   }

   private:

   union {
      CHOOSEFONTW cfw;
      CHOOSEFONTA cfa;
      alias cf = cfw;

      static assert(CHOOSEFONTW.sizeof == CHOOSEFONTA.sizeof);
      static assert(CHOOSEFONTW.Flags.offsetof == CHOOSEFONTA.Flags.offsetof);
      static assert(CHOOSEFONTW.nSizeMax.offsetof == CHOOSEFONTA.nSizeMax.offsetof);
   }

   union {
      LOGFONTW lfw;
      LOGFONTA lfa;

      static assert(LOGFONTW.lfFaceName.offsetof == LOGFONTA.lfFaceName.offsetof);
   }

   Font _fon;

   enum UINT INIT_FLAGS = CF_EFFECTS | CF_ENABLEHOOK | CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS;
}

// WM_CHOOSEFONT_SETFLAGS to update flags after dialog creation ... ?

private extern (Windows) UINT fondHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow {
   enum PROP_STR = "DFL_FontDialog";
   FontDialog fd;
   LRESULT result = 0;

   try {
      if (msg == WM_INITDIALOG) {
         CHOOSEFONTA* cf;
         cf = cast(CHOOSEFONTA*) lparam;
         SetPropA(hwnd, PROP_STR.ptr, cast(HANDLE) cf.lCustData);
         fd = cast(FontDialog) cast(void*) cf.lCustData;
      } else {
         fd = cast(FontDialog) cast(void*) GetPropA(hwnd, PROP_STR.ptr);
      }

      if (fd) {
         result = fd.hookProc(hwnd, msg, wparam, lparam);
      }
   }
   catch (DThrowable e) {
      Application.onThreadException(e);
   }

   return result;
}
