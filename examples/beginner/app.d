// This code is public domain.


import std.conv;

import dfl;

class MainForm: Form {
   GroupBox myGroup;
   RadioButton likeDfl, okDfl, hateDfl, whatDfl;
   TextBox myTextBox;
   Button voteBtn;


   this() {
      // Initialize some of this Form's properties.
      width = 220;
      startPosition = FormStartPosition.CENTER_SCREEN;
      formBorderStyle = FormBorderStyle.FIXED_DIALOG; // Don't allow resize.
      maximizeBox = false;
      text = "DFL Beginner Example"; // Form's caption text.

      // Add a GroupBox.
      with(myGroup = new GroupBox) {
         bounds = Rect(4, 4, this.clientSize.width - 8, 120); // Set the x, y, width, and height.
         text = "DFL &Poll"; // Text displayed at the top of the box.
         parent = this; // Set myGroup's parent to this Form.
      }

      // Add some RadioButton`s to the GroupBox myGroup..

      with(likeDfl = new RadioButton) {
         bounds = Rect(6, 18, 160, 13); // x, y, width and height within the GroupBox.
         text = "I Like DFL"; // Text displayed next to the selector thing.
         checked = true; // Check this one, but not the others.
         parent = myGroup; // Set likeDfl's parent to the GroupBox.
      }

      with(okDfl = new RadioButton) {
         bounds = Rect(6, likeDfl.bottom + 4, 160, 13); // 4px below likeDfl.
         text = "DFL is OK";
         //checked = false; // false is default. Set one to true per group.
         parent = myGroup;
      }

      with(hateDfl = new RadioButton) {
         bounds = Rect(6, okDfl.bottom + 4, 160, 13);
         text = "I hate DFL!";
         parent = myGroup;
      }

      with(whatDfl = new RadioButton) {
         bounds = Rect(6, hateDfl.bottom + 4, 160, 13);
         text = "What is DFL?";
         parent = myGroup;
      }

      // Update myGroup's height to fit all the RadioButtons.
      // The client size is the area inside the control, excluding the border.
      myGroup.clientSize = Size(myGroup.clientSize.width, whatDfl.bottom + 6);

      // Add a Label for the following TextBox.
      Label myLabel;
      with(myLabel = new Label) {
         bounds = Rect(4, myGroup.bottom + 4, 200, 13); // 4px below myGroup.
         myLabel.text = "&Comments (one per line):";
         parent = this;
      }

      // Add a TextBox below the GroupBox.
      with(myTextBox = new TextBox) {
         bounds = Rect(4, myLabel.bottom + 4, this.clientSize.width - 8, 100); // 4px below Label.
         multiline = true;
         acceptsReturn = true;
         parent = this;
      }

      // Add a button and a click event handler.
      with(voteBtn = new Button) {
         location = Point(this.clientSize.width - voteBtn.width - 4, myTextBox.bottom + 4); // width/height are default.
         text = "&Vote";
         parent = this;

         click ~= &this.voteBtn_click;
      }

      // Set the Form's "accept button", or default button.
      acceptButton = voteBtn;

      // Update the Form's height to fit all the controls.
      // The client size is the area inside the Form, excluding the border and caption.
      clientSize = Size(clientSize.width, voteBtn.bottom + 4);
   }


   // Click handler for voteBtn.
   private void voteBtn_click(Object sender, EventArgs ea) {
      string s;
      string[] comments;
      RadioButton voteOption;

      // Gather comments.
      comments = myTextBox.lines;
      if (!comments.length) {
         if (DialogResult.YES != msgBox("Are you sure that you do not want to comment on DFL?",
                                        "DFL Comments", MsgBoxButtons.YES_NO, MsgBoxIcon.QUESTION)) {
            // They're not sure, they want to stop the vote and add a comment..
            return; // Abort.
         }
      }

      // See which option they voted for.
      if (likeDfl.checked) {
         voteOption = likeDfl;
      } else if (okDfl.checked) {
         voteOption = okDfl;
      } else if (hateDfl.checked) {
         voteOption = hateDfl;
      } else if (whatDfl.checked) {
         voteOption = whatDfl;
      } else {
         assert(0);
      }

      s = "You voted for \"" ~ voteOption.text ~ "\".\r\n\r\n";
      if (comments.length) {
         s ~= "Your comments are:";
         foreach(int i, string comment; comments) {
            s ~= "\r\n   " ~ std.conv.to!string(i + 1) ~ ") " ~ comment;
         }
      } else {
         s ~= "You did not add comments.";
      }

      msgBox(s, "Thanks for Voting!", MsgBoxButtons.OK, MsgBoxIcon.INFORMATION);

      // Now reset everything.
      voteOption.checked = false;
      likeDfl.checked = true;
      myTextBox.text = "";
   }
}


int main() {
   int result = 0;

   try {
      Application.run(new MainForm);
   } catch (DflThrowable o) {
      msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);

      result = 1;
   }

   return result;
}

