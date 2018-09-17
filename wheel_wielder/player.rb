require'dxruby'
require'./hamster'

class Player
	
	@@allPlayerArray = Array.new
	@@allPlayerNum = 0
	
	def initialize(hamster)
		
		@hamster = hamster							#Playerが管理するhamster
		
		@rank = PlayerRankManager.new(self.object_id)	#Playerの順位管理用オブジェクト
		
		@@allPlayerArray.push(self.object_id)				#全てのPlayerの配列に追加
		@@allPlayerNum += 1							#全てのPlayerの数に加算
	end
	
	def self.getAllPlayer
		@@allPlayerArray
	end
end