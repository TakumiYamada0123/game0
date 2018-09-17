require'dxruby'
require'./hamster'

module HamsterState
	NONE		 = 0
	RUN		 = 1
	TACKLE		 = 2
	SLIP			 = 3
	
	STATUS_TEXT = {
		NONE => "NONE",
		RUN => "RUN",
		TACKLE => "TACKLE",
		SLIP => "SLIP"
	}
	
	def stateName
		STATUS_TEXT[self.state]
	end
end