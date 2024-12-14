package;

import haxe.CallStack;
import haxe.Timer;
import imgui.Helpers.*;
import imgui.ImGui.ImGuiIO;
import imgui.ImGui;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.graphics.WebGLRenderContext;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
import peote.ui.event.PointerEvent;
import peote.ui.interactive.UIElement;
import peote.view.Buffer;
import peote.view.Color;
import peote.view.Display;
import peote.view.PeoteView;
import peote.view.Program;
import peote.view.element.Elem;
import peote.view.text.Text;
import peote.view.text.TextProgram;

using Lambda;

class Main extends Application {
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

	public function startSample(window:Window) {
		var peoteView = new PeoteView(window);

		var buffer:Buffer<Elem> = new Buffer<Elem>(4, 4, true);
		var program = new Program(buffer);

		var guiDisplay = new ImGuiDisplay(0, 0, window.width, window.height);
		guiDisplay.addProgram(program);
		peoteView.addDisplay(guiDisplay);
	}
}
