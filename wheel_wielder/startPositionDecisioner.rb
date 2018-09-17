require'dxruby'

class StartPositionDecisioner
	
	@@DivisionNum = 1
	@@Number = 0
	
	def self.startPosion(wheel_x, wheel_y, wheelRadius, division_num = nil)
		
		@@DivisionNum += (division_num != nil ? division_num : 0)
		
		_between = wheelRadius / @@DivisionNum
		
		@@Number += 1
		
		return wheel_x + (@@Number * _between), wheel_y
	end
	
	def self.reset
		@@DivisionNum = 1
		@@Number = 0
	end
	
end