require'dxruby'
require'./controllable'
require'./hamster'
require'./hamsterState'
require'./convertAngleUnit'

module ActionOperation
	include HamsterState
	include ConvertAngleUnit
	
	ACCEL_BUTTON_NEWTRAL_SIZE = 1.0
	ACCEL_BUTTON_PUSHED_SIZE = 0.9
	ACCEL_BUTTON_RETURN_TIME = 12
	ACCEL_INTERVAL = 6
	
	FLICK_TIME_LIMIT = 24
	FLICK_DISTANCE_THRESHOLD = 25
	TACKLE_INTERVAL = 9
	
	def Accel
		if Input::key_down?(K_SPACE) && @hamster.state == RUN
			if @accelInterval == 0
				@hamster.speed += @hamster.acceleration
				@accelInterval = ACCEL_INTERVAL
				@accelButtonSize = ACCEL_BUTTON_PUSHED_SIZE
				@returnTime = ACCEL_BUTTON_RETURN_TIME
			else
				@accelInterval -= 1
			end
		end
		
		if @returnTime > 0
			@accelButtonSize = ACCEL_BUTTON_PUSHED_SIZE + ((ACCEL_BUTTON_NEWTRAL_SIZE - ACCEL_BUTTON_PUSHED_SIZE) / ACCEL_BUTTON_RETURN_TIME)  * (ACCEL_BUTTON_RETURN_TIME - @returnTime)
			@returnTime -= 1
		else
			@accelButtonSize = ACCEL_BUTTON_NEWTRAL_SIZE
		end
	end
	
	def Tackle
		
		unless (@hamster.state == RUN || (@hamster.state == SLIP && @hamster.comeBackFlag == true)) &&
			@tackleInterval <= 0
			
			@tackleInterval -= 1
			
			if @tackleInterval <= 0
				@tackleInterval = 0
			end
			return
		end
		
		if Input::mouse_push?(M_LBUTTON)
			@flickStart_x = Input::mouse_x()
			@flickStart_y = Input::mouse_y()
			@flickTouchingLimit = FLICK_TIME_LIMIT
			
		elsif Input::mouse_down?(M_LBUTTON)
			@flickTouchingLimit -= 1
			
		elsif (Input::mouse_release?(M_LBUTTON) && @flickTouchingLimit > 0) ||
			(Input::mouse_down?(M_LBUTTON) && @flickTouchingLimit <= 0)
			@flickEnd_x = Input::mouse_x()
			@flickEnd_y = Input::mouse_y()
			@flickTouchingLimit = 0
			
			@flickDistance = Math::hypot((@flickEnd_x - @flickStart_x), - (@flickEnd_y - @flickStart_y))
			
			if @flickDistance >= FLICK_DISTANCE_THRESHOLD
				_tackleAngle = self.to_degree(Math::atan2((@flickEnd_x - @flickStart_x), - (@flickEnd_y - @flickStart_y)))
				
				@hamster.changeStatus(TACKLE, :angle => _tackleAngle)
				@tackleInterval = TACKLE_INTERVAL
				self.initFlickInfo()
			end
		else
			@flickTouchingLimit = 0
		end
	end
	
	def initFlickInfo
		@flickStart_x = 0
		@flickStart_y = 0
		@flickEnd_x = 0
		@flickEnd_y = 0
	end
	
	def wheelAffectRateChanger(rate)
		
		_rate = rate
		
		if Input::key_push?(K_UP)
			@changeRate_A += 1
		elsif Input::key_push?(K_DOWN)
			@changeRate_A -= 1
		end
		
		_rate = @changeRate_A * 0.1
		
		if _rate < 0.1
			_rate = 0.0
		elsif _rate > 1.0
			_rate = 1.0
		end
		@changeRate_A = _rate * 10
		_rate
	end
	
	def wheelFrictionRateChanger(rate)
		
		_rate = rate
		
		if Input::key_push?(K_RIGHT)
			@changeRate_F += 1
		elsif Input::key_push?(K_LEFT)
			@changeRate_F -= 1
		end
		
		_rate = @changeRate_F * 0.1
		
		if _rate < 0.1
			_rate = 0.0
		elsif _rate > 1.0
			_rate = 1.0
		end
		@changeRate_F = _rate * 10
		_rate
	end
	
	def colliderSwitch
		if Input::key_push?(K_C)
			return true
		end
		return false
	end
	
	attr_reader:accelButtonSize
end