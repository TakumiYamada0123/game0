require'dxruby'
require'./obstacle'
require'./goalLine'

class Wheel
	
	SPEED_TO_ANGLE_RATE = 7.5
	NO_AFFECTED_STAIL = 0.99
	ELASTICITY = 1.5
	
	@@usingWheel  = nil
	
	def initialize(x, y, radius, axisRadius)
		@x = x
		@y = y
		@radius = radius * 128
		@size = radius * 2
		@axisRadius = axisRadius
		@angle = 0.0
		@angleAdd = 0.0
		@speed = 0.0
		@speedOld = @speed
		@AffectedRate = 1.0		#wheelのHamsterからの影響の受けやすさ
		@FrictionRate = 1.0		#wheelの摩擦の割合
		
		@image = Image.load('image/wheel.png')                            	# wheel画像読み込み
		
		@goalLine = GoalLine.new(@x, @y, @size)
		
		@obstaclewheel = Obstacle.new(@x,			#当たり判定用オブジェクトの設定
        									@y,
        									0.0,
        									radius,
        									0.0,
        									0.0,
        									true,
        									:elasticity => ELASTICITY,
        									:immobility => true)
        									
		@obstacleAxis = Obstacle.new(@x,			#当たり判定用オブジェクトの設定
        									@y,
        									0.0,
        									axisRadius,
        									0.0,
        									0.0,
        									:immobility => true)
        	@@usingWheel = self.object_id
	end
	
	def self.getUsingWheel
		@@usingWheel
	end
	
	def update(affectSpeed)
		
		if affectSpeed > 0.0
			@speed = affectSpeed * @AffectedRate
		else
			@speed = @speedOld * NO_AFFECTED_STAIL
		end
		
		@angleAdd = @speed * SPEED_TO_ANGLE_RATE
		@angle += @angleAdd
		
		if @angle < 0.0
        		@angle += 360.0
        	elsif @angle > 360.0
        		@angle -= 360.0
       		end
        
        	@goalLine.update(@angle)
        
        	@speedOld = @speed
	end
	
	def draw
		Window.draw_ex(@x - (128 / 2), @y - (128 / 2), @image, :scalex=> @size, :scaley=> @size, :angle=> @angle)		
		@goalLine.draw
	end
	
	attr_reader:x
	attr_reader:y
	attr_reader:radius
	attr_reader:axisRadius
	attr_reader:angle
	attr_reader:speed
	attr_reader:goalLine
	
	attr_accessor:AffectedRate
	attr_accessor:FrictionRate
end