package;

import haxe.CallStack;
import haxe.io.BufferInput;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.ui.Window;
import peote.view.Buffer;
import peote.view.Color;
import peote.view.Display;
import peote.view.PeoteView;
import peote.view.Program;
import peote.view.element.Elem;

using Lambda;


class Main extends Application {
	static var peoteView:PeoteView;
	static var buffer:Buffer<Elem>;

	public function new() {
		super();
	}

	public function initImGui(done:() -> Void):Void {
		trace("complete!");
		ImGuiDisplay.loadImGui(done);
	}

	
	override function onWindowCreate():Void {
		switch (window.context.type) {
			case WEBGL, OPENGL, OPENGLES:
				try {
					startSample(window);
					initImGui(() -> {
						ImGuiDisplay.ready = true;
					});
				}
				catch (_)
					trace(CallStack.toString(CallStack.exceptionStack()), _);
			default:
				throw("Sorry, only works with OpenGL.");
		}
	}

	override function render(context:RenderContext) {
		switch (context.type) {
			case OPENGL, WEBGL, OPENGLES:
				{
					ImGuiDisplay.render(peoteView, window);
					// peoteView.renderPart();
				}
			default:
		}
	}

	// override function update(deltaTime:Int) {
	// 	ImGuiDisplay.render(peoteView, window);
	// }


	public function startSample(window:Window) {
		peoteView = new PeoteView(window, false);

		buffer = new Buffer<Elem>(4, 4, true);
		var program = new Program(buffer);

		var elem = new Elem(0, 0, 10, 10, 0, 0, 0, 0, Color.ORANGE);
		// buffer.addElement(elem);

		// var guiDisplay = new ImGuiDisplay(0, 0, window.width, window.height);
		// guiDisplay.addProgram(program);
		// peoteView.addDisplay(guiDisplay);

		var display = new Display(0, 0, window.width, window.height);
		display.addProgram(program);
		peoteView.addDisplay(display);
	}
}
