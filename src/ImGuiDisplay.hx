package;

import imgui.Helpers.*;
import imgui.ImGui;
import lime.graphics.WebGLRenderContext;
import peote.view.*;
import peote.view.PeoteGL.Version;
import peote.view.intern.UniformBufferDisplay;
import peote.view.intern.UniformBufferView;

class ImGuiDisplay {
	var init:Bool = false;

	public static var ready:Bool = false;

	static var ImGui_Impl(get, never):Dynamic;

	inline static function get_ImGui_Impl():Dynamic
		return untyped window.ImGui_Impl;

	static var io:ImGuiIO = null;

	static function loadScript(src:String, done:Bool->Void) {
		var didCallDone = false;

		var script = js.Browser.document.createScriptElement();
		script.setAttribute('type', 'text/javascript');
		script.addEventListener('load', function() {
			if (didCallDone)
				return;
			didCallDone = true;
			done(true);
		});
		script.addEventListener('error', function() {
			if (didCallDone)
				return;
			didCallDone = true;
			done(false);
		});
		script.setAttribute('src', src);

		js.Browser.document.head.appendChild(script);
	}

	public static function loadImGui(done:() -> Void) {
		Reflect.field(untyped window.ImGui, 'default')().then(function() {
			initImGui(done);
		}, function() {
			trace('Failed to load ImGui bindings');
		});
	}

	static function initImGui(done:() -> Void) {
		ImGui.createContext();
		ImGui.styleColorsDark();

		ImGui_Impl.Init(null);

		io = ImGui.getIO();

		done();
	}

	public static function newFrame():Void {
		ImGui_Impl.NewFrame(haxe.Timer.stamp() * 1000);
		ImGui.newFrame();
	}

	public static function endFrame():Void {
		ImGui.endFrame();

		ImGui.render();

		ImGui_Impl.RenderDrawData(ImGui.getDrawData());

		// clay.Clay.app.runtime.skipKeyboardEvents = io.wantCaptureKeyboard;
		// clay.Clay.app.runtime.skipMouseEvents = io.wantCaptureMouse;
	}

	public static function render():Void {
		if (ready) {
			var someFloat = 0.2;

			trace("im ready!");
			newFrame();

			ImGui.begin('Hello');

			ImGui.sliderFloat('Some slider', fromFloat(someFloat), 0.0, 1.0);

			if (someFloat == 1.0) {
				ImGui.text('Float value is at MAX (1.0)');
			}

			ImGui.end();

			endFrame();
		}

	}
}