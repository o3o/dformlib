// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.folderdialog;

import std.utf: toUTFz, toUTF8;
import core.sys.windows.windows;
import core.sys.windows.shlobj; // Fot ITEMIDLIST
import core.sys.windows.objidl; // Fot IMALLC

import dfl.application;
import dfl.base;
import dfl.commondialog;
import dfl.exception;
import dfl.internal.clib;
import dfl.internal.dlib;
import dfl.internal.utf;

private extern (Windows) nothrow {
   alias SHBrowseForFolderWProc = LPITEMIDLIST function(LPBROWSEINFOW lpbi);
   alias SHGetPathFromIDListWProc = BOOL function(LPCITEMIDLIST pidl, LPWSTR pszPath);
}

class FolderBrowserDialog : CommonDialog {
   this() {
      // Flag BIF_NEWDIALOGSTYLE requires OleInitialize().
      //OleInitialize(null);

      Application.ppin(cast(void*) this);

      bi.ulFlags = INIT_FLAGS;
      bi.lParam = cast(typeof(bi.lParam)) cast(void*) this;
      bi.lpfn = &fbdHookProc;
   }

   ~this() {
      //OleUninitialize();
   }

   override DialogResult showDialog() {
      if (!runDialog(GetActiveWindow())) {
         return DialogResult.CANCEL;
      }
      return DialogResult.OK;
   }

   override DialogResult showDialog(IWindow owner) {
      if (!runDialog(owner ? owner.handle : GetActiveWindow())) {
         return DialogResult.CANCEL;
      }
      return DialogResult.OK;
   }

   override void reset() {
      bi.ulFlags = INIT_FLAGS;
      _desc = null;
      _selpath = null;
   }

   final @property void description(Dstring desc) {
      // lpszTitle
      _desc = desc;
   }

   final @property Dstring description() {
      return _desc;
   }

   final @property void selectedPath(Dstring selpath) {
      // pszDisplayName
      _selpath = selpath;
   }

   final @property Dstring selectedPath() {
      return _selpath;
   }

   // FIX:
   /+
   // Currently only works for shell32.dll version 6.0+.
   final @property void showNewFolderButton(bool byes) {
      // BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
      // Might need to enum child windows looking for window title
      // "&New Folder" and hide it, then shift "OK" and "Cancel" over.

      if (byes) {
         bi.ulFlags &= ~BIF_NONEWFOLDERBUTTON;
      } else {
         bi.ulFlags |= BIF_NONEWFOLDERBUTTON;
      }
   }
   //
   final @property bool showNewFolderButton() {
      return (bi.ulFlags & BIF_NONEWFOLDERBUTTON) == 0;
   }
+/

   // Currently only works for shell32.dll version 6.0+.
   final @property void showNewStyleDialog(bool byes) {
      // BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
      // Might need to enum child windows looking for window title
      // "&New Folder" and hide it, then shift "OK" and "Cancel" over.

      if (byes) {
         bi.ulFlags |= BIF_NEWDIALOGSTYLE;
      } else {
         bi.ulFlags &= ~BIF_NEWDIALOGSTYLE;
      }
   }

   final @property bool showNewStyleDialog() {
      return (bi.ulFlags & BIF_NEWDIALOGSTYLE) != 0;
   }

   // Currently only works for shell32.dll version 6.0+.
   final @property void showTextBox(bool byes) {
      // BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
      // Might need to enum child windows looking for window title
      // "&New Folder" and hide it, then shift "OK" and "Cancel" over.

      if (byes) {
         bi.ulFlags |= BIF_EDITBOX;
      } else {
         bi.ulFlags &= ~BIF_EDITBOX;
      }
   }

   final @property bool showTextBox() {
      return (bi.ulFlags & BIF_EDITBOX) != 0;
   }

   private void _errPathTooLong() {
      throw new DflException("Path name is too long");
   }

   private void _errNoGetPath() {
      throw new DflException("Unable to obtain path");
   }

   private void _errNoShMalloc() {
      throw new DflException("Unable to get shell memory allocator");
   }

   protected override bool runDialog(HWND owner) {
		wchar[MAX_PATH + 1] buffer;
		buffer[] = '\0';
      BROWSEINFOW dlgStruct;
		dlgStruct.hwndOwner = owner;
		dlgStruct.pszDisplayName = buffer.ptr;
		dlgStruct.ulFlags = BIF_RETURNONLYFSDIRS;
		dlgStruct.lpszTitle = toUTFz!(wchar*)(_desc);

		ITEMIDLIST* pidl = SHBrowseForFolderW(&dlgStruct);

		if (pidl) {
			SHGetPathFromIDListW(pidl, buffer.ptr); //Get Full Path.
			this.selectedPath = toUTF8(buffer);
			return true;
		}
		return false;
   }

protected:

   /+
         override LRESULT hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
            switch(msg) {
               case WM_NOTIFY: {
                                  NMHDR* nmhdr;
                                  nmhdr = cast(NMHDR*)lparam;
                                  switch(nmhdr.code) {
                                     /+
                                     case CDN_FILEOK:
                                        break;
                                        +/

                                     default:
                                  }
                               }
                               break;

               default:
            }

            return super.hookProc(hwnd, msg, wparam, lparam);
         }
      +/

private:

   union {
      BROWSEINFOW biw;
      BROWSEINFOA bia;
      alias bi = biw;

      static assert(BROWSEINFOW.sizeof == BROWSEINFOA.sizeof);
      static assert(BROWSEINFOW.ulFlags.offsetof == BROWSEINFOA.ulFlags.offsetof);
   }

   Dstring _desc;
   Dstring _selpath;

   enum UINT INIT_FLAGS = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
}

private:

// FIX:
private  /*extern (Windows)*/ int fbdHookProc(HWND hwnd, UINT msg, LPARAM lparam, LPARAM lpData) {
   FolderBrowserDialog fd;
   int result = 0;

   try {
      fd = cast(FolderBrowserDialog) cast(void*) lpData;
      if (fd) {
         Dstring s;
         switch (msg) {
         case BFFM_INITIALIZED:
            s = fd.selectedPath;
            if (s.length) {
               if (dfl.internal.utf.useUnicode) {
                  SendMessageA(hwnd, BFFM_SETSELECTIONW, TRUE,
                     cast(LPARAM) dfl.internal.utf.toUnicodez(s));
               } else {
                  SendMessageA(hwnd, BFFM_SETSELECTIONA, TRUE,
                     cast(LPARAM) dfl.internal.utf.toAnsiz(s));
               }
            }
            break;

         default:
         }
      }
   }
   catch (DThrowable e) {
      Application.onThreadException(e);
   }

   return result;
}
