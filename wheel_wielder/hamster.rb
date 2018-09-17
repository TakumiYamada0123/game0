require'dxruby'
require'./game'
require'./convertAngleUnit'
require'./animationModule'
require'./hamsterState'
require'./obstacle'

class Hamster
	include ConvertAngleUnit
	include Animation
	include HamsterState
	
        public
        		HAM_ANIM_NUM = 4							#アニメーション枚数
        		HAM_SPEED_STD = 1.0						#速さの基準
        		HAM_SPEED_MAX = 0.8						#速さの上限
        		HAM_WEIGHT_MAX = 2						#重さの上限
        		HAM_RUN_SPEED_RATE = 7.5					#走り時の速さ倍率
        		HAM_TACKLE_SPEED_RATE = 10.0				#タックルの速さの倍率
        		HAM_TACKLE_FRAME = 12						#タックル終了までのフレーム
        		HAM_ANGLE_CORRECTING_FRAME = 9			#角度補正完了までのフレーム
        		HAM_WEIGHT_TO_FRICTION_RATE = 0.075		#重さに比例する摩擦の割合
        		HAM_COLLISION_SIZE_RATE = 0.4				#大きさに対する当たり判定の大きさ
        		HAM_SPEED_TO_SLIP_THRESHOLD = 1.5		#転倒条件を満たすwheelとの速さの差
        		HAM_SLIP_SPEED_RATE = 15.7					#転倒時の速さ倍率
        		
        		#subState
        		RUN_		= 0
        		TACKLE_	= 0.25
        		SLIP_FLY	= 0.5
        		SLIP_DOWN	= 0.75
        		SLIP_RISE	= 1.0
        		
        		@@AllHamster = Array.new
        		@@weightAll = 0.0					#hamster全ての重さの合計
        		@@affectSpeedAll = 0.0			#hamster全てのwheelへの速さの影響の平均
        		
        		def initialize(x,
        						y,
        						size,
        						weight,
        						speed,
        						acceleration,
        						stail,
        						elasticity,
        						image,
        						anti_frictionless = false)
        		@x = x											#X座標
                	@y = y											#Y座標
                	@size = size										#大きさ(倍率　※元の大きさは画像のPixel数(128))
                	@weight = weight									#重さ
                	@acceleration = acceleration						#加速度
                	@stail = stail										#失速速度
                	@speedMax = HAM_SPEED_MAX					#速さの上限	
        		@state = RUN									#状態
        		@subState = RUN
        		@image = image									#画像オブジェクト
        			self.setSpeed(speed)							#速さ
        			@initSpeed = speed							#基本の速さ
        			@anti_frictionless = anti_frictionless		#対無摩擦状態フラグ
        			self.infomationAnim(@interval, 0)			#アニメーションインターバル
        			@angle = 0.0										#初期角度
        			@angleOld = @angle							#前フレームの角度
        			@influence = 1.0									#wheelの速さに対する被影響値
        			@tackleAngle = 0.0								#タックル時の進行角度
        			@tackleBeforeAngle = 0.0					#タックル直前のhamsterの角度
        			@tackleCnt = 0									#タックル終了までのフレーム用カウンタ
        			@correctFrame = 0								#タックル後の角度補正の完了までのフレーム
        			@differenceAngle = nil						#タックル後の角度補正の差分の角度
        			@drawingAngle = 0								#描画するhamsterの角度
        			@knockedAngle = 0.0							#転倒時の突き飛ばされた角度
        			@knockedSpeed = 0.0						#転倒時の突き飛ばされた速さ
        			@comeBackFlag = nil							#転倒状態から復帰可能であることを示すフラグ
        			
        			@@AllHamster.push(self)					#全hamsterの管理用配列に追加
        			@@weightAll += @weight					#全hamsterの重さの合計に加算
        			
        			@obstacle = Obstacle.new(@x,			#当たり判定用オブジェクトの設定
        												@y,
        												@angle,
        												size * HAM_COLLISION_SIZE_RATE,
        												@speed,
        												@weight,
        												:elasticity => elasticity,
        												:direction => @angleOld,
        												:state => @state)
        		end
        		
			def setSpeed(speed)
				if speed < @speedMax								#上限を超えていない時
	   				@speed = speed
				else															#上限を超えている時
					@speed = @speedMax
				end
	   			
	   			if @speed > 0 && @speed <= 1
	   				@interval = HAM_SPEED_STD / @speed	#アニメーションの間隔設定
	   				
	   			elsif @speed <= 0
	   				@interval = 61
	   				
	   			elsif @speed > 1
	   				@interval = 1
	   			end
			end
			
			def self.allUpdate(wheel_x, wheel_y, wheelSpeed, wheelRadius, axisRadius, wheelFriction)
				@@AllHamster.each{|ham|
					ham.update(wheel_x, wheel_y, wheelSpeed, wheelRadius, axisRadius, wheelFriction)
				}
			end
        		
        		def update(wheel_x, wheel_y, wheelSpeed, wheelRadius, axisRadius, wheelFriction)
        			
        			#当たり判定用オブジェクトからの更新要請によるパラメータ補正
        			if @obstacle.updateFlag
        				
        				case @state
        				when RUN
        					_speed_buf_id = @tackleSpeed.object_id
        				when TACKLE
        					_speed_buf_id = @tackleSpeed.object_id
        				when SLIP
        					_speed_buf_id = @relativeSpeed.object_id
        				end
        				
        				_speed = ObjectSpace._id2ref(_speed_buf_id)
        				
        				@x, @y, @angle, _speed = @obstacle.getParameter()
        				
        				@obstacle.updateFlag = false
        			end
        			
        			self.calcStail()										#失速と上限の処理
        			
        			case @state
        			
        			when RUN
        				self.updateRun(wheel_x, wheel_y, wheelSpeed, wheelRadius, wheelFriction)
        				
        				if @relativeSpeed < -HAM_SPEED_TO_SLIP_THRESHOLD
        					self.changeStatus(SLIP, :speed => 0.0, :angle => 0.0)
        				end
        				
        			when TACKLE
        				self.updateTackle()
        				
        			when SLIP
        				self.updateSlip(wheel_x, wheel_y, wheelSpeed, wheelRadius, wheelFriction)
        			end
        			
        			self.calcRadius(wheel_x, wheel_y)												#wheelの中心からの距離を算出
        			self.calcRadiusRate(wheelRadius)												#wheelの半径に対するhamsterの中心からの距離の割合
        			self.calcDrawAngle()															#描画用の角度を計算
        			
        			#当たり判定用オブジェクトの更新###############################        			
        			case @state
        			when RUN
        				_speed = @relativeSpeed
        				
        			when TACKLE
        				_speed = @tackleSpeed
        				
        			when SLIP
        				_speed = @relativeSpeed
        			end
        			
        			@obstacle.setParameter(:x => @x,
        								:y => @y,
        								:angle => @angle,
        								:speed => _speed,
        								:direction => @angleOld,
        								:state => @state)
        			#######################################################
        		end
        		
        		def updateRun(wheel_x, wheel_y, wheelSpeed, wheelRadius, wheelFriction)
        			
        			_wheelFriction = wheelFriction
        			
        			#対無摩擦状態フラグによる補正
        			if @anti_frictionless
        				_wheelFriction = 1.0
        			end
        			
        			#相対移動距離の算出
        			@relativeSpeed = (@speed - (wheelSpeed * @influence * @@AllHamster.length)) * HAM_RUN_SPEED_RATE
        			
        			if @relativeSpeed >= 0
        				@relativeSpeed *= _wheelFriction
        			end
        			
        			@x += @relativeSpeed * Math::sin(self.to_radian(@angle))				#X座標の更新
        			@y -= @relativeSpeed * Math::cos(self.to_radian(@angle))			#Y座標の更新
        			
        			self.calcAngle(wheel_x, wheel_y)									#角度を算出して確定
        			self.calcAffect(wheelRadius, _wheelFriction)						#速さの影響値を算出
        			self.calcAnim()												#アニメーション
        			@angleOld = @angle											#前フレームの角度を更新
        			@subState = RUN_
        		end
        		
        		def updateTackle
        			
        			@tackleSpeed = @speed * HAM_TACKLE_SPEED_RATE	#タックル時の速さ
        			@x += @tackleSpeed * Math::sin(self.to_radian(@angle))		#X座標の更新
        			@y -= @tackleSpeed * Math::cos(self.to_radian(@angle))		#Y座標の更新
        			
        			@affectSpeed = 0.0
        			
        			if @tackleCnt >= 0
        				@tackleCnt -= 1
        			else
        				@tackleCnt = 0
        				self.changeStatus(RUN)
        				@correctFrame = HAM_ANGLE_CORRECTING_FRAME + 1
        			end
        			@subState = TACKLE_
        		end
        		
        		def updateSlip(wheel_x, wheel_y, wheelSpeed, wheelRadius, wheelFriction)
        			
        			_wheelFriction = wheelFriction
        			
        			#対無摩擦状態フラグによる補正
        			if @anti_frictionless
        				_wheelFriction = 1.0
        			end
        			
        			#相対移動距離の算出
        			if @knockedSpeed > 0.0						#突き飛ばされ中
        				@relativeSpeed = @knockedSpeed
        				_angle = @knockedAngle
        				@speed = 0.0
        			else													#着地後転倒中
        				_angle = @angle
        				@speed = @relativeSpeed.abs * (1.0 / HAM_SLIP_SPEED_RATE)
        			end
        			
        			#座標の更新
        			@x += @relativeSpeed * Math::sin(self.to_radian(_angle))
        			@y -= @relativeSpeed * Math::cos(self.to_radian(_angle))
        			
        			#突き飛ばされ中
        			if @knockedSpeed > 0.0
        				@knockedSpeed -= @weight * HAM_WEIGHT_TO_FRICTION_RATE
        				@comeBackFlag = false
        				
        				if @knockedSpeed <= 0.0
        					@relativeSpeed = -wheelSpeed * (1.0 / @influence) * @@AllHamster.length * HAM_SLIP_SPEED_RATE
        				end
        				@subState = SLIP_FLY
        			#着地後
        			else
        				#転倒中
        				if @knockedSpeed > (@speed * -1.0) && @knockedSpeed <= 0.0
        					@knockedSpeed -= @weight * HAM_WEIGHT_TO_FRICTION_RATE * (1.0 / HAM_SLIP_SPEED_RATE) * 1.5
        					@relativeSpeed = -wheelSpeed * (1.0 / @influence) * @@AllHamster.length * HAM_SLIP_SPEED_RATE
        					@comeBackFlag = true
        					@subState = SLIP_DOWN
        				#立て直し中
        				else
        					#立て直し未完了
        					if @relativeSpeed < 0.0
        						@relativeSpeed += @weight * HAM_WEIGHT_TO_FRICTION_RATE
        						@comeBackFlag = true
        						
        					#立て直し完了時
        					else
        						_speed = wheelSpeed * @influence * @@AllHamster.length
        						self.changeStatus(RUN, :speed => _speed)
        						@knockedSpeed = 0.0
        						@relativeSpeed = 0.0
        					end
        					@subState = SLIP_RISE
        				end
        			end
        			
        			@affectSpeed = 0.0
        			self.calcAngle(wheel_x, wheel_y)													#角度を算出して確定
        			@angleOld = @angle																	#前フレームの角度を更新
        		end
        		
        		def calcRadius(wheel_x, wheel_y)
                	@radius = Math::hypot((@x - wheel_x), (@y - wheel_y))  #wheel中心からの距離
        		end
        		
        		def calcAngle(wheel_x, wheel_y)
                	@angle = self.to_degree(Math::atan2((@y - wheel_y), (@x - wheel_x)))			#Hamsterの角度
        			if @angle < 0.0
        				@angle += 360.0
        			elsif @angle > 360.0
        				@angle -= 360.0
        			end
        		end
        		
        		def calcAnim
        			self.numberCalcAnim(HAM_ANIM_NUM)
        		end
        		
        		def calcStail
        			#基準の速さより大きいときのみ処理
        			if @speed > @initSpeed
        				@speed -= @stail
        				if @speed < @initSpeed
        					@speed = @initSpeed
        				end
        			end
        			self.setSpeed(@speed)
        		end
        		
        		def calcWeightRate
        			_weightRate = @weight / @@weightAll
        		end
        		
        		def calcRadiusRate(wheelRadius)
        			@influence = @radius / wheelRadius
        		end
        		
        		def calcAffect(wheelRadius, wheelFriction)
        			_weightRate = self.calcWeightRate()
                	@affectSpeed = wheelFriction * @speed * _weightRate * (1.0 / @influence)			#Hamsterがwheelに影響を与える速さ
                	@@affectSpeedAll += @affectSpeed
                	@affectSpeed
        		end
        		
        		def self.calcAffectAll
        			_affectAll = @@affectSpeedAll / @@AllHamster.length
        			@@affectSpeedAll = 0
        			_affectAll
        		end
        		
        		def changeStatus(state, **option)
        			
        			case state
        			
        			when RUN
        				if option[:speed] != nil
        					@speed = (option[:speed] > @initSpeed ? option[:speed] : @initSpeed)
        					@comeBackFlag = nil
        				end
        				
        			when TACKLE
        				if option[:angle] != nil
        					
        					@angle = option[:angle]
        					if @angle < 0.0
							@angle += 360
        					elsif @angle > 360.0
        						@angle -= 360.0
						end
        					@tackleCnt = HAM_TACKLE_FRAME
        					@tackleBeforeAngle = @angleOld
        					@comeBackFlag = nil
        				end
        				
        			when SLIP
        				if option[:angle] != nil && option[:speed] != nil
        					@knockedAngle = @angle - option[:angle]
        					if @knockedAngle < 0.0
							@knockedAngle += 360
        					elsif @knockedAngle > 360.0
        						@knockedAngle -= 360.0
						end
						@knockedSpeed = option[:speed]
						@speed = 0.0
        				end
        			end
        			
        			@state = state
        		end
        		
        		def calcDrawAngle
        			
        			if @correctFrame > 0 && @state != TACKLE
        				
        				@differenceAngle = @tackleBeforeAngle - @angle
        					
        				if @differenceAngle < -180.0
        					@differenceAngle += 360.0
        				elsif @differenceAngle > 180.0
        					@differenceAngle -= 360.0
        				end
        				@differenceAngle /= HAM_ANGLE_CORRECTING_FRAME
        				
        				@drawingAngle = @angle + (@differenceAngle * @correctFrame)
        				
        				@correctFrame -= 1
        				
        				if @correctFrame <= 0
        					@correctFrame = 0
        					@tackleBeforeAngle = 0.0
        					@differenceAngle = nil
        				end
        			else
        				@drawingAngle = @angleOld
        			end
        		end
        		
        		def self.observeCollision()
        			@@AllHamster.each{|hamster|
        				
        				#衝突相手が存在する時
        				if hamster.obstacle.opnt_state != nil
        					
        					#RUN中にTACKLEされた時
        					if (hamster.state == RUN) &&
        						(hamster.obstacle.opnt_state == TACKLE)
        						
        						_knocked_speed = hamster.obstacle.impact * (1.0 / hamster.weight)	#"受けた衝撃"と"重さ"から速さを算出
        						_knocked_angle = hamster.obstacle.angle							#衝突後の向き
        						
        						#転倒状態に変化
        						hamster.changeStatus(SLIP, :speed => _knocked_speed, :angle => _knocked_angle)
        						
        						#衝突相手をリセット
        						hamster.obstacle.opnt_state = nil
        					end
        					
        					#受けた衝撃をリセット
						hamster.obstacle.impact = 0.0
        				end
        			}
        		end
        		
        		def self.getNumberOfHamster
        			@@AllHamster.length
        		end
        		
        		def self.getAllHamster_id
        			
        			_array = Array.new
        			
        			@@AllHamster.each{|ham|
        				_array.push(ham.object_id)
        			}
        			return _array
        		end
        		
        		def self.allDraw
        			@@AllHamster.each{|ham|
        				ham.draw
        			}
        		end
        		
        		def draw
        			Window.draw_ex(@x - (Game::TEXTURE_SIZE_128 / 2), @y - (Game::TEXTURE_SIZE_128 / 2), @image[@animNumber], :scalex=> @size, :scaley=> @size, :angle=> @drawingAngle)
        		end
        		
        		def self.finalize
        			@@affectSpeedAll = 0.0			#hamster全てのwheelへの速さの影響の平均
        			@@weightAll = 0.0					#hamster全ての重さの合計
        			@@AllHamster.clear
        		end
        		
        		attr_reader:x
        		attr_reader:y
        		attr_reader:size
        		attr_reader:weight
        		attr_reader:angle
        		attr_reader:radius
        		attr_reader:acceleration
        		attr_accessor:speed
        		attr_reader:affectSpeed
        		attr_reader:influence
        		attr_reader:state
        		attr_reader:drawingAngle
        		attr_reader:obstacle
        		attr_reader:knockedSpeed
        		attr_reader:comeBackFlag
end