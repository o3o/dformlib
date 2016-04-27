module dfl.toolbar;

import core.sys.windows.windows;
import core.sys.windows.commctrl;

import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.exception;
import dfl.internal.dlib;
static import dfl.internal.utf;

version (DFL_NO_IMAGELIST) {
} else {
   private import dfl.imagelist;
}

version (DFL_NO_MENUS) version = DFL_TOOLBAR_NO_MENU;

version (DFL_TOOLBAR_NO_MENU) {
} else {
   private import dfl.menu;
}

enum ToolBarButtonStyle : ubyte {
   PUSH_BUTTON = TBSTYLE_BUTTON,
   TOGGLE_BUTTON = TBSTYLE_CHECK,
   SEPARATOR = TBSTYLE_SEP,
   //static if (_WIN32_IE >= 0x500) {
      //DROP_DOWN_BUTTON = TBSTYLE_DROPDOWN | BTNS_WHOLEDROPDOWN,
   //} else {
      DROP_DOWN_BUTTON = TBSTYLE_DROPDOWN,
   //}
}

class ToolBarButton {

   this() {
      Application.ppin(cast(void*) this);
   }

   this(Dstring text) {
      this();

      this.text = text;
   }

   version (DFL_NO_IMAGELIST) {
   } else {

      final @property void imageIndex(int index) {
         this._imgidx = index;

         //if(tbar && tbar.created)
         // tbar.updateItem(this);
      }

      final @property int imageIndex() {
         return _imgidx;
      }
   }

   @property void text(Dstring newText) {
      _text = newText;

      //if(tbar && tbar.created)
      //
   }

   @property Dstring text() {
      return _text;
   }

   final @property void style(ToolBarButtonStyle st) {
      this._style = st;

      //if(tbar && tbar.created)
      //
   }

   final @property ToolBarButtonStyle style() {
      return _style;
   }

   override Dstring toString() {
      return text;
   }

   override Dequ opEquals(Object o) {
      return text == getObjectString(o);
   }

   Dequ opEquals(Dstring val) {
      return text == val;
   }

   override int opCmp(Object o) {
      return stringICmp(text, getObjectString(o));
   }

   int opCmp(Dstring val) {
      return stringICmp(text, val);
   }

   final @property void tag(Object o) {
      _tag = o;
   }

   final @property Object tag() {
      return _tag;
   }

   version (DFL_TOOLBAR_NO_MENU) {
   } else {

      final @property void dropDownMenu(ContextMenu cmenu) {
         _cmenu = cmenu;
      }

      final @property ContextMenu dropDownMenu() {
         return _cmenu;
      }
   }

   final @property ToolBar parent() {
      return tbar;
   }

   final @property Rect rectangle() {
      //if(!tbar || !tbar.created)
      if (!visible) {
         return Rect(0, 0, 0, 0); // ?
      }
      assert(tbar !is null);
      RECT rect;
      //assert(-1 != tbar.buttons.indexOf(this));
      tbar.prevwproc(TB_GETITEMRECT, tbar.buttons.indexOf(this), cast(LPARAM)&rect); // Fails if item is hidden.
      return Rect(&rect); // Should return all 0`s if TB_GETITEMRECT failed.
   }

   final @property void visible(bool byes) {
      if (byes) {
         _state &= ~TBSTATE_HIDDEN;
      } else {
         _state |= TBSTATE_HIDDEN;
      }

      if (tbar && tbar.created) {
         tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
      }
   }

   final @property bool visible() {
      if (!tbar || !tbar.created) {
         return false;
      }
      return true; // To-do: get actual hidden state.
   }

   final @property void enabled(bool byes) {
      if (byes) {
         _state |= TBSTATE_ENABLED;
      } else {
         _state &= ~TBSTATE_ENABLED;
      }

      if (tbar && tbar.created) {
         tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
      }
   }

   final @property bool enabled() {
      if (_state & TBSTATE_ENABLED) {
         return true;
      }
      return false;
   }

   final @property void pushed(bool byes) {
      if (byes) {
         _state = (_state & ~TBSTATE_INDETERMINATE) | TBSTATE_CHECKED;
      } else {
         _state &= ~TBSTATE_CHECKED;
      }

      if (tbar && tbar.created) {
         tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
      }
   }

   final @property bool pushed() {
      if (TBSTATE_CHECKED == (_state & TBSTATE_CHECKED)) {
         return true;
      }
      return false;
   }

   final @property void partialPush(bool byes) {
      if (byes) {
         _state = (_state & ~TBSTATE_CHECKED) | TBSTATE_INDETERMINATE;
      } else {
         _state &= ~TBSTATE_INDETERMINATE;
      }

      if (tbar && tbar.created) {
         tbar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
      }
   }

   final @property bool partialPush() {
      if (TBSTATE_INDETERMINATE == (_state & TBSTATE_INDETERMINATE)) {
         return true;
      }
      return false;
   }

private:
   ToolBar tbar;
   int _id = 0;
   Dstring _text;
   Object _tag;
   ToolBarButtonStyle _style = ToolBarButtonStyle.PUSH_BUTTON;
   BYTE _state = TBSTATE_ENABLED;
   version (DFL_TOOLBAR_NO_MENU) {
   } else {
      ContextMenu _cmenu;
   }
   version (DFL_NO_IMAGELIST) {
   } else {
      int _imgidx = -1;
   }
}

class ToolBarButtonClickEventArgs : EventArgs {
   this(ToolBarButton tbbtn) {
      _btn = tbbtn;
   }

   final @property ToolBarButton button() {
      return _btn;
   }

private:

   ToolBarButton _btn;
}

class ToolBar : ControlSuperClass {
   class ToolBarButtonCollection {
      protected this() {
      }

   private:

      ToolBarButton[] _buttons;

      void _adding(size_t idx, ToolBarButton val) {
         if (val.tbar) {
            throw new DflException("ToolBarButton already belongs to a ToolBar");
         }
      }

      void _added(size_t idx, ToolBarButton val) {
         val.tbar = tbar;
         val._id = tbar._allocTbbID();

         if (created) {
            _ins(idx, val);
         }
      }

      void _removed(size_t idx, ToolBarButton val) {
         if (size_t.max == idx) { // Clear all.
         } else {
            if (created) {
               prevwproc(TB_DELETEBUTTON, idx, 0);
            }
            val.tbar = null;
         }
      }

   public:

      mixin ListWrapArray!(ToolBarButton, _buttons, _adding, _added,
         _blankListCallback!(ToolBarButton), _removed, true, false, false, true); // CLEAR_EACH
   }

   private @property ToolBar tbar() {
      return this;
   }

   this() {
      _initToolbar();

      _tbuttons = new ToolBarButtonCollection();

      dock = DockStyle.TOP;

      //wexstyle |= WS_EX_CLIENTEDGE;
      wclassStyle = toolbarClassStyle;
   }

   final @property ToolBarButtonCollection buttons() {
      return _tbuttons;
   }

   // buttonSize...

   final @property Size imageSize() {
      version (DFL_NO_IMAGELIST) {
      } else {
         if (_imglist) {
            return _imglist.imageSize;
         }
      }
      return Size(16, 16); // ?
   }

   version (DFL_NO_IMAGELIST) {
   } else {

      final @property void imageList(ImageList imglist) {
         if (isHandleCreated) {
            prevwproc(TB_SETIMAGELIST, 0, cast(WPARAM) imglist.handle);
         }

         _imglist = imglist;
      }

      final @property ImageList imageList() {
         return _imglist;
      }
   }

   Event!(ToolBar, ToolBarButtonClickEventArgs) buttonClick;

   protected void onButtonClick(ToolBarButtonClickEventArgs ea) {
      buttonClick(this, ea);
   }

   protected override void onReflectedMessage(ref Message m) {
      switch (m.msg) {
      case WM_NOTIFY: {
            auto nmh = cast(LPNMHDR) m.lParam;
            switch (nmh.code) {
            case NM_CLICK: {
                  auto nmm = cast(LPNMMOUSE) nmh;
                  if (nmm.dwItemData) {
                     auto tbb = cast(ToolBarButton) cast(void*) nmm.dwItemData;
                     scope ToolBarButtonClickEventArgs bcea = new ToolBarButtonClickEventArgs(tbb);
                     onButtonClick(bcea);
                  }
               }
               break;

            case TBN_DROPDOWN:
               version (DFL_TOOLBAR_NO_MENU) { // This condition might be removed later.
               } else { // Ditto.
                  auto nmtb = cast(LPNMTOOLBARA) nmh; // NMTOOLBARA/NMTOOLBARW doesn't matter here; string fields not used.
                  auto tbb = buttomFromID(nmtb.iItem);
                  if (tbb) {
                     version (DFL_TOOLBAR_NO_MENU) { // Keep this here in case the other condition is removed.
                     } else { // Ditto.
                        if (tbb._cmenu) {
                           auto brect = tbb.rectangle;
                           tbb._cmenu.show(this, pointToScreen(Point(brect.x, brect.bottom)));
                           // Note: showing a menu also triggers a click!
                        }
                     }
                  }
               }
               m.result = TBDDRET_DEFAULT;
               return;

            default:
            }
         }
         break;

      default:
         super.onReflectedMessage(m);
      }
   }

   protected override @property Size defaultSize() {
      return Size(100, 16);
   }

   protected override void createParams(ref CreateParams cp) {
      super.createParams(cp);

      cp.className = TOOLBAR_CLASSNAME;
   }

   // Used internally
   /+package+/
   final ToolBarButton buttomFromID(int id) { // package
      foreach (tbb; _tbuttons._buttons) {
         if (id == tbb._id) {
            return tbb;
         }
      }
      return null;
   }

   package int _lastTbbID = 0;

   package final int _allocTbbID() {
      for (int j = 0; j != 250; j++) {
         _lastTbbID++;
         if (_lastTbbID >= short.max) {
            _lastTbbID = 1;
         }

         if (!buttomFromID(_lastTbbID)) {
            return _lastTbbID;
         }
      }
      return 0;
   }

   protected override void onHandleCreated(EventArgs ea) {
      super.onHandleCreated(ea);

      static assert(TBBUTTON.sizeof == 20);
      prevwproc(TB_BUTTONSTRUCTSIZE, TBBUTTON.sizeof, 0);

      //prevwproc(TB_SETPADDING, 0, MAKELPARAM(0, 0));

      version (DFL_NO_IMAGELIST) {
      } else {
         if (_imglist) {
            prevwproc(TB_SETIMAGELIST, 0, cast(WPARAM) _imglist.handle);
         }
      }

      foreach (idx, tbb; _tbuttons._buttons) {
         _ins(idx, tbb);
      }

      //prevwproc(TB_AUTOSIZE, 0, 0);
   }

   protected override void prevWndProc(ref Message msg) {
      //msg.result = CallWindowProcA(toolbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
      msg.result = dfl.internal.utf.callWindowProc(toolbarPrevWndProc, msg.hWnd,
         msg.msg, msg.wParam, msg.lParam);
   }

private:

   ToolBarButtonCollection _tbuttons;

   version (DFL_NO_IMAGELIST) {
   } else {
      ImageList _imglist;
   }

   void _ins(size_t idx, ToolBarButton tbb) {
      // To change: TB_SETBUTTONINFO

      TBBUTTON xtb;
      version (DFL_NO_IMAGELIST) {
         xtb.iBitmap = -1;
      } else {
         xtb.iBitmap = tbb._imgidx;
      }
      xtb.idCommand = tbb._id;
      xtb.dwData = cast(DWORD) cast(void*) tbb;
      xtb.fsState = tbb._state;
      xtb.fsStyle = TBSTYLE_AUTOSIZE | tbb._style; // TBSTYLE_AUTOSIZE factors in the text's width instead of default button size.
      LRESULT lresult;
      // MSDN says iString can be either an int offset or pointer to a string buffer.
      if (dfl.internal.utf.useUnicode) {
         if (tbb._text.length) {
            xtb.iString = cast(typeof(xtb.iString)) dfl.internal.utf.toUnicodez(tbb._text);
         }
         //prevwproc(TB_ADDBUTTONSW, 1, cast(LPARAM)&xtb);
         lresult = prevwproc(TB_INSERTBUTTONW, idx, cast(LPARAM)&xtb);
      } else {
         if (tbb._text.length) {
            xtb.iString = cast(typeof(xtb.iString)) dfl.internal.utf.toAnsiz(tbb._text);
         }
         //prevwproc(TB_ADDBUTTONSA, 1, cast(LPARAM)&xtb);
         lresult = prevwproc(TB_INSERTBUTTONA, idx, cast(LPARAM)&xtb);
      }
      //if(!lresult)
      // throw new DflException("Unable to add ToolBarButton");
   }

package:
final:
   LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam) {
      //return CallWindowProcA(toolbarPrevWndProc, hwnd, msg, wparam, lparam);
      return dfl.internal.utf.callWindowProc(toolbarPrevWndProc, hwnd, msg, wparam,
         lparam);
   }
}

private {
   enum TOOLBAR_CLASSNAME = "DFL_ToolBar";

   WNDPROC toolbarPrevWndProc;

   LONG toolbarClassStyle;

   void _initToolbar() {
      if (!toolbarPrevWndProc) {
         _initCommonControls(ICC_BAR_CLASSES);

         dfl.internal.utf.WndClass info;
         toolbarPrevWndProc = superClass(HINSTANCE.init, "ToolbarWindow32",
            TOOLBAR_CLASSNAME, info);
         if (!toolbarPrevWndProc) {
            _unableToInit(TOOLBAR_CLASSNAME);
         }
         toolbarClassStyle = info.wc.style;
      }
   }
}
