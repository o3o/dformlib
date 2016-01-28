import dfl;

class OpenFile: Form {
	private Button open;
	private Label label1;


	this() {
		initializeMyForm();
	}


	private void initializeMyForm() {
		text = "My Form";
		clientSize = Size(280, 182);
		open = new Button();
		open.name = "open";
		open.dock = DockStyle.BOTTOM;
		open.text = "Open";
		open.bounds = Rect(0, 118, 280, 64);
		open.parent = this;
      open.click ~= &click;

		label1 = new Label();
		label1.name = "label1";
		label1.dock = DockStyle.TOP;
		label1.borderStyle = BorderStyle.FIXED_SINGLE;
		label1.bounds = Rect(0, 0, 280, 56);
		label1.parent = this;
	}

   private void click(Control c, EventArgs args) {
      FileDialog fd = new OpenFileDialog();
      fd.showDialog();
      label1.text = fd.fileName();
   }
}

int main() {
   int result = 0;
   try	{
      Application.enableVisualStyles();

      Application.run(new OpenFile());
   } catch (Exception e) {
      msgBox(e.msg, "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
      result = 1;
   }

   return result;
}

