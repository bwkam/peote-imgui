package;

import imgui.Helpers.*;
import imgui.ImGui;
import lime.graphics.WebGLRenderContext;
import peote.view.*;
import peote.view.PeoteGL.Version;
import peote.view.intern.UniformBufferDisplay;
import peote.view.intern.UniformBufferView;

@:access(peote.view)
class ImGuiDisplay extends Display {
	var init:Bool = false;

	public static var ready:Bool = false;

	static var ImGui_Impl(get, never):Dynamic;

	inline static function get_ImGui_Impl():Dynamic
		return untyped window.ImGui_Impl;

	static var io:ImGuiIO = null;

	public function new(x:Int, y:Int, width:Int, height:Int, color:Color = 0x00000000) {
		super(x, y, width, height, color);
	}

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
	}

	public function endFrame(gl:WebGLRenderContext):Void {
		ImGui.endFrame();

		ImGui.render();

		gl.viewport(0, 0, this.width, this.height);
		gl.clearColor(0.75, 1, 0, 1);
		gl.clear(gl.COLOR_BUFFER_BIT);

		ImGui_Impl.RenderDrawData(ImGui.getDrawData());

		// clay.Clay.app.runtime.skipKeyboardEvents = io.wantCaptureKeyboard;
		// clay.Clay.app.runtime.skipMouseEvents = io.wantCaptureMouse;
	}

	#if peoteview_customdisplay // needs compiler condition to enable override
	override private function renderProgram(peoteView:PeoteView):Void {
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

			endFrame(gl);
		}

		// to also render the other added Programs
		super.renderProgram(peoteView);

		// -----------------------------------------------
		// ----------- ---- SHADERPROGRAM ----------------
		// -----------------------------------------------

		// gl.useProgram(glProgram);

		//  if (Version.isUBO)...

		// -----------------------------------------------
		// ------------------- TEXTURES ------------------
		// -----------------------------------------------
		// ... (better later!)

		// -----------------------------------------------
		// ------------------- UNIFORMS ------------------
		// -----------------------------------------------

		if (Version.isUBO) // ------------- uniform block (ES3) -------------
		{
			gl.bindBufferBase(gl.UNIFORM_BUFFER, UniformBufferView.block, peoteView.uniformBuffer.uniformBuffer);
			gl.bindBufferBase(gl.UNIFORM_BUFFER, UniformBufferDisplay.block, uniformBuffer.uniformBuffer);
		} else // ------------- simple uniforms (ES2) -------------
		{
			// gl.uniform2f (uRESOLUTION, peoteView.width, peoteView.height);
			// gl.uniform2f (uZOOM, peoteView.xz * display.xz, peoteView.yz * display.yz);
			// gl.uniform2f (uOFFSET, (display.x + display.xOffset + peoteView.xOffset) / display.xz,
			// (display.y + display.yOffset + peoteView.yOffset) / display.yz);
		}

		// gl.uniform1f (uTIME, peoteView.time);

		// ---------------------------------------
		// --------------- FLAGS -----------------
		// ---------------------------------------

		// peoteView.setColor(colorEnabled);
		// peoteView.setGLDepth(zIndexEnabled);
		// peoteView.setGLAlpha(alphaEnabled);
		// peoteView.setMask(mask, clearMask);

		// --------------------------------------------------
		// -------------  VERTEX BUFFER DATA ----------------
		// --------------------------------------------------

		// use vertex array object or not into binding your shader-attributes
		if (Version.isVAO) {
			// gl.bindVertexArray( ... );
		} else {
			// enable Vertex Attributes
		}

		// draw by instanced array (ES3) or without (ES2)
		if (Version.isINSTANCED) {
			// gl.drawArraysInstanced ( ... );
		} else {
			// gl.drawArrays ( ... );
		}

		// -----------------------------------------------------
		// ---- cleaning up VAO, Buffer and shaderprogram ------
		// -----------------------------------------------------

		if (Version.isVAO) {
			// gl.bindVertexArray(null);
		} else {
			// disable Vertex Attributes
		}

		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.useProgram(null);
	}

	// if Display is rendered into texture this is called instead:
	// override private function renderFramebufferProgram(peoteView:PeoteView):Void {}
	#end
}