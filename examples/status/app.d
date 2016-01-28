import dfl;

class Status: Form {
   // Do not modify or move this block of variables.
   //~Entice Designer variables begin here.
   StatusBar sbar;
   Button button1;
   TextBox textBox1;
   GroupBox groupBox1;
   CheckBox checkBox1;
   Label label1;

   this() {
      initializeStatus();

      sbar.showPanels = true; // Show panels at first.
      sbar.panels.add(new StatusBarPanel("<None>"));
      sbar.panels.add(new StatusBarPanel("Hover mouse over controls", -1));

      autoScale = true;

      button1.mouseEnter ~= &control_enter;
      textBox1.mouseEnter ~= &control_enter;
      //groupBox1.mouseEnter ~= &control_enter;
      checkBox1.mouseEnter ~= &control_enter;
      label1.mouseEnter ~= &control_enter;

      this.mouseEnter ~= &form_enter;
   }


   private void control_enter(Control sender, MouseEventArgs ea) {
      sbar.text = sender.text; // Set no-panels text.
      sbar.showPanels = false; // Shows text property instead of panels.
   }


   private void form_enter(Control sender, MouseEventArgs ea) {
      sbar.showPanels = true; // Go back to the panels.
   }


   private void initializeStatus() {
      // Do not manually modify this function.
      //~Entice Designer 0.8.2.1 code begins here.
      //~DFL Form
      text = "Status";
      clientSize = Size(292, 273);
      //~DFL StatusBar:dfl.label.Label=sbar
      sbar = new StatusBar();
      sbar.name = "sbar";
      sbar.dock = DockStyle.BOTTOM;
      sbar.bounds = Rect(0, 250, 292, 23);
      sbar.parent = this;
      //~DFL dfl.button.Button=button1
      button1 = new Button();
      button1.name = "button1";
      button1.text = "Hello";
      button1.bounds = Rect(8, 8, 75, 23);
      button1.parent = this;
      //~DFL dfl.textbox.TextBox=textBox1
      textBox1 = new TextBox();
      textBox1.name = "textBox1";
      textBox1.text = "In a text box!";
      textBox1.bounds = Rect(8, 40, 120, 23);
      textBox1.parent = this;
      //~DFL dfl.groupbox.GroupBox=groupBox1
      groupBox1 = new GroupBox();
      groupBox1.name = "groupBox1";
      groupBox1.text = "Group";
      groupBox1.bounds = Rect(8, 72, 88, 52);
      groupBox1.parent = this;
      //~DFL dfl.button.CheckBox=checkBox1
      checkBox1 = new CheckBox();
      checkBox1.name = "checkBox1";
      checkBox1.text = "Check!";
      checkBox1.bounds = Rect(12, 23, 59, 23);
      checkBox1.parent = groupBox1;
      //~DFL dfl.label.Label=label1

      label1 = new Label();
      label1.name = "label1";
      label1.backColor = Color(28, 128, 166);
      label1.font = new Font("Verdana", 9f, FontStyle.BOLD);
      label1.foreColor = Color(253, 204, 36);
      label1.text = "Label...";
      label1.borderStyle = BorderStyle.FIXED_SINGLE;
      label1.textAlign = ContentAlignment.MIDDLE_CENTER;
      label1.bounds = Rect(80, 136, 100, 23);
      label1.parent = this;
   }
}


int main() {
   int result = 0;

   try {
      Application.run(new Status());
   } catch(DflThrowable o) {
      msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
      result = 1;
   }

   return result;
}

