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
import dfl.base;
import dfl.menu;
import dfl.control;
import dfl.usercontrol;
import dfl.form;
import dfl.drawing;
import dfl.panel;
import dfl.event;
import dfl.application;
import dfl.button;
//import dfl.socket;
import dfl.timer;
import dfl.environment;
import dfl.label;
import dfl.textbox;
import dfl.listbox;
import dfl.splitter;
import dfl.groupbox;
import dfl.messagebox;
import dfl.registry;
import dfl.notifyicon;
import dfl.collections;
import dfl.data;
import dfl.clipboard;
import dfl.commondialog;
import dfl.richtextbox;
import dfl.tooltip;
import dfl.combobox;
import dfl.treeview;
import dfl.picturebox;
import dfl.tabcontrol;
import dfl.listview;
import dfl.statusbar;
import dfl.progressbar;
import dfl.resources;
import dfl.imagelist;
import dfl.toolbar;
