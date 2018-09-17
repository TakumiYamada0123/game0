require'dxruby'
require'./hamster'
require'./hamchan'
require'./kindOfHamster'
require'./controllable'
require'./autoplayer'
require'./wheel'
require'./startPositionDecisioner'
require'./obstacle'
require'./number'

class Game

	BG_SIZE = 128.0         #BGサイズ幅、高さ
	TEXTURE_SIZE_128 = 128.0 #テクスチャサイズ128
	WHEEL_RADIUS_RATE = 1.5
	WHEEL_RADIUS_MAX = 128.0 * WHEEL_RADIUS_RATE
	GOAL_LAPS = 100

	#フォント登録
	@@font = Font.new(16)

	#ウィンドウサイズに合わせたBG用補正
	@@win_w = Window.width().to_f
	@@win_h = Window.height().to_f
	@@bgTimes_w = 1 / BG_SIZE * @@win_w
	@@bgTimes_h = 1 / BG_SIZE * @@win_h

	def initialize
		@wheel = Wheel::new((@@win_w) / 2, (@@win_h) / 2, WHEEL_RADIUS_RATE, 0.1)

		ham1_x, ham1_y = StartPositionDecisioner.startPosion((@@win_w) / 2, (@@win_h) / 2, WHEEL_RADIUS_MAX, 2)
		ham2_x, ham2_y = StartPositionDecisioner.startPosion((@@win_w) / 2, (@@win_h) / 2, WHEEL_RADIUS_MAX)
		StartPositionDecisioner.reset()

		#参加キャラクター作成
		@hamster1 = Hamchan::new(ham1_x, ham1_y)
		@hamster2 = Hamchan::new(ham2_x, ham2_y)
		
		#参加キャラクターに操縦者を与える
		@player = Controllable::new(@hamster1)
		@auto = AutoPlayer::new(@hamster2)
		
		#周回数の表示
		@player_laps = Number.new(Vector[100, 0],
								Vector[35, 50],
								-10,
								Number::MID,
								Number::TOP,
								[255, 255, 255, 128]
								)
		
		#画像ファイル読み込み
		@imageBG         		= Image.load('image/BG.png')	                             	#BG画像読み込み
		@imageAxis       		= Image.load('image/wheelaxis.png')                     	#wheelaxis画像読み込み
		@imageHamster 		= Image.load_tiles('image/hamster.png', Hamster::HAM_ANIM_NUM, 1)       #hamster画像読み込み
		@imageAccelButton	= Image.load('image/accel_button.png')				#accelButton画像読み込み
	end
	
	#更新処理
	def update
		@hamster1.update(@wheel.x, @wheel.y, @wheel.speed, @wheel.radius, @wheel.axisRadius, @wheel.FrictionRate)
      		@hamster2.update(@wheel.x, @wheel.y, @wheel.speed, @wheel.radius, @wheel.axisRadius, @wheel.FrictionRate)
      		@player.update()
      		@affect = Hamster::calcAffectAll()
      		@wheel.update(@affect)
      		@NumObstacle = Obstacle::allObstacleCollision()
      		Hamster::observeCollision()
      		
      		#デバッグ用
      		@wheel.AffectedRate = @player.wheelAffectRateChanger(@wheel.AffectedRate)
      		@wheel.FrictionRate = @player.wheelFrictionRateChanger(@wheel.FrictionRate)
      		@visibleCollider = Obstacle::drawSwitch(@player.colliderSwitch())
	end
	
	#描画処理
	def draw
		Window.draw_scale((@@bgTimes_w - 1.0) / 2 * BG_SIZE ,(@@bgTimes_h - 1.0) / 2 * BG_SIZE, @imageBG, @@bgTimes_w, @@bgTimes_h)
		@wheel.draw()
		Window.draw_scale(@wheel.x - (TEXTURE_SIZE_128 / 2), @wheel.y - (TEXTURE_SIZE_128 / 2), @imageAxis, 0.1, 0.1)
		Window.draw_ex(@hamster1.x - (TEXTURE_SIZE_128 / 2), @hamster1.y - (TEXTURE_SIZE_128 / 2), @imageHamster[@hamster1.animNumber], :scalex=> @hamster1.size, :scaley=> @hamster1.size, :angle=> @hamster1.drawingAngle)
		Window.draw_ex(@hamster2.x - (TEXTURE_SIZE_128 / 2), @hamster2.y - (TEXTURE_SIZE_128 / 2), @imageHamster[@hamster2.animNumber], :scalex=> @hamster2.size, :scaley=> @hamster2.size, :angle=> @hamster2.drawingAngle)
		Window.draw_scale(430, 300, @imageAccelButton, 0.5 * @player.accelButtonSize, 0.5 * @player.accelButtonSize)
		
		@player_laps.draw(@player.rank.laps)		
	end
	
	#終了処理
	def finalize
		
	end
	
	#デバッグ用表示の描画処理
	def drawDebug
		Obstacle::allObstacleDraw(@wheel.x, @wheel.y)
		
		if !@visibleCollider
			Window.draw_font(0, 0, 	"WindowX:" + Window.width().to_s + ",WindowY:" + Window.height().to_s, @@font)
			
			Window.draw_font(0, 16, 	"Wheel" , @@font)
			Window.draw_font(0, 32, 	"    X:" + @wheel.x.to_s, @@font)
			Window.draw_font(0, 48, 	"    Y:" + @wheel.y.to_s, @@font)
			Window.draw_font(0, 64, 	"    Angle:" + @wheel.angle.to_s, @@font)
			Window.draw_font(0, 80, 	"    Radius:" + @wheel.radius.to_s, @@font)
			Window.draw_font(0, 96, 	"    Speed:" + @wheel.speed.to_s, @@font)
			
			Window.draw_font(0, 128, 	"Hamster(Player)", @@font)
			Window.draw_font(0, 144, 	"    X:" + @player.hamster.x.to_s, @@font)
			Window.draw_font(0, 160, 	"    Y:" + @player.hamster.y.to_s, @@font)
			Window.draw_font(0, 176, 	"    Angle:" + @player.hamster.angle.to_s, @@font)
			Window.draw_font(0, 192, 	"    Radius:" + @player.hamster.radius.to_s, @@font)
			Window.draw_font(0, 208, 	"    Speed:" + @player.hamster.speed.to_s, @@font)
			Window.draw_font(0, 224, 	"    AnimNumber:" + @player.hamster.animNumber.to_s, @@font)
			Window.draw_font(0, 240, 	"    AnimInterval:" + @player.hamster.interval.to_s, @@font)
			Window.draw_font(0, 256, 	"    IntervalCnt:" + @player.hamster.intervalCnt.to_s, @@font)
			Window.draw_font(0, 272, 	"    FrameCnt:" + @player.hamster.frameCnt.to_s, @@font)
			Window.draw_font(0, 288, 	"    Influence:" + @player.hamster.influence.to_s, @@font)
			Window.draw_font(0, 304,	"    State:" + @player.hamster.stateName(), @@font)
			Window.draw_font(0, 320,	"AffectSpeedAll:" + @affect.to_s, @@font)
			
			Window.draw_font(0, 352,	"WheelAffectedRate:" + @wheel.AffectedRate.to_s, @@font)
			Window.draw_font(0, 368,	"WheelFrictionRate:" + @wheel.FrictionRate.to_s, @@font)
			
			Window.draw_font(0, 400,	"VisibleCollider:" + (@visibleCollider ? "TRUE": "FALSE"), @@font)
			
			Window.draw_font(0, 432,	"ComeBackSlip:" + (@player.hamster.comeBackFlag != nil ? (@hamster1.comeBackFlag ? "TRUE": "FALSE") : "NIL"), @@font)
			
		else
			@wheel.goalLine.check.draw()
			
			Window.draw_font(0, 0, 	"AllObstacles:" + @NumObstacle.to_s, @@font)
			
			Window.draw_font(0, 16, 	"Player1" , @@font)
			Window.draw_font(0, 32, 	"    Laps:" + @player.rank.laps.to_s, @@font)
			Window.draw_font(0, 48, 	"    Rank:" + @player.rank.rank.to_s, @@font)
			Window.draw_font(0, 64, 	"  PassFlag:", @@font)
			Window.draw_font(0, 80, 	"      [0](goal):" + @player.rank.pass_flag[0].to_s, @@font)
			Window.draw_font(0, 96, 	"      [1]         :" + @player.rank.pass_flag[1].to_s, @@font)
			Window.draw_font(0, 112, 	"      [2]         :" + @player.rank.pass_flag[2].to_s, @@font)
			Window.draw_font(0, 128, 	"      [3]         :" + @player.rank.pass_flag[3].to_s, @@font)
			Window.draw_font(0, 144, 	"      near      :" + @player.rank.near_point.to_s, @@font)
			
			Window.draw_font(0, 176, 	"Player2(Auto)" , @@font)
			Window.draw_font(0, 192, 	"    Laps:" + @auto.rank.laps.to_s, @@font)
			Window.draw_font(0, 208, 	"    Rank:" + @auto.rank.rank.to_s, @@font)
			Window.draw_font(0, 224, 	"  PassFlag:", @@font)
			Window.draw_font(0, 240, 	"      [0](goal):" + @auto.rank.pass_flag[0].to_s, @@font)
			Window.draw_font(0, 256, 	"      [1]         :" + @auto.rank.pass_flag[1].to_s, @@font)
			Window.draw_font(0, 272, 	"      [2]         :" + @auto.rank.pass_flag[2].to_s, @@font)
			Window.draw_font(0, 288, 	"      [3]         :" + @auto.rank.pass_flag[3].to_s, @@font)
			Window.draw_font(0, 304, 	"      near      :" + @auto.rank.near_point.to_s, @@font)
			Window.draw_font(0, 320, 	"      to_Goal:" + @auto.rank.angle2Goal.to_s, @@font)
		end
			
	end
end