require'dxruby'
require'./convertAngleUnit'

class Obstacle
	extend ConvertAngleUnit
	
	ANGLE_THRESHOLD = 0.1				#同角度と判断する閾値
	INNER_CIRCLE_SET_DIST = 1.5		#内円判定時に内側にずらす距離
	
	@@AllObstacle = Array.new()
	@@NumberOfObstacle = 0
	@@drawOn = false
		
	@@visible_collider = Image.new(512, 512, [128, 0, 0, 255])
	
	def initialize(x, y, angle, size, speed, weight, inner = false, **option)
		@x				 = x																				#X座標
		@y				 = y																				#Y座標
		@angle			 = angle																			#進行方向(移動ベクトルの向き)
		@size			 = size * 128.0																#判定の大きさ(円の半径)
		@speed			 = speed																		#フレーム毎の速さ(移動ベクトルの大きさ)
		@weight		 = weight																		#重さ
		@inner			 = inner																			#当たり判定の内向きフラグ
		@elasticity		 = (option[:elasticity] != nil ? option[:elasticity].abs : 0.0)		#反発力
		@immobility	 = (option[:immobility] != nil ? option[:immobility] : false)		#不動フラグ
		@direction		 = (option[:direction] != nil ? option[:direction] : angle)			#向き
		@state			 = (option[:state] != nil ? option[:state] : nil)						#任意の状態(Obstacleを持つ対象の状態)
		@opnt_state	 = nil																				#上記に対応する、衝突時の相手の状態
		@x_new		 = 0.0																			#次フレームのX座標用バッファ
		@y_new		 = 0.0																			#次フレームのY座標用バッファ
		@angle_new	 = 0.0																			#次フレームの進行方向用バッファ
		@speed_new	 = 0.0																			#次フレームのフレーム毎の速さ用バッファ
		@impact		 = 0.0																			#衝突力
		
		@color			 = (@inner ? [64, 0, 255, 0] :  [96, 0, 0, 255])						#色配列
		
		@updateFlag	 = false																			#衝突時の更新指示フラグ
		
		@@AllObstacle.push(self)																	#全Obstacle管理用配列に追加
		@@NumberOfObstacle += 1
	end
	
	#全Obstacleの当たり判定処理
	def self.allObstacleCollision
		
		#1つ以下の場合当たり判定をしない
		if @@NumberOfObstacle > 1
			
			_obstacles_range = Hash.new		#全Obstacle同士の距離の管理用Hash
			
			########################################################################
			#	距離の管理用Hashによる２重ハッシュのイメージ(総ハッシュ数 = Obstacle数 * (Obstacle数 - 1))
			#_obstacles_range = [	obstacle1 => _distance = [	obstacle2 => dist_of_1_to_2,
			#																		obstacle3 => dist_of_1_to_3
			#																		],
			#								obstacle2 => _distance = [	obstacle1 => dist_of_2_to_1,
			#																		obstacle3 => dist_of_2_to_3
			#																		],
			#								obstacle3 => _distance = [	obstacle2 => dist_of_3_to_1,
			#																		obstacle3 => dist_of_3_to_2
			#																		]
			#								]
			########################################################################
			
			#総当たりに互いの距離の算出を行う
			@@AllObstacle.each{|origin|		#処理対象
				
				_distance = Hash.new										#Obstacle毎に距離データバッファとしてHashを作成
				_obstacles_range[origin.object_id] = _distance	#作成したHashをObstacleのIDに紐付けておく
				
				@@AllObstacle.each{|collider|	#衝突対象
					
					#非同一であるかの判定
					if origin.object_id != collider.object_id
						
						#互いの距離の算出
						_obstacles_range[origin.object_id][collider.object_id] = Math::hypot((collider.x - origin.x), (collider.y - origin.y))
					end
				}
				
				#距離を短い順にソート
				_buf_hash = _obstacles_range[origin.object_id].sort{|(k1, v1), (k2, v2)| v1 <=> v2}
				_obstacles_range[origin.object_id] = Hash[_buf_hash]
			}
			
			#登録順に処理対象を決定し、処理対象と衝突対象の当たり判定を"近い衝突対象から"順に行う
			@@AllObstacle.each{|origin|		#処理対象
				_obstacles_range[origin.object_id].each{|collider_id, range|
				
				#次フレームのパラメータ用バッファに現在のデータをコピー
				origin.angle_new = origin.angle
				origin.speed_new = origin.speed
				
				#衝突対象のオブジェクトを取得
				collider = ObjectSpace._id2ref(collider_id)
				
				#当たり判定
				if self.calcCollisionCircle(origin, collider)
					
					#衝突後処理
					origin = self.calcSelfAffectImpact(origin, collider)
					
					#この時点で確定するデータを更新
					origin.x = origin.x_new
					origin.y = origin.y_new
					origin.updateFlag = true
					
					#originが不動でない時、衝突時カラーに変更
					if !origin.immobility
						origin.color = [96, 255, 0, 0]
					end
				else
					origin.x_new = origin.x
					origin.y_new = origin.y
					
					if !origin.updateFlag
						origin.color = (origin.inner ? [64, 0, 255, 0] :  [96, 0, 0, 255])
					end
				end
				}
			}
			#次フレームのパラメータの確定
			@@AllObstacle.each{|origin|		#処理対象
				
				#衝突時更新指示フラグが立っている時
				if origin.updateFlag
					origin.angle = origin.angle_new
					origin.speed = origin.speed_new
				end
			}
		end
		@@NumberOfObstacle
	end
	
	#全Obstacleの描画処理
	def self.allObstacleDraw(wheel_x, wheel_y)
		
		if @@drawOn == false
			return		
		end
		
		#1つ未満の場合描画をしない
		if @@NumberOfObstacle >= 1
			
			@@AllObstacle.each{|_DrawTarget|		#描画対象
				Window.draw_circle_fill(_DrawTarget.x, _DrawTarget.y, _DrawTarget.size, _DrawTarget.color)
				
				if (_DrawTarget.x != wheel_x) && (_DrawTarget.y != wheel_y)
					
					_radius = Math::hypot((_DrawTarget.x - wheel_x), (_DrawTarget.y - wheel_y))		#対象と回転の中心との距離
					Window.draw_circle(wheel_x, wheel_y, _radius, _DrawTarget.color)					#軌道の描画
				end
			}
		end
	end
	
	def self.drawSwitch(switch)
		if switch
			if @@drawOn
				@@drawOn = false
			else
				@@drawOn = true
			end
		end
		@@drawOn
	end
	
	#先に設定した物体の中心を基準とした、衝突対象との接触点の角度を算出します
	def self.calcCollidedAngle(origin_x, origin_y, collider_x, collider_y)
		_collidedAngle = self.to_degree(Math::atan2((collider_x - origin_x), (collider_y - origin_y)))
	end
	
	#円形の当たり判定
	def self.calcCollisionCircle(origin, collider)
		
		if !origin.inner		#originが内向き判定でない時
			
			_distance = Math::hypot((collider.x - origin.x), (collider.y - origin.y))
			
			if !collider.inner	#colliderが内向き判定でない時
				if _distance < (origin.size + collider.size)
					return true
				end
					
			else						#colliderが内向き判定時
				if _distance > (collider.size - origin.size)
					return true
				end
			end
		end
		return false
	end
	
	#衝突時のoriginへの影響の反映をします
	def self.calcSelfAffectImpact(origin, collider)
		#衝突力を計算
		_impact = self.calcImpactInfluence(origin, collider)
		
		if _impact > origin.impact
			
			origin.opnt_state = (collider.state != nil ? collider.state : origin.opnt_state)	#相手の状態を保持
			origin.impact = _impact					#最大値を反映
		end
		
		#座標の補正
		origin.x_new, origin.y_new = self.calcCorrectPosition(origin, collider)
		
		#角度(ベクトル)の反映
		origin.angle_new  = self.calcCorrectAngle(origin, collider)
		
		#速さの反映
		origin.speed_new  = self.calcCorrectSpeed(origin, collider)
		
		#反映後のObstacleを返します
		return origin
	end
	
	#座標の補正
	def self.calcCorrectPosition(origin, collider)
		
		if !origin.immobility	#自身が不動でないかの判定
			
			if collider.immobility	#相手が不動である時
				
				#相手の座標を基準とした自分の座標の角度
				_relative_angle  = self.calcCollidedAngle(collider.x, collider.y, origin.x, origin.y)
				
				if !collider.inner
					#自分と相手の接触時の距離
					_distance = origin.size + collider.size
					
					#座標を確定させ、次フレームの座標として保持する
					origin.x_new = collider.x + _distance * Math::sin(self.to_radian(_relative_angle))
					origin.y_new = collider.y + _distance * Math::cos(self.to_radian(_relative_angle))
				
				else
					#自分と相手の接触時の距離
					_distance = collider.size - origin.size - INNER_CIRCLE_SET_DIST
					
					#座標を確定させ、次フレームの座標として保持する
					origin.x_new = collider.x + _distance * Math::sin(self.to_radian(_relative_angle))
					origin.y_new = collider.y + _distance * Math::cos(self.to_radian(_relative_angle))
				
				end
			else	#相手が不動でない時
				
				#自分と相手の中間の座標を求める
				mid_x = (origin.x + collider.x) / 2
				mid_y = (origin.y + collider.y) / 2
				
				#中間の座標を基準とした自分の座標の角度
				_relative_angle  = self.calcCollidedAngle(mid_x, mid_y, origin.x, origin.y)
				
				#座標を確定させ、次フレームの座標として保持する
				origin.x_new = mid_x + origin.size * Math::sin(self.to_radian(_relative_angle))
				origin.y_new = mid_y + origin.size * Math::cos(self.to_radian(_relative_angle))
			end
		end
		return origin.x_new, origin.y_new
	end
	
	#角度(ベクトル)の反映
	def self.calcCorrectAngle(origin, collider)
		
		if !origin.immobility	#自身が不動でないかの判定
			
			if origin.elasticity + collider.elasticity > 0.0
				
				if !collider.inner	#colliderが内向き判定でない時
					origin.angle_new = self.calcCollidedAngle(collider.x, collider.y, origin.x, origin.y)
				end
			end
		end
		return origin.angle_new
	end
	
	#速さの反映
	def self.calcCorrectSpeed(origin, collider)
		
		if !origin.immobility	#自身が不動でないかの判定
			
			origin.speed_new = origin.speed * (origin.elasticity + collider.elasticity)
		end
		return origin.speed_new
	end
	
	#originに与えられるimpact値を計算します
	def self.calcImpactInfluence(origin, collider)
		#相手のimpact値を計算
		_collider_impact = self.calcImpactForce(collider, origin)
		
		#自身の対impact値を計算
		_origin_impact = self.calcImpactForce(origin, collider)
		
		#差を被impact値とする
		return _difference_impact = _collider_impact - (_origin_impact * 0.5)
	end
	
	#origin側の衝突力を計算します
	def self.calcImpactForce(origin, collider)
		
		_difference_angle = self.calcCollidedAngle(origin.x, origin.y, collider.x, collider.y) - origin.angle
		
		if _difference_angle < -180.0
        		_difference_angle += 360.0
        	elsif _difference_angle > 180.0
        		_difference_angle -= 360.0
        	end
        	
        	if _difference_angle < 0
        		_difference_angle *= -1
        	end
        	
        	return _impact = origin.weight * (origin.speed * Math::cos(self.to_radian(_difference_angle)))
	end
	
	def setParameter(**option)
		#option	:x,  :y, angle, :size, :speed, :direction, :state
		if option[:x] != nil
			@x =  option[:x]
		end
		
		if option[:y] != nil
			@y =  option[:y]
		end
		
		if option[:angle] != nil
			@angle =  option[:angle]
		end
		
		if option[:size] != nil
			@size =  option[:size]
		end
		
		if option[:speed] != nil
			@speed =  option[:speed]
		end
		
		if option[:direction] != nil && (!@immobility)
			@direction =  option[:direction]
		else
			@direction =  @angle
		end
		
		if option[:state] != nil
			@state =  option[:state]
		end
	end
	
	def getParameter(**option)
		#option	:x,  :y, angle, :speed		必ずこの順番で返り値を渡します
		if (option[:x] == nil) && (option[:y] == nil) && (option[:angle] == nil) && (option[:speed] == nil)
			return @x, @y, @angle, @speed
		end
		
		parameter = Array.new()
		
		if option[:x] != nil
			parameter.push(@x)
		end
		
		if option[:y] != nil
			parameter.push(@y)
		end
		
		if option[:angle] != nil
			parameter.push(@angle)
		end
		
		if option[:speed] != nil
			parameter.push(@speed)
		end
		
		return parameter
	end
	
	attr_accessor:x
	attr_accessor:y
	attr_accessor:angle
	attr_reader:size
	attr_accessor:speed
	attr_reader:weight
	attr_reader:inner
	attr_reader:elasticity
	attr_reader:immobility
	attr_reader:direction
	attr_accessor:state
	attr_accessor:opnt_state
	attr_accessor:x_new
	attr_accessor:y_new
	attr_accessor:angle_new
	attr_accessor:speed_new
	attr_accessor:impact
	attr_accessor:color
	attr_accessor:updateFlag
end