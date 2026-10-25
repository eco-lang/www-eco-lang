---
title: "JavaScript output"
description: "Why Eco keeps the stock Elm compiler's JavaScript and HTML generator, unchanged and fed from the untyped program, alongside its native back end."
section: "The compiler"
sectionOrder: 2
order: 9
---

Eco still writes JavaScript, with the same generator stock Elm uses, and we think it should keep doing so for two reasons. The compiler is itself an Elm program, so before any native binary of it exists it has to run as JavaScript. Elm's JavaScript output is also the established behaviour of Elm programs, and so the reference the native path is checked against.

> **Background**
> - [Kernel](/docs/glossary#kernel): a built-in function with no Elm body, implemented in the host language.
> - [Fixed point](/docs/glossary#fixed-point): a compiler that rebuilds itself and gets identical output.

## Choosing JavaScript

The output file name picks the back end, once for the whole build. A name ending in `.js` or `.html` selects this generator, `.mlir` selects MLIR, and any other name selects a native output whose kind the extension decides. With no output name, the build writes `index.html` for a project with one entry point and `elm.js` for several, as `elm make` does.

The `--debug`, `--optimize` and `--sourcemaps` options mean what they mean in Elm and affect only this generator. Development mode writes readable code. Debug mode adds the type information the Elm debugger needs. Production mode gives the most frequent record fields the shortest names.

## Same driver, different program

The JavaScript and MLIR generators are two back ends of one [build driver](/docs/build-driver). They share project loading, caching and error reporting, but not the program they read. A JavaScript build takes the erased path: the front end, then Elm's own optimiser, which drops types, then this generator. The typed, specialized program that feeds MLIR never reaches it, and a JavaScript build writes none of the typed artifacts. The generator's interface takes the erased graph in its type, so a JavaScript back end cannot be handed typed data by accident.

The generator walks the program from its entry points and writes every reachable definition once, dependencies first, inside a single JavaScript function. Decision trees become chains of `if` and `switch`, tail calls become loops, and the file opens with the helpers that make curried calls of two to nine arguments cheap, followed by the kernel JavaScript of the libraries the program uses. All of that is the stock design, left alone so that Eco's output stays interchangeable with Elm's.

Here is the `area` function from [the tour](/docs/tour), built with `eco make src/Main.elm --output=main.js`:

```javascript
var $author$project$Main$area = function (shape) {
	switch (shape.$) {
		case 'Circle':
			var r = shape.a;
			return (3.14 * r) * r;
		case 'Rect':
			var w = shape.a;
			var h = shape.b;
			return w * h;
		default:
			var s = shape.a;
			return s * s;
	}
};
```

This is character for character what stock Elm writes. The constructor is a string tag on a JavaScript object and every number is a JavaScript double. Compare the native version in the tour, where the same `case` reads an integer tag from a heap header and multiplies raw `f64` values. The two outputs share nothing below the decision tree.

Kernel names are the one place Eco departs from the stock generator. Eco's own kernel package shares module names with Elm's libraries (`File`, `Http`, `Process`), and both `File` kernels define `_File_size`. Under stock Elm's flat names, one kernel would silently replace the other and the program would fail at load. Elm kernels therefore keep their stock `_Module_name`, which leaves the output for ordinary Elm programs unchanged, and Eco kernels are named `_Eco_Module_name`.

## Why Eco keeps it

**The bootstrap needs it.** Stock Elm builds the compiler as JavaScript. That JavaScript compiler then rebuilds itself through this generator until the output stops changing, and only then emits the MLIR that becomes the first native compiler. Without this generator there is no path from stock Elm to a native Eco ([The compiler compiles itself](/docs/bootstrap)). The fixed point also constrains the native compiler: when it writes JavaScript, the text it prints for a float literal must match what the JavaScript-hosted compiler prints, or the outputs differ.

**Browser projects need it.** Because the generator and its options are stock Elm, Eco can replace `elm make` for a browser project.

**The native path needs a reference.** The native runtime's rules for effects and ports are stated as parity with the JavaScript runtime, so native matches JavaScript and not the other way round. Our benchmarks compare Eco's JavaScript output with its native output.

The generator reads the erased program because that is stock Elm's design. JavaScript does not need types, so Elm drops them after type checking. Leaving the generator there has a cost, since it cannot use anything the typed stages learn, but it frees the typed representation to be shaped entirely for native code.

> **Designs we didn't use.** Feeding the generator from the typed or specialized program, to improve its output, would tie it to data whose shape is chosen for native code and changes for native reasons. An improvement both back ends would benefit from belongs in the optimiser that builds the erased program.

## Further reading

- [The compiler](/docs/compiler) — the typed and erased paths, and where they split.
- [The build driver](/docs/build-driver) — the shared driver that hands each back end its program.
- [The compiler compiles itself](/docs/bootstrap) — the bootstrap chain that runs through this generator.
- The full design document: [JavaScript output theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/javascript-output.md)
- Source: [`compiler/src/Compiler/Generate`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/Generate)
