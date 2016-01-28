# dformlib
[![Build Status](https://travis-ci.org/o3o/dformlib.svg?branch=master)](https://travis-ci.org/o3o/dformlib)

Yet another fork of Christopher Miller [D Form Library](http://www.dprogramming.com/), based on [Rayerd work](https://github.com/Rayerd/dfl).




## Compiling DFormLib

The simplest way to compile with dformlib is to use [dub](http://code.dlang.org/) package.


## Examples

```
import dfl;

int main() {
   Form myForm;
   Label myLabel;

   myForm = new Form;
   myForm.text = "DFL Example";

   myLabel = new Label;
   myLabel.font = new Font("Verdana", 14f);
   myLabel.text = "Hello, DFL World!";
   myLabel.location = Point(15, 15);
   myLabel.autoSize = true;
   myLabel.parent = myForm;

   Application.run(myForm);

   return 0;
}
```

See also _examples_ directory and [here](https://github.com/SeijiFujita/dfl-examples-d2).

## License

The project is licensed under the terms of the [Boost Software License, Version 1.0](http://www.boost.org/LICENSE_1_0.txt)
