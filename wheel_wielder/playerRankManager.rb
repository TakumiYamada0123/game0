require'dxruby'
require'./checkPoint'
require'./convertAngleUnit'
require'./supportMath'
require'./wheel'

###########################################################################################
#		外積等は判定が逆(もしかして座標系のせい？)
###########################################################################################

class PlayerRankManager
	include ConvertAngleUnit
	include SupportMath
	
	ANGLE_THRESHOLD = 0.1				#同角度と判断する閾値
	
	@@allPlayerRankManager = Array.new
	
	def initialize(origin_id)
		@pass_flag = Array.new(CheckPoint::NUM_CHECKPOINT, false)	#チェックポイントの通過フラグ
		@angle2Goal = 0.0											#ゴールラインとの角度差
		@near_point = nil											#最も近い次のチェックポイント
		@laps = 0												#周回数
		@rank = 1												#順位
		@id = origin_id											#対象プレイヤーの主要オブジェクトのID
		
		@@allPlayerRankManager.push(self)
	end
	
	def self.allUpdate(wheel_x, wheel_y, checkpoint_array)
		
		@@allPlayerRankManager.each{|prm|
			prm.update(wheel_x, wheel_y, checkpoint_array)
		}
		self.calcRank()
	end
	
	def update(wheel_x, wheel_y, checkpoint_array)
		
		self.calcAngle(checkpoint_array[CheckPoint::GOAL][:x],
					checkpoint_array[CheckPoint::GOAL][:y],
					wheel_x,
					wheel_y)
		
		self.checkPassFlag(checkpoint_array,
						wheel_x,
						wheel_y)
	end
	
	def calcAngle(goal_x, goal_y, wheel_x, wheel_y)
		
		_x = ObjectSpace._id2ref(@id).hamster.x - wheel_x
		_y = ObjectSpace._id2ref(@id).hamster.y - wheel_y
		
		_angle = self.to_degree(self.Dot2Radian(_x, _y, goal_x, goal_y))
		
		#ゴールより左側にいる時
		if !(self.Cross2LorR(goal_x, goal_y, _x, _y))
			_angle = 360.0 - _angle
		end
		
		@angle2Goal = _angle
	end
	
	def checkPassFlag(checkpoint_array, wheel_x, wheel_y)
		
		_x = ObjectSpace._id2ref(@id).hamster.x - wheel_x
		_y = ObjectSpace._id2ref(@id).hamster.y - wheel_y
		
		#最も近い次のチェックポイントを設定していない時
		if @near_point == nil
			
			_near_angle = nil		#最も近い角度
			
			for num in 0..(CheckPoint::NUM_CHECKPOINT - 1) do
				
				_CPx = checkpoint_array[num][:x]
				_CPy = checkpoint_array[num][:y]
				
				#内積による左右90°以内である判定
				if (self.Dot(_x, _y, _CPx, _CPy) > 0)
					
					#外積による左右判定(チェックポイントベクトルを越えている判定)
					if !(self.Cross2LorR(_CPx, _CPy, _x, _y))
						
						next		#このチェックポイントの判定をパスする
					end
					
					#角度の算出
					_angle =  self.to_degree(self.Dot2Radian(_CPx, _CPy, _x, _y))
					
					#最小角度が未設定のとき
					if _near_angle == nil
						_near_angle = _angle
						
						#この時のチェックポイントを保持
						@near_point = num
						
					#設定済のとき
					else
						#以前のチェックポイントより近いかどうかの判定
						if _angle < _near_angle
							
							#最も近い角度として保持する
							_near_angle = _angle
							
							#この時のチェックポイントを保持
							@near_point = num
						end
					end
				end
			end
			
		#最も近い次のチェックポイントが設定されている時
		else
			
			#通過判定するチェックポイント
			_checkpoint = checkpoint_array[@near_point]
			 
			_CPx = _checkpoint[:x]
			_CPy = _checkpoint[:y]
			
			#外積による左右判定(チェックポイントベクトルを越えている判定)
			if !(self.Cross2LorR(_CPx, _CPy, _x, _y))
				
				#対象のチェックポイントが通過済のとき
				if @pass_flag[@near_point]
					
					@near_point = (@near_point + 1 == CheckPoint::NUM_CHECKPOINT) ? 0
													: @near_point + 1
					
					return	#関数を抜ける
				end
				
				@pass_flag[@near_point] = true
				
				if @near_point == 0
					
					_num_pass = 0	#通過済フラグの数
					
					#「0」を除く全ての通過フラグを参照する
					for num in 1..(CheckPoint::NUM_CHECKPOINT - 1) do
						
						#通過済のとき
						if @pass_flag[num]
							
							_num_pass += 1	#通過済フラグをカウントする
						end
					end
					
					#「0」を除く全ての通過フラグが「true」のとき
					if _num_pass == CheckPoint::NUM_CHECKPOINT - 1
						
						@laps += 1	#周回数を加算する
					end
						
					#全フラグを落とす
					for num in 0..(CheckPoint::NUM_CHECKPOINT - 1) do
						
						@pass_flag[num] = false
					end
				end
				
				@near_point = nil
			end
		end
	end
	
	def self.calcRank
		
		#angle2Goalでソート(小さい順)
		@@allPlayerRankManager.sort!{|ps1, ps2| ps1.angle2Goal <=> ps2.angle2Goal}
		
		#Lapsでソート(大きい順)
		@@allPlayerRankManager.sort!{|ps1, ps2| ps2.laps <=> ps1.laps}
				
		_number = 1							#順位付け用数字
		
		#順位を振る
		@@allPlayerRankManager.each{|prm|
			
			prm.rank = _number				#順位確定
			_number += 1						#次の順位へ
		}
	end
	
	attr_reader:angle2Goal
	attr_reader:near_point
	attr_reader:pass_flag
	attr_reader:laps
	attr_accessor:rank
end