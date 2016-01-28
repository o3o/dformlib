import dfl;

class MyForm: Form {
   Button button2;
   this() {
      initializeMyForm();
   }

   private void initializeMyForm() {
      clientSize = dfl.Size(684, 251);
      button2 = new Button();
      button2.name = "button2";
      button2.text = "Hello World";
      button2.bounds = Rect(80, 40, 510, 150);
      button2.parent = this;
      button2.click ~= &click;
   }

   private void click(Control c, EventArgs args) {
      msgBox("Hello world");
   }
}

int main() {
   int result = 0;
   try {
      Application.enableVisualStyles();
      Application.run(new MyForm());
   } catch (Exception o) {
      msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
      result = 1;
   }
   return result;
}
