require'dxruby'
require'./checkPoint'

class GoalLine
	
	def initialize(x, y, size)
		@x = x
		@y = y
		@size = size
		@image = Image.load('image/goal_line.png')		#GoalLine画像読み込み
		@angle = 0.0
		
		@check = CheckPoint.new(@x, @y, @angle, @size * 0.5 * 128)
	end
	
	def update(angle)
		@angle = angle
		@check.update(@angle)
	end
	
	def draw
		Window.draw_ex(@x - (128 / 2), @y - (128 / 2), @image, :scalex=> @size, :scaley=> @size, :angle=> @angle)
	end
	
	attr_reader:check
end