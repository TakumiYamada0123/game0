require'./newral'
require'./hamster'
require'./hamsterState'
require'./wheel'

class AutoAction
	include HamsterState
	
	@@ACTION_NUM = 8 + (Hamster::getNumberOfHamster - 1) * 2
	@@HAMSTER_NUM = Hamster::getNumberOfHamster
	
	ACCEL_INTERVAL = 6
	TACKLE_INTERVAL = 9
	
	def initialize(origin_id)
		@id = origin_id
		@accelInterval = 0
		@tackleInterval = 0
		@act = 0
	end
	
	def actions
		_wheel = ObjectSpace._id2ref(Wheel::getUsingWheel)
		_root = ObjectSpace._id2ref(ObjectSpace._id2ref(@id).autoplayer_id)
		
		#各アクション選択
		case @act
		
		#何もしない
		when 0
		
		#加速
		when 1
			if _root.hamster.state == RUN
				if @accelInterval == 0
					_root.hamster.speed += _root.hamster.acceleration
					@accelInterval = ACCEL_INTERVAL
				else
					@accelInterval -= 1
				end
			end
		
		#タックル系(敵関連)
		when 2..(@@ACTION_NUM - 1)
			#タックル可能な条件
			unless (_root.hamster.state == RUN || (_root.hamster.state == SLIP && _root.hamster.comeBackFlag == true)) && _root.tackleInterval <= 0
				@tackleInterval -= 1
			
				if @tackleInterval <= 0
					@tackleInterval = 0
				end
				return
			end
			
			if @act <= 7
				
				case @act
				
				#wheelの内側へ
				when 2
					_tackleAngle = self.to_degree(Math::atan2((_wheel.x - _root.hamster.x), - (_wheel.y - _root.hamster.y)))
					
				#wheelの内側へ(やや前)
				when 3
					_tackleAngle = self.to_degree(Math::atan2((_wheel.x - _root.hamster.x), - (_wheel.y - _root.hamster.y))) + 30
					
				#wheelの内側へ(やや後ろ)
				when 4
					_tackleAngle = self.to_degree(Math::atan2((_wheel.x - _root.hamster.x), - (_wheel.y - _root.hamster.y))) - 30
					
				#wheelの外側へ
				when 5
					_tackleAngle = self.to_degree(Math::atan2((_root.hamster.x - _wheel.x), - (_root.hamster.y - _wheel.y)))
					
				#wheelの外側へ(やや前)
				when 6
					_tackleAngle = self.to_degree(Math::atan2((_root.hamster.x - _wheel.x), - (_root.hamster.y - _wheel.y))) - 30
					
				#wheelの外側へ(やや後ろ)
				when 7
					_tackleAngle = self.to_degree(Math::atan2((_root.hamster.x - _wheel.x), - (_root.hamster.y - _wheel.y))) + 30
				end
				
			else
				_ref = (@act - 8) / 2
				_act = (@act - 8) % 2
				
				_id_array = Hamster::getAllHamster_id
				
				if _id_array[_ref.to_i] == _root.hamster
					_ref = (_ref != @@HAMSTER_NUM - 1) ? _ref + 1 : _ref - 1
				end
				
				_opnt = ObjectSpace._id2ref(_id_array[_ref.to_i] )
				
				case _act
			
				#対象の敵にタックル
				when 0
					_tackleAngle = self.to_degree(Math::atan2((_opnt.x - _root.hamster.x), - (_opnt.y - _root.hamster.y)))
					
				#対象の敵から逃れる
				when 1
					_tackleAngle = self.to_degree(Math::atan2((_opnt.x - _root.hamster.x), - (_opnt.y - _root.hamster.y)))
				end
			end
			_root.hamster.changeStatus(TACKLE, :angle => _tackleAngle)
			@tackleInterval = TACKLE_INTERVAL
			@accelInterval -= 1
		end
	end
end