require'dxruby'
require'matrix'
require'./convertAngleUnit'
require'./playerRankManager'

class CheckPoint
	include ConvertAngleUnit
	
	NUM_CHECKPOINT = 4	#チェックポイントとする線分の本数(均等に配置し、ゴールを含む[0])
	GOAL = 0				#ゴールの配列番号
	
	def initialize(x, y, goal_angle, length)
		@x = x						#回転の中心のX座標
		@y = y						#回転の中心のY座標
		@length = length				#線分の長さ
		
		@check_point = Array.new
		
		for num in 0..(NUM_CHECKPOINT - 1) do
			info = Hash[:angle => self.correct_degree(goal_angle - num * (360.0 / NUM_CHECKPOINT)),	#基本の角度
						:x =>0.0,
						:y =>  0.0,
						:rotation => 0.0]														#現在の回転量
			
			info[:x] = @length * Math::cos(self.to_radian(info[:angle]))
			info[:y] = @length * Math::sin(self.to_radian(info[:angle]))
			
			@check_point.push(info)
		end
	end
	
	def update(angle)
		
		for num in 0..(NUM_CHECKPOINT - 1) do
			@check_point[num][:rotation] = self.correct_degree(angle + @check_point[num][:angle])
			@check_point[num][:x] = @length * Math::cos(self.to_radian(@check_point[num][:rotation]))
			@check_point[num][:y] = @length * Math::sin(self.to_radian(@check_point[num][:rotation]))
		end
		
		PlayerRankManager::allUpdate(@x, @y, @check_point)
	end
	
	def draw
		
		_red = 0
		_blue = 224
		
		@check_point.each{|line|
			
			_x = @x + line[:x] * 1.2
			_y = @y + line[:y] * 1.2
			
			Window.draw_line(@x, @y, _x, _y, [255, _red, 0, _blue])
			
			_red += 224 / NUM_CHECKPOINT
			_blue -= 224 / NUM_CHECKPOINT
		}
	end
	
	attr_reader:length
end