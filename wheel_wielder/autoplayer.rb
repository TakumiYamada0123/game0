require'dxruby'
require'./hamster'
require'./player'
require'./autoAction'
require'./newral'

class AutoPlayer < Player
	
	@@allAutoplayer = Array.new
	
	def initialize(hamster)
		
		@@allAutoplayer.push(self)
		
		super(hamster)
		
		@newral = Newral.new(self.object_id)
	end
	
	def self.allUpdate
		if @@allAutoplayer.length > 0
			@@allAutoplayer.each{|autoplayer|
				autoplayer.update()
			}
		end
	end
	
	def update
		@newral.autoAction.actions
	end
	
	def self.finalize
		@@allAutoplayer.clear
	end
	
	attr_reader:hamster
	attr_reader:rank
	attr_reader:newral
end