require'dxruby'
require'./hamster'
require'./actionOperation'
require'./playerRankManager'
require'./player'

class Controllable < Player
	include ActionOperation
	
	def initialize(hamster)
		
		@accelButtonSize = ACCEL_BUTTON_NEWTRAL_SIZE
		@accelInterval = 0
		@returnTime = 0
		@tackleInterval = 0
		@flickTouchingLimit = 0
		self.initFlickInfo()
		@changeRate_A = 10
		@changeRate_F = 10
		
		super(hamster)
	end
	
	def update
		self.Accel()
		self.Tackle()
	end
	
	attr_reader:hamster
	attr_reader:rank
end