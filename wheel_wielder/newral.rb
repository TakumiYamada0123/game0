require 'ruby_brain'
require 'yaml'

require'./game'
require'./wheel'
require'./hamster'
require'./player'
require'./autoAction'
require'./convertAngleUnit'

class Newral
	include ConvertAngleUnit
	
	@@INPUT = (Hamster::getNumberOfHamster * 5) + ((Hamster::getNumberOfHamster - 1) * 2) + 1
	@@HIDDEN = 20
	@@OUTPUT = 8 + (Hamster::getNumberOfHamster - 1) * 2
	
	@@allNewalNetwork = Array.new
	
	def initialize(autoplayer_id)
		@network = RubyBrain::Network.new([@@INPUT, @@HIDDEN, @@OUTPUT])
		@network.init_network
		
		@autoplayer_id = autoplayer_id
		
		@fitness = 0			#遺伝的アルゴリズム用の適応度
		
		@autoAction = AutoAction.new(self.object_id)
		
		@@allNewalNetwork.push(self.object_id)
		p'Link-NN : No.' + @@allNewalNetwork.length.to_s
	end
	
	def input_yaml(yaml)
		@data = open(yaml, 'r') { |f| YAML.load(f) }
	end
	
	def output_yaml(data)
		YAML.dump(data, File.open(@yaml_file, 'w'))
	end
	
	def dump_weight
		@network.dump_weights_to_yaml(@yaml_file)
	end
	
	def load_weight(yaml)
		@network.load_weights_from_yaml_file(yaml)
		@yaml_file = yaml
	end
	
	def thinking
		p'start'
		###############################################################
		#入力値の配列を作る
		_input_data = Array.new
		
		_self_ham = ObjectSpace._id2ref(@autoplayer_id).hamster
		_self_prm = ObjectSpace._id2ref(@autoplayer_id).rank
		
		Player::getAllPlayer.each{|player_id|
			
			_player_ham = ObjectSpace._id2ref(player_id).hamster
			_player_prm = ObjectSpace._id2ref(player_id).rank
			
			_wheel = ObjectSpace._id2ref(Wheel::getUsingWheel)
			
			if player_id != @autoplayer_id
				
				#距離
				_dist = (Math::hypot((_self_ham.x - _player_ham.x), (_self_ham.y - _player_ham.y)) / (_wheel.radius * 2))
				_input_data.push(_dist)
				
				#角度差
				_angle_difference = (self.correct_degree(_player_prm.angle2Goal - _self_prm.angle2Goal, 180.0).abs) / (180.0)
				_input_data.push(_angle_difference)
			end
			
			#周回数
			_laps = (_player_prm.laps) / Game::GOAL_LAPS
			_input_data.push(_laps)
			
			#順位
			_rank = (_player_prm.rank) / Hamster::getNumberOfHamster
			_input_data.push(_rank)
			
			#状態
			_state = _player_ham.subState
			_input_data.push(_state)
			
			#速度
			_speed = (_player_ham.speed) / Hamster::HAM_SPEED_MAX
			_input_data.push(_speed)
			
			#重さ
			_weight = (_player_ham.weight) / Hamster::HAM_WEIGHT_MAX
			_input_data.push(_weight)
		}
		#ホイール速度
		_wheel_speed = (_wheel.speed) / ((1.0 / _wheel.axisRadius) * _wheel.AffectedRate)
		_input_data.push(_wheel_speed)
		###############################################################
		p'thinking'
		_output_data = @network.get_forward_outputs(_input_data)
		
		_result =0
		_index = 0
		
		_output_data.each_with_index{|out, i|
			
			if out > _result
				_result = out
				_index = i
			end
		}
		@autoAction.act = _index
		return _index
	end
	
	def self.game_finishing
		_array = Array.new
		@@allNewalNetwork.each{|nn|
			nn.fitness = ObjectSpace._id2ref(nn.autoplayer_id).rank.laps
			_array.push(nn.fitness)
		}
		return _array
	end
	
	def self.all_Input(file_name_array)
		_index = 0
		_data_array = Array.new
		
		@@allNewalNetwork.each{|nn|
			nn.input_yaml(file_name_array[_index])
			_array.push(nn.data)
		}
		return _data_array
	end
	
	def self.all_output(data_array)
		index = 0
		_array = Array.new
		@@allNewalNetwork.each{|nn|
			nn.output_yaml(data_array[index])
			_array.push(nn.yaml_file)
			index += 1
		}
		return _array
	end
	
	def self.all_dump(generation)
		_array = Array.new
		_index = 0
		@@allNewalNetwork.each{|nn|
			nn.yaml_file = 'GrowingData/gen_' + generation.to_s + '_idx_' + _index.to_s + 'weight.yml'
			
			nn.dump_weight()
			_array.push(nn.yaml_file)
			_index += 1
		}
		return _array
	end
	
	def self.all_load(file_name_array)
		_index = 0
		
		@@allNewalNetwork.each{|nn|
			nn.load_weight(file_name_array[_index])
			_index += 1
		}
	end
	
	def self.all_thinking
		if @@allNewalNetwork.length <= 0
			p'Not found Newral Network'
			return
		end
		p'I am thinking. Please wait !!'
		
		@@allNewalNetwork.each{|nn|
			p 'NNID : ' + nn.object_id.to_s
			_act = nn.thinking()
			p 'Select Act : ' + _act.to_s
		}
	end
	
	def self.finalize
		@@allNewalNetwork.clear
	end
end