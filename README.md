# dformlib
Yet another fork of Christopher Miller [D Form Library](http://www.dprogramming.com/), based on [Rayerd work](https://github.com/Rayerd/dfl).




## Compiling DFormLib

The simplest way to compile with dformlib is to use [dub](http://code.dlang.org/) package.

```
$ dub build
```

Or you can use make:
```
$ make
```

## Examples

```
import dfl;

int main() {
   Form myForm;
   Label myLabel;

   myForm = new Form;
   myForm.text = "dformlib Example";

   myLabel = new Label;
   myLabel.font = new Font("Verdana", 14f);
   myLabel.text = "Hello, dformlib World!";
   myLabel.location = Point(15, 15);
   myLabel.autoSize = true;
   myLabel.parent = myForm;

   Application.run(myForm);

   return 0;
}
```

See also _examples_ directory and [here](https://github.com/SeijiFujita/dfl-examples-d2).

## Related Projects

| Project                                          | Author        | Notes                                    | DUB |
| -----------------------------                    | -------       | -------                                  | --- |
| [dfl](http://wiki.dprogramming.com/Dfl/HomePage) | C. Miller     | Abandoned                                | no  |
| [DFL](https://github.com/rahim14/DFL)            | Rahim Firouzi | With Entice Design                       | yes |
| [dfl](https://github.com/Rayerd/dfl)             |               |                                          | no  |
| [DFL2](https://github.com/FrankLIKE/dfl2)        | FrankLike     |                                          | yes |
| [DGui](https://bitbucket.org/dgui/dgui)          | Antonio Trogu | Components can be positioned using Docks | yes |


## License

The project is licensed under the terms of the [Boost Software License, Version 1.0](http://www.boost.org/LICENSE_1_0.txt)
