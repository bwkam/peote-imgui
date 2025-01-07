package;

import imgui.Helpers.*;
import imgui.ImGui;
import lime.graphics.WebGLRenderContext;
import lime.ui.Window;
import peote.view.PeoteView;

class ImGuiDisplay {
	var init:Bool = false;

	public static var ready:Bool = false;

	static var ImGui_Impl(get, never):Dynamic;

	inline static function get_ImGui_Impl():Dynamic
		return untyped window.ImGui_Impl;

	static var io:ImGuiIO = null;

	static var framePending:Bool = false;


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
		loadScript('assets/imgui.umd.js', function(_) {
			loadScript('assets/imgui_impl.umd.js', function(_) {
				Reflect.field(untyped window.ImGui, 'default')().then(function() {
					initImGui(done);
				}, function() {
					trace('Failed to load ImGui bindings');
				});
			});
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
		framePending = true;
	}

	public static function endFrame(window:Window, peoteView:PeoteView):Void {
		if (!framePending)
			return;
		framePending = false;

		ImGui.endFrame();

		ImGui.render();

		var gl = window.context.webgl;
		var width = window.width;
		var height = window.height;

		ImGui_Impl.RenderDrawData(ImGui.getDrawData());
	}

	public static function render(peoteView:PeoteView, window:Window):Void {
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

			endFrame(window, peoteView);

		}

	}
}