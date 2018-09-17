require'dxruby'
require'./hamster'

class Hamchan < Hamster
	SIZE = 0.5
	WEIGHT = 1
	SPEED = 0.4
	ACCELERATION = 0.05
	STAIL = 0.004
	ELASTICITY = 0.2
	
	@@image = Image.load_tiles('image/hamster.png', Hamster::HAM_ANIM_NUM, 1)       #hamster画像読み込み
	
	def initialize(x, y)
		super(x,
			y,
			SIZE,
			WEIGHT,
			SPEED,
			ACCELERATION,
			STAIL,
			ELASTICITY,
			@@image)
	end
end