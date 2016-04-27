// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.messagebox;

import core.sys.windows.windows;
import dfl.internal.dlib;
static import dfl.internal.utf;
import dfl.base;

enum MsgBoxButtons {
   ABORT_RETRY_IGNORE = MB_ABORTRETRYIGNORE,
   OK = MB_OK,
   OK_CANCEL = MB_OKCANCEL,
   RETRY_CANCEL = MB_RETRYCANCEL,
   YES_NO = MB_YESNO,
   YES_NO_CANCEL = MB_YESNOCANCEL,
}

enum MsgBoxIcon {
   NONE = 0,

   ASTERISK = MB_ICONASTERISK,
   ERROR = MB_ICONERROR,
   EXCLAMATION = MB_ICONEXCLAMATION,
   HAND = MB_ICONHAND,
   INFORMATION = MB_ICONINFORMATION,
   QUESTION = MB_ICONQUESTION,
   STOP = MB_ICONSTOP,
   WARNING = MB_ICONWARNING,
}

enum MsgBoxDefaultButton {
   BUTTON1 = MB_DEFBUTTON1,
   BUTTON2 = MB_DEFBUTTON2,
   BUTTON3 = MB_DEFBUTTON3,

   // Extra.
   BUTTON4 = MB_DEFBUTTON4,
}

enum MsgBoxOptions {
   DEFAULT_DESKTOP_ONLY = MB_DEFAULT_DESKTOP_ONLY,
   RIGHT_ALIGN = MB_RIGHT,
   LEFT_ALIGN = MB_RTLREADING,
   SERVICE_NOTIFICATION = MB_SERVICE_NOTIFICATION,
}

DialogResult msgBox(Dstring txt) {
   return cast(DialogResult) dfl.internal.utf.messageBox(GetActiveWindow(), txt, "\0",
      MB_OK);
}

DialogResult msgBox(IWindow owner, Dstring txt) {
   return cast(DialogResult) dfl.internal.utf.messageBox(
      owner ? owner.handle : GetActiveWindow(), txt, "\0", MB_OK);
}

DialogResult msgBox(Dstring txt, Dstring caption) {
   return cast(DialogResult) dfl.internal.utf.messageBox(GetActiveWindow(), txt, caption,
      MB_OK);
}

DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption) {
   return cast(DialogResult) dfl.internal.utf.messageBox(
      owner ? owner.handle : GetActiveWindow(), txt, caption, MB_OK);
}

DialogResult msgBox(Dstring txt, Dstring caption, MsgBoxButtons buttons) {
   return cast(DialogResult) dfl.internal.utf.messageBox(GetActiveWindow(), txt, caption,
      buttons);
}

DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption, MsgBoxButtons buttons) {
   return cast(DialogResult) dfl.internal.utf.messageBox(
      owner ? owner.handle : GetActiveWindow(), txt, caption, buttons);
}

DialogResult msgBox(Dstring txt, Dstring caption, MsgBoxButtons buttons, MsgBoxIcon icon) {
   return cast(DialogResult) dfl.internal.utf.messageBox(GetActiveWindow(),
      txt, caption, buttons | icon);
}

DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption,
   MsgBoxButtons buttons, MsgBoxIcon icon) {
   return cast(DialogResult) dfl.internal.utf.messageBox(
      owner ? owner.handle : GetActiveWindow(), txt, caption, buttons | icon);
}

DialogResult msgBox(Dstring txt, Dstring caption, MsgBoxButtons buttons,
   MsgBoxIcon icon, MsgBoxDefaultButton defaultButton) {
   return cast(DialogResult) dfl.internal.utf.messageBox(GetActiveWindow(),
      txt, caption, buttons | icon | defaultButton);
}

DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption,
   MsgBoxButtons buttons, MsgBoxIcon icon, MsgBoxDefaultButton defaultButton) {
   return cast(DialogResult) dfl.internal.utf.messageBox(
      owner ? owner.handle : GetActiveWindow(), txt, caption, buttons | icon | defaultButton);
}

DialogResult msgBox(IWindow owner, Dstring txt, Dstring caption,
   MsgBoxButtons buttons, MsgBoxIcon icon, MsgBoxDefaultButton defaultButton, MsgBoxOptions options) {
   return cast(DialogResult) dfl.internal.utf.messageBox(
      owner ? owner.handle : GetActiveWindow(), txt, caption,
      buttons | icon | defaultButton | options);
}

deprecated final class MessageBox {
   private this() {
   }

static:
   deprecated alias show = msgBox;
}

deprecated alias messageBox = msgBox;

deprecated alias MessageBoxOptions = MsgBoxOptions;
deprecated alias MessageBoxDefaultButton = MsgBoxDefaultButton;
deprecated alias MessageBoxButtons = MsgBoxButtons;
deprecated alias MessageBoxIcon = MsgBoxIcon;
