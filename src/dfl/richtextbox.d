// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.richtextbox;
import core.sys.windows.windows;
import core.sys.windows.windef;
import core.sys.windows.richedit;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.data;
import dfl.drawing;
import dfl.event;
import dfl.exception;
import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.textbox;

version (DFL_NO_MENUS) {
} else {
   private import dfl.menu;
}

private extern (C) char* strcpy(char*, char*);

private extern (Windows) void _initRichtextbox();

class LinkClickedEventArgs : EventArgs {

   this(Dstring linkText) {
      _linktxt = linkText;
   }

   final @property Dstring linkText() {
      return _linktxt;
   }

private:
   Dstring _linktxt;
}
// rom winapi
enum: UINT {
   SF_TEXT = 0x0001,
   SF_RTF = 0x0002,
   SF_RTFNOOBJS = 0x0003,
   SF_TEXTIZED = 0x0004,

   SFF_SELECTION = 0x8000,
   SFF_PLAINRTF = 0x4000,

   SCF_SELECTION = 0x0001,
   SCF_WORD = 0x0002,
   SCF_ALL = 0x0004,

   CFM_BOLD = 0x00000001,
   CFM_ITALIC = 0x00000002,
   CFM_UNDERLINE = 0x00000004,
   CFM_STRIKEOUT = 0x00000008,
   CFM_PROTECTED = 0x00000010,
   CFM_LINK = 0x00000020,
   CFM_SIZE = 0x80000000,
   CFM_COLOR = 0x40000000,
   CFM_FACE = 0x20000000,
   CFM_OFFSET = 0x10000000,
   CFM_CHARSET = 0x08000000,
   CFM_SMALLCAPS = 0x0040,
   CFM_ALLCAPS = 0x0080,
   CFM_HIDDEN = 0x0100,
   CFM_OUTLINE = 0x0200,
   CFM_SHADOW = 0x0400,
   CFM_EMBOSS = 0x0800,
   CFM_IMPRINT = 0x1000,
   CFM_DISABLED = 0x2000,
   CFM_REVISED = 0x4000,
   CFM_BACKCOLOR = 0x04000000,
   CFM_LCID = 0x02000000,
   CFM_UNDERLINETYPE = 0x00800000,
   CFM_WEIGHT = 0x00400000,
   CFM_SPACING = 0x00200000,
   CFM_KERNING = 0x00100000,
   CFM_STYLE = 0x00080000,
   CFM_ANIMATION = 0x00040000,
   CFM_REVAUTHOR = 0x00008000,

   CFE_BOLD = 0x0001,
   CFE_ITALIC = 0x0002,
   CFE_UNDERLINE = 0x0004,
   CFE_STRIKEOUT = 0x0008,
   CFE_PROTECTED = 0x0010,
   CFE_LINK = 0x0020,
   CFE_AUTOCOLOR = 0x40000000,
   CFE_AUTOBACKCOLOR = CFM_BACKCOLOR,
   CFE_SUBSCRIPT = 0x00010000,
   CFE_SUPERSCRIPT = 0x00020000,

   CFM_SUBSCRIPT = CFE_SUBSCRIPT | CFE_SUPERSCRIPT,
   CFM_SUPERSCRIPT = CFM_SUBSCRIPT,

   CFU_UNDERLINE = 1,

   ENM_NONE = 0x00000000,
   ENM_CHANGE = 0x00000001,
   ENM_UPDATE = 0x00000002,
   ENM_LINK = 0x04000000,
   ENM_PROTECTED = 0x00200000,
}
enum RichTextBoxScrollBars : ubyte {
   NONE,
   HORIZONTAL,
   VERTICAL,
   BOTH,
   FORCED_HORIZONTAL,
   FORCED_VERTICAL,
   FORCED_BOTH,
}

class RichTextBox : TextBoxBase {
   this() {
      super();

      _initRichtextbox();

      wstyle |= ES_MULTILINE | ES_WANTRETURN | ES_AUTOHSCROLL | ES_AUTOVSCROLL | WS_HSCROLL | WS_VSCROLL;
      wcurs = null; // So that the control can change it accordingly.
      wclassStyle = richtextboxClassStyle;

      version (DFL_NO_MENUS) {
      } else {
         with (miredo = new MenuItem) {
            text = "&Redo";
            click ~= &menuRedo;
            contextMenu.menuItems.insert(1, miredo);
         }

         contextMenu.popup ~= &menuPopup2;
      }
   }

   private {
      version (DFL_NO_MENUS) {
      } else {
         void menuRedo(Object sender, EventArgs ea) {
            redo();
         }

         void menuPopup2(Object sender, EventArgs ea) {
            miredo.enabled = canRedo;
         }

         MenuItem miredo;
      }
   }

   override @property Cursor cursor() {
      return wcurs; // Do return null and don't inherit.
   }

   alias cursor = TextBoxBase.cursor; // Overload.

   override @property Dstring selectedText() {
      if (created) {
         /+
         uint len = selectionLength + 1;
         Dstring result = new char[len];
         len = SendMessageA(handle, EM_GETSELTEXT, 0, cast(LPARAM)cast(char*)result);
         assert(!result[len]);
         return result[0 .. len];
         +/

         return dfl.internal.utf.emGetSelText(hwnd, selectionLength + 1);
      }
      return null;
   }

   alias selectedText = TextBoxBase.selectedText; // Overload.

   override @property void selectionLength(uint len) {
      if (created) {
         CHARRANGE chrg;
         SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
         chrg.cpMax = chrg.cpMin + len;
         SendMessageA(handle, EM_EXSETSEL, 0, cast(LPARAM)&chrg);
      }
   }

   // Current selection length, in characters.
   // This does not necessarily correspond to the length of chars; some characters use multiple chars.
   // An end of line (\r\n) takes up 2 characters.
   override @property uint selectionLength() {
      if (created) {
         CHARRANGE chrg;
         SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
         assert(chrg.cpMax >= chrg.cpMin);
         return chrg.cpMax - chrg.cpMin;
      }
      return 0;
   }

   override @property void selectionStart(uint pos) {
      if (created) {
         CHARRANGE chrg;
         SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
         assert(chrg.cpMax >= chrg.cpMin);
         chrg.cpMax = pos + (chrg.cpMax - chrg.cpMin);
         chrg.cpMin = pos;
         SendMessageA(handle, EM_EXSETSEL, 0, cast(LPARAM)&chrg);
      }
   }

   // Current selection starting index, in characters.
   // This does not necessarily correspond to the index of chars; some characters use multiple chars.
   // An end of line (\r\n) takes up 2 characters.
   override @property uint selectionStart() {
      if (created) {
         CHARRANGE chrg;
         SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
         return chrg.cpMin;
      }
      return 0;
   }

   override @property void maxLength(uint len) {
      lim = len;

      if (created) {
         SendMessageA(handle, EM_EXLIMITTEXT, 0, cast(LPARAM) len);
      }
   }

   alias maxLength = TextBoxBase.maxLength; // Overload.

   override @property Size defaultSize() {
      return Size(120, 120); // ?
   }

   private void _setbk(Color c) {
      if (created) {
         if (c._systemColorIndex == COLOR_WINDOW) {
            SendMessageA(handle, EM_SETBKGNDCOLOR, 1, 0);
         } else {
            SendMessageA(handle, EM_SETBKGNDCOLOR, 0, cast(LPARAM) c.toRgb());
         }
      }
   }

   override @property void backColor(Color c) {
      _setbk(c);
      super.backColor(c);
   }

   alias backColor = TextBoxBase.backColor; // Overload.

   private void _setfc(Color c) {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_COLOR;
         if (c._systemColorIndex == COLOR_WINDOWTEXT) {
            cf.dwEffects = CFE_AUTOCOLOR;
         } else {
            cf.crTextColor = c.toRgb();
         }

         _setFormat(&cf, SCF_ALL);
      }
   }

   override @property void foreColor(Color c) {
      _setfc(c);
      super.foreColor(c);
   }

   alias foreColor = TextBoxBase.foreColor; // Overload.

   final @property bool canRedo() {
      if (!created) {
         return false;
      }
      return SendMessageA(handle, EM_CANREDO, 0, 0) != 0;
   }

   final bool canPaste(DataFormats.Format df) {
      if (created) {
         if (SendMessageA(handle, EM_CANPASTE, df.id, 0)) {
            return true;
         }
      }

      return false;
   }

   final void redo() {
      if (created) {
         SendMessageA(handle, EM_REDO, 0, 0);
      }
   }

   // "Paste special."
   final void paste(DataFormats.Format df) {
      if (created) {
         SendMessageA(handle, EM_PASTESPECIAL, df.id, cast(LPARAM) 0);
      }
   }

   alias paste = TextBoxBase.paste; // Overload.

   final @property void selectionCharOffset(int yoffset) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_OFFSET;
      cf.yOffset = yoffset;

      _setFormat(&cf);
   }

   final @property int selectionCharOffset() {
      if (created) {
         CHARFORMAT2A cf;
         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_OFFSET;
         _getFormat(&cf);
         return cf.yOffset;
      }
      return 0;
   }

   final @property void selectionColor(Color c) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_COLOR;
      if (c._systemColorIndex == COLOR_WINDOWTEXT) {
         cf.dwEffects = CFE_AUTOCOLOR;
      } else {
         cf.crTextColor = c.toRgb();
      }

      _setFormat(&cf);
   }

   final @property Color selectionColor() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_COLOR;
         _getFormat(&cf);

         if (cf.dwMask & CFM_COLOR) {
            if (cf.dwEffects & CFE_AUTOCOLOR) {
               return Color.systemColor(COLOR_WINDOWTEXT);
            }
            return Color.fromRgb(cf.crTextColor);
         }
      }
      return Color.empty;
   }

   final @property void selectionBackColor(Color c) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_BACKCOLOR;
      if (c._systemColorIndex == COLOR_WINDOW) {
         cf.dwEffects = CFE_AUTOBACKCOLOR;
      } else {
         cf.crBackColor = c.toRgb();
      }

      _setFormat(&cf);
   }

   final @property Color selectionBackColor() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_BACKCOLOR;
         _getFormat(&cf);

         if (cf.dwMask & CFM_BACKCOLOR) {
            if (cf.dwEffects & CFE_AUTOBACKCOLOR) {
               return Color.systemColor(COLOR_WINDOW);
            }
            return Color.fromRgb(cf.crBackColor);
         }
      }
      return Color.empty;
   }

   final @property void selectionSubscript(bool byes) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
      if (byes) {
         cf.dwEffects = CFE_SUBSCRIPT;
      } else {
         // Make sure it doesn't accidentally unset superscript.
         CHARFORMAT2A cf2get;
         cf2get.cbSize = cf2get.sizeof;
         cf2get.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
         _getFormat(&cf2get);
         if (cf2get.dwEffects & CFE_SUPERSCRIPT) {
            return; // Superscript is set, so don't bother.
         }
         if (!(cf2get.dwEffects & CFE_SUBSCRIPT)) {
            return; // Don't need to unset twice.
         }
      }

      _setFormat(&cf);
   }

   final @property bool selectionSubscript() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
         _getFormat(&cf);

         return (cf.dwEffects & CFE_SUBSCRIPT) == CFE_SUBSCRIPT;
      }
      return false;
   }

   final @property void selectionSuperscript(bool byes) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
      if (byes) {
         cf.dwEffects = CFE_SUPERSCRIPT;
      } else {
         // Make sure it doesn't accidentally unset subscript.
         CHARFORMAT2A cf2get;
         cf2get.cbSize = cf2get.sizeof;
         cf2get.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
         _getFormat(&cf2get);
         if (cf2get.dwEffects & CFE_SUBSCRIPT) {
            return; // Subscript is set, so don't bother.
         }
         if (!(cf2get.dwEffects & CFE_SUPERSCRIPT)) {
            return; // Don't need to unset twice.
         }
      }

      _setFormat(&cf);
   }

   final @property bool selectionSuperscript() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
         _getFormat(&cf);

         return (cf.dwEffects & CFE_SUPERSCRIPT) == CFE_SUPERSCRIPT;
      }
      return false;
   }

   // FIX:
   private enum DWORD FONT_MASK = CFM_BOLD | CFM_ITALIC | CFM_STRIKEOUT | CFM_UNDERLINE | CFM_CHARSET | CFM_FACE | CFM_SIZE | CFM_UNDERLINETYPE | CFM_WEIGHT;

   final @property void selectionFont(Font f) {
      if (created) {
         // To-do: support Unicode font names.

         CHARFORMAT2A cf;
         LOGFONTA lf;

         f._info(&lf);

         cf.cbSize = cf.sizeof;
         cf.dwMask = FONT_MASK;

         //cf.dwEffects = 0;
         if (lf.lfWeight >= FW_BOLD) {
            cf.dwEffects |= CFE_BOLD;
         }
         if (lf.lfItalic) {
            cf.dwEffects |= CFE_ITALIC;
         }
         if (lf.lfStrikeOut) {
            cf.dwEffects |= CFE_STRIKEOUT;
         }
         if (lf.lfUnderline) {
            cf.dwEffects |= CFE_UNDERLINE;
         }
         cf.yHeight = cast(typeof(cf.yHeight)) Font.getEmSize(lf.lfHeight, GraphicsUnit.TWIP);
         cf.bCharSet = lf.lfCharSet;
         strcpy(cf.szFaceName.ptr, lf.lfFaceName.ptr);
         cf.bUnderlineType = CFU_UNDERLINE;
         cf.wWeight = cast(WORD) lf.lfWeight;

         _setFormat(&cf);
      }
   }

   // Returns null if the selection has different fonts.
   final @property Font selectionFont() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = FONT_MASK;
         _getFormat(&cf);

         if ((cf.dwMask & FONT_MASK) == FONT_MASK) {
            LOGFONTA lf;
            with (lf) {
               lfHeight = -Font.getLfHeight(cast(float) cf.yHeight, GraphicsUnit.TWIP);
               lfWidth = 0; // ?
               lfEscapement = 0; // ?
               lfOrientation = 0; // ?
               lfWeight = cf.wWeight;
               if (cf.dwEffects & CFE_BOLD) {
                  if (lfWeight < FW_BOLD) {
                     lfWeight = FW_BOLD;
                  }
               }
               lfItalic = (cf.dwEffects & CFE_ITALIC) != 0;
               lfUnderline = (cf.dwEffects & CFE_UNDERLINE) != 0;
               lfStrikeOut = (cf.dwEffects & CFE_STRIKEOUT) != 0;
               lfCharSet = cf.bCharSet;
               strcpy(lfFaceName.ptr, cf.szFaceName.ptr);
               lfOutPrecision = OUT_DEFAULT_PRECIS;
               lf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
               lf.lfQuality = DEFAULT_QUALITY;
               lf.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE;
            }
            //return new Font(Font._create(&lf));
            LogFont _lf;
            Font.LOGFONTAtoLogFont(_lf, &lf);
            return new Font(Font._create(_lf));
         }
      }

      return null;
   }

   final @property void selectionBold(bool byes) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_BOLD;
      if (byes) {
         cf.dwEffects |= CFE_BOLD;
      } else {
         cf.dwEffects &= ~CFE_BOLD;
      }
      _setFormat(&cf);
   }

   final @property bool selectionBold() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_BOLD;
         _getFormat(&cf);

         return (cf.dwEffects & CFE_BOLD) == CFE_BOLD;
      }
      return false;
   }

   final @property void selectionUnderline(bool byes) {
      if (!created) {
         return;
      }

      CHARFORMAT2A cf;

      cf.cbSize = cf.sizeof;
      cf.dwMask = CFM_UNDERLINE;
      if (byes) {
         cf.dwEffects |= CFE_UNDERLINE;
      } else {
         cf.dwEffects &= ~CFE_UNDERLINE;
      }
      _setFormat(&cf);
   }

   final @property bool selectionUnderline() {
      if (created) {
         CHARFORMAT2A cf;

         cf.cbSize = cf.sizeof;
         cf.dwMask = CFM_UNDERLINE;
         _getFormat(&cf);

         return (cf.dwEffects & CFE_UNDERLINE) == CFE_UNDERLINE;
      }
      return false;
   }

   final @property void scrollBars(RichTextBoxScrollBars sb) {
      LONG st;
      st = _style() & ~(ES_DISABLENOSCROLL | WS_HSCROLL | WS_VSCROLL | ES_AUTOHSCROLL | ES_AUTOVSCROLL);

      final switch (sb) {
      case RichTextBoxScrollBars.FORCED_BOTH:
         st |= ES_DISABLENOSCROLL;
         goto case RichTextBoxScrollBars.BOTH;
      case RichTextBoxScrollBars.BOTH:
         st |= WS_HSCROLL | WS_VSCROLL | ES_AUTOHSCROLL | ES_AUTOVSCROLL;
         break;

      case RichTextBoxScrollBars.FORCED_HORIZONTAL:
         st |= ES_DISABLENOSCROLL;
         goto case RichTextBoxScrollBars.HORIZONTAL;
      case RichTextBoxScrollBars.HORIZONTAL:
         st |= WS_HSCROLL | ES_AUTOHSCROLL;
         break;

      case RichTextBoxScrollBars.FORCED_VERTICAL:
         st |= ES_DISABLENOSCROLL;
         goto case RichTextBoxScrollBars.VERTICAL;
      case RichTextBoxScrollBars.VERTICAL:
         st |= WS_VSCROLL | ES_AUTOVSCROLL;
         break;

      case RichTextBoxScrollBars.NONE:
         break;
      }

      _style(st);

      _crecreate();
   }

   final @property RichTextBoxScrollBars scrollBars() {
      LONG wl = _style();

      if (wl & WS_HSCROLL) {
         if (wl & WS_VSCROLL) {
            if (wl & ES_DISABLENOSCROLL) {
               return RichTextBoxScrollBars.FORCED_BOTH;
            }
            return RichTextBoxScrollBars.BOTH;
         }

         if (wl & ES_DISABLENOSCROLL) {
            return RichTextBoxScrollBars.FORCED_HORIZONTAL;
         }
         return RichTextBoxScrollBars.HORIZONTAL;
      }

      if (wl & WS_VSCROLL) {
         if (wl & ES_DISABLENOSCROLL) {
            return RichTextBoxScrollBars.FORCED_VERTICAL;
         }
         return RichTextBoxScrollBars.VERTICAL;
      }

      return RichTextBoxScrollBars.NONE;
   }

   override int getLineFromCharIndex(int charIndex) {
      if (!isHandleCreated) {
         return -1; // ...
      }
      if (charIndex < 0) {
         return -1;
      }
      return SendMessageA(hwnd, EM_EXLINEFROMCHAR, 0, charIndex);
   }

   private void _getFormat(CHARFORMAT2A* cf, BOOL selection = TRUE)
   in {
      assert(created);
   }
   body {
      //SendMessageA(handle, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
      //CallWindowProcA(richtextboxPrevWndProc, hwnd, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
      dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd,
         EM_GETCHARFORMAT, selection, cast(LPARAM) cf);
   }

   private void _setFormat(CHARFORMAT2A* cf, WPARAM scf = SCF_SELECTION)
   in {
      assert(created);
   }
   body {
      /+
      //if(!SendMessageA(handle, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
      //if(!CallWindowProcA(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
      if(!dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf)) {
         throw new DflException("Unable to set text formatting");
      }
      +/
      dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd,
         EM_SETCHARFORMAT, scf, cast(LPARAM) cf);
   }

   private struct _StreamStr {
      Dstring str;
   }

   // Note: RTF should only be ASCII so no conversions are necessary.
   // TODO: verify this; I'm not certain.

   private void _streamIn(UINT fmt, Dstring str)
   in {
      assert(created);
   }
   body {
      _StreamStr si;
      EDITSTREAM es;

      si.str = str;
      es.dwCookie = cast(DWORD)&si;
      es.pfnCallback = &_streamingInStr;

      //if(SendMessageA(handle, EM_STREAMIN, cast(WPARAM)fmt, cast(LPARAM)&es) != str.length)
      // throw new DflException("Unable to set RTF");

      SendMessageA(handle, EM_STREAMIN, cast(WPARAM) fmt, cast(LPARAM)&es);
   }

   private Dstring _streamOut(UINT fmt)
   in {
      assert(created);
   }
   body {
      _StreamStr so;
      EDITSTREAM es;

      so.str = null;
      es.dwCookie = cast(DWORD)&so;
      es.pfnCallback = &_streamingOutStr;

      SendMessageA(handle, EM_STREAMOUT, cast(WPARAM) fmt, cast(LPARAM)&es);
      return so.str;
   }

   final @property void selectedRtf(Dstring rtf) {
      _streamIn(SF_RTF | SFF_SELECTION, rtf);
   }

   final @property Dstring selectedRtf() {
      return _streamOut(SF_RTF | SFF_SELECTION);
   }

   final @property void rtf(Dstring newRtf) {
      _streamIn(SF_RTF, rtf);
   }

   final @property Dstring rtf() {
      return _streamOut(SF_RTF);
   }

   final @property void detectUrls(bool byes) {
      autoUrl = byes;

      if (created) {
         SendMessageA(handle, EM_AUTOURLDETECT, byes, 0);
      }
   }

   final @property bool detectUrls() {
      return autoUrl;
   }

   /+
   override void createHandle() {
      if(isHandleCreated) {
         return;
      }

      createClassHandle(RICHTEXTBOX_CLASSNAME);

      onHandleCreated(EventArgs.empty);
   }
   +/

   /+
   override void createHandle() {
      /+ // TextBoxBase.createHandle() does this.
      if(!isHandleCreated) {
         Dstring txt;
         txt = wtext;

         super.createHandle();

         //dfl.internal.utf.setWindowText(hwnd, txt);
         text = txt; // So that it can be overridden.
      }
      +/
   }
   +/

   protected override void createParams(ref CreateParams cp) {
      super.createParams(cp);

      cp.className = RICHTEXTBOX_CLASSNAME;
      //cp.caption = null; // Set in createHandle() to allow larger buffers. // TextBoxBase.createHandle() does this.
   }

   //LinkClickedEventHandler linkClicked;
   Event!(RichTextBox, LinkClickedEventArgs) linkClicked;

protected:

   void onLinkClicked(LinkClickedEventArgs ea) {
      linkClicked(this, ea);
   }

   private Dstring _getRange(LONG min, LONG max)
   in {
      assert(created);
      assert(max >= 0);
      assert(max >= min);
   }
   body {
      if (min == max) {
         return null;
      }

      TEXTRANGEA tr;
      char[] s;

      tr.chrg.cpMin = min;
      tr.chrg.cpMax = max;
      max = max - min + 1;
      if (dfl.internal.utf.useUnicode) {
         max = cast(uint) max << 1;
      }
      s = new char[max];
      tr.lpstrText = s.ptr;

      //max = SendMessageA(handle, EM_GETTEXTRANGE, 0, cast(LPARAM)&tr);
      max = dfl.internal.utf.sendMessage(handle, EM_GETTEXTRANGE, 0, cast(LPARAM)&tr);
      Dstring result;
      if (dfl.internal.utf.useUnicode) {
         result = fromUnicode(cast(wchar*) s.ptr, max);
      } else {
         result = fromAnsi(s.ptr, max);
      }
      return result;
   }

   protected override void onReflectedMessage(ref Message m) {
      super.onReflectedMessage(m);

      switch (m.msg) {
      case WM_NOTIFY: {
            NMHDR* nmh;
            nmh = cast(NMHDR*) m.lParam;

            assert(nmh.hwndFrom == handle);

            switch (nmh.code) {
            case EN_LINK: {
                  ENLINK* enl;
                  enl = cast(ENLINK*) nmh;

                  if (enl.msg == WM_LBUTTONUP) {
                     if (!selectionLength) {
                        onLinkClicked(new LinkClickedEventArgs(_getRange(enl.chrg.cpMin,
                           enl.chrg.cpMax)));
                     }
                  }
               }
               break;

            default:
            }
         }
         break;

      default:
      }
   }

   override void onHandleCreated(EventArgs ea) {
      super.onHandleCreated(ea);

      SendMessageA(handle, EM_AUTOURLDETECT, autoUrl, 0);

      _setbk(this.backColor);

      //Application.doEvents(); // foreColor won't work otherwise.. seems to work now
      _setfc(this.foreColor);

      SendMessageA(handle, EM_SETEVENTMASK, 0, ENM_CHANGE | ENM_CHANGE | ENM_LINK | ENM_PROTECTED);
   }

   override void prevWndProc(ref Message m) {
      m.result = CallWindowProcA(richtextboxPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
      //m.result = dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
   }

private:
   bool autoUrl = true;
}

private extern (Windows) DWORD _streamingInStr(DWORD dwCookie, LPBYTE pbBuff, LONG cb,
   LONG* pcb) nothrow {
   RichTextBox._StreamStr* si;
   si = cast(typeof(si)) dwCookie;

   if (!si.str.length) {
      *pcb = 0;
      return 1; // ?
   } else if (cb >= si.str.length) {
      pbBuff[0 .. si.str.length] = (cast(BYTE[]) si.str)[];
      *pcb = si.str.length;
      si.str = null;
   } else {
      pbBuff[0 .. cb] = (cast(BYTE[]) si.str)[0 .. cb];
      *pcb = cb;
      si.str = si.str[cb .. si.str.length];
   }

   return 0;
}

private extern (Windows) DWORD _streamingOutStr(DWORD dwCookie, LPBYTE pbBuff, LONG cb,
   LONG* pcb) nothrow {
   RichTextBox._StreamStr* so;
   so = cast(typeof(so)) dwCookie;

   so.str ~= cast(Dstring) pbBuff[0 .. cb];
   *pcb = cb;

   return 0;
}
