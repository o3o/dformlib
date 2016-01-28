import dfl;


class MainForm: Form {
   TabControl tctrl;
   TextBox tab4box;


   this() {
      text = "Tabs";
      size = Size(380, 300);
      startPosition = FormStartPosition.CENTER_SCREEN;

      Label label;
      with(tctrl = new TabControl) {
         multiline = true;
         dock = DockStyle.FILL;

         TabPage tp;

         tp = new TabPage("Tab 1");
         tp.backColor = Color(0, 0, 0xDD);
         with(label = new Label) {
            backColor = tp.backColor;
            foreColor = Color(0xDD, 0xDD, 0xFF);
            bounds = Rect(20, 20, 400, 40);
            useMnemonic = false;
            font = new Font("Arial", 11f, FontStyle.BOLD);
            label.text = Environment.osVersion.toString();
            parent = tp;
         }
         tabPages.add(tp);

         tabPages.add("Tab 2  :\u00FE");

         tp = new TabPage("Tab 3");
         tp.backColor = Color(0, 0xDD, 0);
         with(label = new Label) {
            backColor = tp.backColor;
            foreColor = Color.fromRgb(cast(int)0);
            bounds = Rect(20, 20, 400, 40);
            useMnemonic = false;
            font = new Font("Courier New", 10f, FontStyle.BOLD);
            label.text = Environment.machineName;
            parent = tp;
         }
         tabPages.add(tp);

         tp = new TabPage("Tab 4");
         tp.borderStyle = BorderStyle.FIXED_3D;
         with(tab4box = new TextBox) {
            text = tp.text;
            location = Point(20, 20);
            parent = tp;
         }
         Button btn;
         with(btn = new Button) {
            text = "Text";
            location = Point(tab4box.right + 4, 20);
            parent = tp;
            click ~= &acceptButton_click;
         }
         this.acceptButton = btn;
         tabPages.add(tp);

         tp = new TabPage("Tab 5");
         tp.backColor = Color(0xDD, 0, 0);
         tp.dockPadding.all = 32;
         with(new TextBox) {
            text = "This is tab number 5!";
            multiline = true;
            acceptsReturn = true;
            dock = DockStyle.FILL;
            parent = tp;
         }
         tabPages.add(tp);

         parent = this;

         selectedIndexChanging ~= &tctrl_selectedIndexChanging;
      }
   }


   private void acceptButton_click(Object sender, EventArgs ea) {
      tctrl.tabPages[3].text = tab4box.text;
   }


   private void tctrl_selectedIndexChanging(Object sender, CancelEventArgs ea) {
      if(tctrl.selectedIndex == 1) {
         if(DialogResult.OK == msgBox(this, "Do not leave Tab 2, do not collect $200",
                                      text, MsgBoxButtons.OK_CANCEL, MsgBoxIcon.INFORMATION)) {
            ea.cancel = true;
         }
      }
   }
}


int main() {
   int result = 0;

   try {
      Application.run(new MainForm);
   } catch(DflThrowable o) {
      msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);

      result = 1;
   }

   return result;
}

