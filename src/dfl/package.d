// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


/// Imports all of DFL's public interface.
module dfl;


version(bud)
version = build;
version(DFL_NO_BUD_DEF)
version = DFL_NO_BUILD_DEF;


version(build) {
   version(WINE) {
   }
   else {
      version(DFL_NO_LIB) {
      }
      else {
         pragma(link, "dfl_build");

         pragma(link, "ws2_32");
         pragma(link, "gdi32");
         pragma(link, "comctl32");
         pragma(link, "advapi32");
         pragma(link, "comdlg32");
         pragma(link, "ole32");
         pragma(link, "uuid");
      }

      version(DFL_NO_BUILD_DEF) {
      }
      else {
         pragma(build_def, "EXETYPE NT");
         version(gui) {
            pragma(build_def, "SUBSYSTEM WINDOWS,4.0");
         }
         else {
            pragma(build_def, "SUBSYSTEM CONSOLE,4.0");
         }
      }
   }
}


public:
import dfl.application;
import dfl.base;
import dfl.button;
import dfl.clipboard;
import dfl.clippingform;
import dfl.collections;
import dfl.colordialog;
import dfl.combobox;
import dfl.commondialog;
import dfl.control;
import dfl.data;
import dfl.drawing;
import dfl.environment;
import dfl.event;
import dfl.exception;
import dfl.filedialog;
import dfl.folderdialog;
import dfl.fontdialog;
import dfl.form;
import dfl.groupbox;
import dfl.imagelist;
import dfl.label;
import dfl.listbox;
import dfl.listview;
import dfl.menu;
import dfl.messagebox;
import dfl.notifyicon;
import dfl.panel;
import dfl.picturebox;
import dfl.progressbar;
import dfl.registry;
import dfl.resources;
import dfl.richtextbox;
import dfl.splitter;
import dfl.statusbar;
import dfl.tabcontrol;
import dfl.textbox;
import dfl.timer;
import dfl.toolbar;
import dfl.tooltip;
import dfl.treeview;
import dfl.usercontrol;
