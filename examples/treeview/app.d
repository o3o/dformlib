import dfl;

class TreeViewForm: Form {
   TreeView tview;
   Label selnode;

   ContextMenu nodeMenu, noNodeMenu;


   this() {
      initializeTreeViewForm();

      initializeMenus();

      with(tview = new TreeView) {
         width = 120;
         dock = DockStyle.LEFT;
         sorted = true;
         parent = this;

         TreeNode helloNode, worldNode, pieNode;

         helloNode = new TreeNode("hello");
         nodes.add(helloNode);

         worldNode = new TreeNode("world");
         nodes.add(worldNode);

         nodes.add("last");

         helloNode.nodes.add("hello child");
         helloNode.nodes.add("pine");
         helloNode.nodes.add("apple");
         helloNode.nodes.add("fish");

         pieNode = new TreeNode("pie");
         worldNode.nodes.add(pieNode);
         worldNode.nodes.add("chocolate");
         worldNode.nodes.add("candy");

         pieNode.nodes.add("tree");

         afterSelect ~= &onTreeSelect;
         mouseDown ~= &onTreeMouseDown;

         labelEdit = true;
         afterLabelEdit ~= &tview_afterLabelEdit;
      }

      with(new Button)
      {
         text = "&Expand All";
         location = Point(170, 40);
         parent = this;

         click ~= &onExpandClick;
      }

      with(new Button)
      {
         text = "&Collapse All";
         location = Point(170, 80);
         parent = this;

         click ~= &onCollapseClick;
      }

      with(selnode = new Label)
      {
         bounds = Rect(140, 160, 400, 40);
         useMnemonic = false;
         font = new Font("Courier New", 9);
         parent = this;
         backColor = this.backColor;
      }
   }


   private void tview_afterLabelEdit(Object sender, NodeLabelEditEventArgs ea) {
      if(DialogResult.YES != msgBox(this, `"` ~ ea.label ~ `"?`, "Edit label?", MsgBoxButtons.YES_NO, MsgBoxIcon.QUESTION))
         ea.cancelEdit = true;
   }


   private void onExpandClick(Object sender, EventArgs ea) {
      tview.expandAll();
   }


   private void onCollapseClick(Object sender, EventArgs ea) {
      tview.collapseAll();
   }


   private void onTreeSelect(Object sender, TreeViewEventArgs ea) {
      selnode.text = ea.node.fullPath;
   }


   private void onTreeMouseDown(Object sender, MouseEventArgs ea)
   {
      if(ea.button == MouseButtons.RIGHT)
      {
         TreeNode node;
         node = tview.getNodeAt(ea.x, ea.y);
         if(node)
         {
            tview.selectedNode = node;
            nodeMenu.show(tview, Cursor.position);
         }
         else
         {
            noNodeMenu.show(tview, Cursor.position);
         }
      }
   }


   private void initializeTreeViewForm()
   {
      // Do not manually edit this block of code.
      //~DFL Designer 0.3 code begins here.

      //~DFL MainForm
      startPosition = FormStartPosition.CENTER_SCREEN;
      text = "DFL TreeView Example";
      clientSize = Size(292, 273);
      location = Point(0, 0);

      //~DFL Designer 0.3 code ends here.
   }


   private void initializeMenus()
   {
      MenuItem mi;

      nodeMenu = new ContextMenu;

      with(mi = new MenuItem)
      {
         text = "&Add Child Node...";
         index = 0;
         nodeMenu.menuItems.add(mi);

         click ~= &onMenuAddChildNodeClick;
      }

      with(mi = new MenuItem)
      {
         text = "&Delete Node";
         index = 1;
         nodeMenu.menuItems.add(mi);

         click ~= &onMenuDeleteNode;
      }

      /+
         with(mi = new MenuItem)
         {
            text = "-";
            index = 2;
            nodeMenu.menuItems.add(mi);
         }

      with(mi = new MenuItem)
      {
         text = "&Expand";
         index = 3;
         nodeMenu.menuItems.add(mi);

         click ~= &onMenuExpandChildNodes;
      }

      with(mi = new MenuItem)
      {
         text = "&Collapse";
         index = 4;
         nodeMenu.menuItems.add(mi);

         click ~= &onMenuCollapseChildNodes;
      }
      +/

         noNodeMenu = new ContextMenu;

      with(mi = new MenuItem)
      {
         text = "&Add Node...";
         index = 0;
         noNodeMenu.menuItems.add(mi);

         click ~= &onMenuAddNode;
      }
   }


   private class AskForNodeNameForm: Form
   {
      // Valid on return only if -dialogResult- is OK.
      string nodeName;

      TextBox tbox;
      Button okBtn, cancelBtn;


      this()
      {
         const int CWIDTH = 220;

         dialogResult = DialogResult.CANCEL;
         text = "Node Name";
         startPosition = FormStartPosition.CENTER_PARENT;
         formBorderStyle = FormBorderStyle.FIXED_DIALOG;
         minimizeBox = false;
         maximizeBox = false;
         icon = null;

         with(tbox = new TextBox)
         {
            bounds = Rect(0, 0, CWIDTH, height);
            parent = this;
         }

         with(okBtn = new Button)
         {
            text = "OK";
            location = Point(CWIDTH - 4 - width - 4 - width, tbox.bottom + 4);
            parent = this;

            click ~= &onOkClick;
         }
         acceptButton = okBtn;

         with(cancelBtn = new Button)
         {
            text = "Cancel";
            location = Point(CWIDTH - 4 - width, okBtn.top);
            parent = this;

            click ~= &onCancelClick;
         }
         cancelButton = cancelBtn;

         clientSize = Size(CWIDTH, okBtn.bottom + 4);
      }


      private void onOkClick(Object sender, EventArgs ea)
      {
         nodeName = tbox.text;
         dialogResult = DialogResult.OK;
         hide();
      }


      private void onCancelClick(Object sender, EventArgs ea)
      {
         hide();
      }
   }


   private void onMenuExpandChildNodes(Object sender, EventArgs ea)
   {
      TreeNode node;
      node = tview.selectedNode;
      if(node)
         node.expand();
   }


   private void onMenuCollapseChildNodes(Object sender, EventArgs ea)
   {
      TreeNode node;
      node = tview.selectedNode;
      if(node)
         node.collapse();
   }


   private void onMenuAddChildNodeClick(Object sender, EventArgs ea)
   {
      TreeNode node;
      node = tview.selectedNode;
      if(node)
      {
         AskForNodeNameForm ask;
         ask = new AskForNodeNameForm;
         ask.showDialog();
         ask.dispose(); // Destroy its handle.
         if(DialogResult.OK == ask.dialogResult)
         {
            node.nodes.add(ask.nodeName);
         }
      }
   }


   private void onMenuDeleteNode(Object sender, EventArgs ea)
   {
      TreeNode node;
      node = tview.selectedNode;
      if(node)
         node.remove();
   }


   private void onMenuAddNode(Object sender, EventArgs ea)
   {
      AskForNodeNameForm ask;
      ask = new AskForNodeNameForm;
      ask.showDialog();
      ask.dispose(); // Destroy its handle.
      if(DialogResult.OK == ask.dialogResult)
      {
         tview.nodes.add(ask.nodeName);
      }
   }
}


int main() {
   int result = 0;

   try {
      Application.enableVisualStyles();
      Application.run(new TreeViewForm);
   } catch(DflThrowable o) {
      msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
      result = 1;
   }
   return result;
}

