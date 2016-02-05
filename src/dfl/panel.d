// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.

module dfl.panel;

import core.sys.windows.windows;

import dfl.control;
import dfl.exception;
import dfl.base;

class Panel : ContainerControl {

   @property void borderStyle(BorderStyle bs) {
      final switch (bs) {
      case BorderStyle.FIXED_3D:
         _style(_style() & ~WS_BORDER);
         _exStyle(_exStyle() | WS_EX_CLIENTEDGE);
         break;

      case BorderStyle.FIXED_SINGLE:
         _exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
         _style(_style() | WS_BORDER);
         break;

      case BorderStyle.NONE:
         _style(_style() & ~WS_BORDER);
         _exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
         break;
      }

      if (created) {
         redrawEntire();
      }
   }

   @property BorderStyle borderStyle() {
      if (_exStyle() & WS_EX_CLIENTEDGE) {
         return BorderStyle.FIXED_3D;
      } else if (_style() & WS_BORDER) {
         return BorderStyle.FIXED_SINGLE;
      }
      return BorderStyle.NONE;
   }

   this() {
      //ctrlStyle |= ControlStyles.SELECTABLE | ControlStyles.CONTAINER_CONTROL;
      ctrlStyle |= ControlStyles.CONTAINER_CONTROL;
      /+ wstyle |= WS_TABSTOP; +/ // Should WS_TABSTOP be set?
      //wexstyle |= WS_EX_CONTROLPARENT; // Allow tabbing through children. ?
   }
}
