package;

import Menu.Menus;
import haxe.CallStack;
import imgui.Helpers.*;
import imgui.ImGui;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.graphics.WebGLRenderContext;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
import peote.view.Buffer;
import peote.view.Color;
import peote.view.Display;
import peote.view.PeoteView;
import peote.view.Program;
import peote.view.element.Elem;
import peote.view.element.ElemFloat;
import peote.view.text.Text;
import peote.view.text.TextProgram;


class Main extends Application {
	var init:Bool = false;
	var ready:Bool = false;
	var peoteView:PeoteView;
	var rendered = false;
	static var ball:Circle;
	static var player:Sprite;
	static var collided:Bool = false;
	static var angle:Float = 20.0;
	static var display:Display;
	static var buffer:Buffer<Sprite>;
	static var score:Int = 0;
	static var textProgram:TextProgram;
	static var text:Text;

	static var playerWidth:Int = 20;
	static var playerHeight:Int = 20;



	static var ImGui_Impl(get, never):Dynamic;
	static var framePending:Bool = false;

	inline static function get_ImGui_Impl():Dynamic
		return untyped window.ImGui_Impl;

	static var io:ImGuiIO = null;

	override function onWindowCreate():Void {
		switch (window.context.type) {
			case WEBGL, OPENGL, OPENGLES:
				try {
					startSample(window);
				}
				catch (_)
					trace(CallStack.toString(CallStack.exceptionStack()), _);
			default:
				throw("Sorry, only works with OpenGL.");
		}
	}
	public function new() {
		super();
		init = false;
	}

	public function startSample(window:Window) {
		peoteView = new PeoteView(window, false);
		peoteView.start();
		renderPeote();
	}

	public function renderPeote() {
		buffer = new Buffer<Sprite>(1, 1, true);

		display = new Display(0, 0, window.width, window.height, Color.BLACK);
		display.hide();
		var program = new Program(buffer);

		Menus.init(peoteView, window, display);

		Circle.init(display);
		ball = new Circle(display.width / 2, display.height / 2, 20, Color.WHITE);
		ball.vx = 100; 
		ball.vy = -100;

		playerWidth = 200;
		playerHeight = 20;
		player = new Sprite((display.width - playerWidth) / 2, display.height - playerHeight, playerWidth, playerHeight, 0, 0, 0, 0, Color.WHITE);
		
		peoteView.addDisplay(display);
		display.addProgram(program);

		textProgram = new TextProgram();
		display.addProgram(textProgram);
		text = new Text(display.width, 20, '$score', {letterWidth: 50, letterHeight: 50});
		text.x = display.width - (text.letterWidth * text.text.length) - 15;
		textProgram.add(text);

		buffer.addElement(player);
	}

	public function initialize(done:() -> Void, canvas:WebGLRenderContext):Void {
		if (preloader.complete) {
			loadImGui(done, canvas);
			init = true;
		}
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
	static function loadImGui(done:() -> Void, canvas:WebGLRenderContext) {
		loadScript('assets/imgui.umd.js', function(_) {
			loadScript('assets/imgui_impl.umd.js', function(_) {
				Reflect.field(untyped window.ImGui, 'default')().then(function() {
					initImGui(done, canvas);
				}, function() {
					trace('Failed to load ImGui bindings');
				});
			});
		});
	}
	static function initImGui(done:() -> Void, canvas:WebGLRenderContext) {
		ImGui.createContext();
		ImGui.styleColorsDark();
		ImGui_Impl.Init(canvas);

		io = ImGui.getIO();

		done();
	}

	public static function newFrame():Void {
		ImGui_Impl.NewFrame(haxe.Timer.stamp() * 1000);
		ImGui.newFrame();

		framePending = true;
	}

	public static function endFrame():Void {
		if (!framePending)
			return;
		framePending = false;

		ImGui.endFrame();
		ImGui.render();

		ImGui_Impl.RenderDrawData(ImGui.getDrawData());

		// clay.Clay.app.runtime.skipKeyboardEvents = io.wantCaptureKeyboard;
		// clay.Clay.app.runtime.skipMouseEvents = io.wantCaptureMouse;
	}

	public override function render(context:RenderContext):Void {
		switch (context.type) {
			case WEBGL, OPENGL, OPENGLES:
				peoteView.render();
				var ctx = peoteView.gl;
				var someFloat = 0.2;
				var bool = false;
				if (ready && peoteView != null && !rendered) {
					renderPeote();
					rendered = true;
				}
				if (!init) {
					initialize(() -> {
						ready = true;
					}, ctx);
				}

				if (ready) {
					newFrame();
					ImGui.begin('Hello');
					ImGui.sliderFloat('Some slider', fromFloat(someFloat), 100, 500);
					ImGui.checkbox("yo", fromBool(bool));

					trace(player.speed);

					player.speed = someFloat;
					ImGui.end();
					endFrame();
				}
			default:
		}
	}


	override function update(dt:Float):Void {
		ball.update(dt);

		// paddle/player update 
		if (player.isMovingRight) player.x += (player.speed * dt);
		if (player.isMovingLeft) player.x -= (player.speed * dt);

		if (player.x <= 0) player.x = display.width;
		else if (player.x >= display.width) player.x = 0; 

		buffer.update();

		// bounce ball on the edges
		if ((ball.x <= ball.radius && ball.vx <= 0 ) || ((ball.x >= display.width - ball.radius) && ball.vx >= 0)) {
			ball.vx = -ball.vx; 
			score += 13;
		}
		else if (ball.y <= ball.radius && ball.vy >= 0) {
			score += 13;
			ball.vy = -ball.vy; 
		}
		
		if (ball.y >= display.height - ball.radius && ball.vy <= 0) {
			resetGame();
		}

		updateText(text, score);

		// collision w/ the paddle
		if((ball.x < player.x + player.w &&
			ball.x + ball.radius > player.x &&
			ball.y < player.y + player.h &&
			ball.y + ball.radius > player.y) && ball.vy <= 0) {
			
			ball.vy *= -1;
		}
	}

	override function onKeyDown(keyCode:KeyCode, modifier:KeyModifier) {
		if (keyCode == KeyCode.RIGHT) {
			player.isMovingRight = true;
		} else if (keyCode == KeyCode.LEFT) {
			player.isMovingLeft = true;
		}
	}

	override function onKeyUp(keyCode:KeyCode, modifier:KeyModifier) {
		if (keyCode == KeyCode.RIGHT) {
			player.isMovingRight = false; 
		} else if (keyCode == KeyCode.LEFT) {
			player.isMovingLeft = false;
		}
	}

	function updateText(text:Text, data:Int) {
		text.text = '$data';
		text.x = display.width - (text.letterWidth * text.text.length) - 15;
		textProgram.update(text, true);
	}

	function resetGame() {
		score = 0;
		updateText(text, score);

		ball.x = (display.width - ball.radius) / 2;
		ball.y = (display.height - ball.radius) - 20;

		player.x = (display.width - playerWidth) / 2;

		buffer.update();
	}

}

