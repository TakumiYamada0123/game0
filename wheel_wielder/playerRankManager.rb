require'dxruby'
require'./checkPoint'
require'./convertAngleUnit'
require'./supportMath'
require'./wheel'

###########################################################################################
#		��������Ƚ�꤬��(�⤷�����ƺ�ɸ�ϤΤ�����)
###########################################################################################

class PlayerRankManager
	include ConvertAngleUnit
	include SupportMath
	
	ANGLE_THRESHOLD = 0.1				#Ʊ���٤�Ƚ�Ǥ�������
	
	@@allPlayerRankManager = Array.new
	
	def initialize(origin_id)
		@pass_flag = Array.new(CheckPoint::NUM_CHECKPOINT, false)	#�����å��ݥ���Ȥ��̲�ե饰
		@angle2Goal = 0.0											#������饤��Ȥγ��ٺ�
		@near_point = nil											#�Ǥ�ᤤ���Υ����å��ݥ����
		@laps = 0												#�����
		@rank = 1												#���
		@id = origin_id											#�оݥץ쥤�䡼�μ��ץ��֥������Ȥ�ID
		
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
		
		#�������꺸¦�ˤ����
		if !(self.Cross2LorR(goal_x, goal_y, _x, _y))
			_angle = 360.0 - _angle
		end
		
		@angle2Goal = _angle
	end
	
	def checkPassFlag(checkpoint_array, wheel_x, wheel_y)
		
		_x = ObjectSpace._id2ref(@id).hamster.x - wheel_x
		_y = ObjectSpace._id2ref(@id).hamster.y - wheel_y
		
		#�Ǥ�ᤤ���Υ����å��ݥ���Ȥ����ꤷ�Ƥ��ʤ���
		if @near_point == nil
			
			_near_angle = nil		#�Ǥ�ᤤ����
			
			for num in 0..(CheckPoint::NUM_CHECKPOINT - 1) do
				
				_CPx = checkpoint_array[num][:x]
				_CPy = checkpoint_array[num][:y]
				
				#���Ѥˤ�뺸��90�����Ǥ���Ƚ��
				if (self.Dot(_x, _y, _CPx, _CPy) > 0)
					
					#���Ѥˤ�뺸��Ƚ��(�����å��ݥ���ȥ٥��ȥ��ۤ��Ƥ���Ƚ��)
					if !(self.Cross2LorR(_CPx, _CPy, _x, _y))
						
						next		#���Υ����å��ݥ���Ȥ�Ƚ���ѥ�����
					end
					
					#���٤λ���
					_angle =  self.to_degree(self.Dot2Radian(_CPx, _CPy, _x, _y))
					
					#�Ǿ����٤�̤����ΤȤ�
					if _near_angle == nil
						_near_angle = _angle
						
						#���λ��Υ����å��ݥ���Ȥ��ݻ�
						@near_point = num
						
					#����ѤΤȤ�
					else
						#�����Υ����å��ݥ���Ȥ��ᤤ���ɤ�����Ƚ��
						if _angle < _near_angle
							
							#�Ǥ�ᤤ���٤Ȥ����ݻ�����
							_near_angle = _angle
							
							#���λ��Υ����å��ݥ���Ȥ��ݻ�
							@near_point = num
						end
					end
				end
			end
			
		#�Ǥ�ᤤ���Υ����å��ݥ���Ȥ����ꤵ��Ƥ����
		else
			
			#�̲�Ƚ�ꤹ������å��ݥ����
			_checkpoint = checkpoint_array[@near_point]
			 
			_CPx = _checkpoint[:x]
			_CPy = _checkpoint[:y]
			
			#���Ѥˤ�뺸��Ƚ��(�����å��ݥ���ȥ٥��ȥ��ۤ��Ƥ���Ƚ��)
			if !(self.Cross2LorR(_CPx, _CPy, _x, _y))
				
				#�оݤΥ����å��ݥ���Ȥ��̲�ѤΤȤ�
				if @pass_flag[@near_point]
					
					@near_point = (@near_point + 1 == CheckPoint::NUM_CHECKPOINT) ? 0
													: @near_point + 1
					
					return	#�ؿ���ȴ����
				end
				
				@pass_flag[@near_point] = true
				
				if @near_point == 0
					
					_num_pass = 0	#�̲�ѥե饰�ο�
					
					#��0�פ�������Ƥ��̲�ե饰�򻲾Ȥ���
					for num in 1..(CheckPoint::NUM_CHECKPOINT - 1) do
						
						#�̲�ѤΤȤ�
						if @pass_flag[num]
							
							_num_pass += 1	#�̲�ѥե饰�򥫥���Ȥ���
						end
					end
					
					#��0�פ�������Ƥ��̲�ե饰����true�פΤȤ�
					if _num_pass == CheckPoint::NUM_CHECKPOINT - 1
						
						@laps += 1	#�������û�����
					end
						
					#���ե饰����Ȥ�
					for num in 0..(CheckPoint::NUM_CHECKPOINT - 1) do
						
						@pass_flag[num] = false
					end
				end
				
				@near_point = nil
			end
		end
	end
	
	def self.calcRank
		
		#angle2Goal�ǥ�����(��������)
		@@allPlayerRankManager.sort!{|ps1, ps2| ps1.angle2Goal <=> ps2.angle2Goal}
		
		#Laps�ǥ�����(�礭����)
		@@allPlayerRankManager.sort!{|ps1, ps2| ps2.laps <=> ps1.laps}
				
		_number = 1							#����դ��ѿ���
		
		#��̤򿶤�
		@@allPlayerRankManager.each{|prm|
			
			prm.rank = _number				#��̳���
			_number += 1						#���ν�̤�
		}
	end
	
	attr_reader:angle2Goal
	attr_reader:near_point
	attr_reader:pass_flag
	attr_reader:laps
	attr_accessor:rank
end