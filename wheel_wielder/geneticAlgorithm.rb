require'./newral'
require'./player'

class Genetic
	
	MUTATION_RATE = 5
	
	CROSSING_PARE = 3
	
	@@generation = 0		#世代数
	@@oldGene = nil		#旧世代の遺伝子
	
	#新世代開始
	def self.newGeneration
		
		if @@generation > 0 && @@oldGene != nil
			#全newralのyamlファイルを復元
			Newral::all_load(@@oldGene)
		end
	end
	
	#世代交代
	def self.generationalChange
		#全newralのyamlファイルを保存
		_yaml_name_array = Newral::all_dump(@@generation)
		
		#全newralのyamlファイルを読み込み
		_data_array = Newral::all_Input(_yaml_name_array)
		
		#全newralのyamlファイルを遺伝的アルゴリズムに基づいて書き換える
		_new_data_array = self.genetic(_data_array)
		
		#全newralのyamlファイルを書き出し
		@@oldGene = Newral::all_output(_new_data_array)
	end
	
	#遺伝的アルゴリズムに基づいた遺伝
	def self.genetic(_data_array)
		#交叉
		_new_fitness_array, _new_data_array, _num_data = self.crossing(_data_array)
		
		#突然変異
		_new_data_array = self.mutation(_new_data_array)
		
		#淘汰
		_new_data_array = self.select(_new_fitness_array, _new_data_array, _num_data)
		
		return _new_data_array
	end
	
	#交叉
	def self.crossing(_data_array)
		#元データと交叉結果を保持する配列
		_new_data_array = Array.new
		_new_fitness_array = Array.new
		
		#適応度を配列で取得
		_fitness_array = Newral::game_finishing
		
		#元データを新しい配列に移す
		for num in 0..(_fitness_array.length - 1) do
			_new_data_array.push(_data_array[num])
			_new_fitness_array.push(_fitness_array[num])
		end
		
		#遺伝子長を取得(重み) 
		_gene_length _w= _data_array[0][0].length
		
		#遺伝子長を取得(バイアス) 
		_gene_length_b = _data_array[0][0].length
		
		#ペア選択
		_pare_array = Array.new
		
		#一定数のペアを作る
		for num in 1..CROSSING_PARE do
			_p1 = Random::rand(0..(_fitness_array.length - 1))
			_p2 = Random::rand(0..(_fitness_array.length - 1))
			
			#同じものが選択されたときは別のものになるまでループ
			while _p2 == _p1 do
				_p2 = Random::rand(0..(CROSSING_PARE - 1))
			end
			
			_pare_array.push(Array[_p1, _p2])
		end
		########################################
		#	一点交叉
		########################################
		#ペアごとに一点交叉する
		_pare_array.each{|p|
			#染色体
			_c1 = Array.new
			_c2 = Array.new
			
			#遺伝子(重み)
			_c1_w = Array.new
			_c2_w = Array.new
			
			#遺伝子(バイアス)
			_c1_b = Array.new
			_c2_b = Array.new
			
			#染色体に遺伝子を設定
			_c1.push(_c1_w)
			_c1.push(_c1_b)
			_c2.push(_c2_w)
			_c2.push(_c2_b)
			
			#交叉(重み)
			_separate_w = Random::rand(0..(_gene_length _w- 1))
			
			for num in (0..(_gene_length_w - 1)) do
				
				if num <= _separate_w
					_c1[0].push(_data_array[p[0]][0][num])
					_c2[0].push(_data_array[p[1]][0][num])
				else
					_c1[0].push(_data_array[p[1]][0][num])
					_c2[0].push(_data_array[p[0]][0][num])
				end
			end
			
			#交叉(バイアス)
			_separate_b = Random::rand(0..(_gene_length _b- 1))
			
			for num in (0..(_gene_length_b - 1)) do
				
				if num <= _separate_b
					_c1[1].push(_data_array[p[0]][1][num])
					_c2[1].push(_data_array[p[1]][1][num])
				else
					_c1[1].push(_data_array[p[1]][1][num])
					_c2[1].push(_data_array[p[0]][1][num])
				end
			end
			#子供を保存
			#子１
			_new_data_array.push(_c1)
			_new_fitness_array.push(((_fitness_array[p[0]] * _separate_w) + (_fitness_array[p[1]] * ((_gene_length_w - 1) - _separate_w))) / (_gene_length_w - 1))
			
			#子２
			_new_data_array.push(_c2)
			_new_fitness_array.push(((_fitness_array[p[1]] * _separate_w) + (_fitness_array[p[0]] * ((_gene_length_w - 1) - _separate_w))) / (_gene_length_w - 1))
		}
		
		return _new_fitness_array, _new_data_array, _fitness_array.length
	end
	
	#突然変異
	def self.mutation(_new_data_array)
		########################################
		#	転座
		########################################
		_new_data_array.each{|chr|
			
			#突然変位を確率に従って行う
			if (Random::rand(100)) <= MUTATION_RATE
				
				_m1 = Random::rand(0..chr[0].length - 1)
				_m2 = Random::rand(0..chr[0].length - 1)
				
				#遺伝子を入れ替える
				_buf = chr[0][_m1]
				chr[0][_m1] = chr[0][_m2]
				chr[0][_m2] = _buf
				
				p 'Mutation !!'
			end
		}
		
		return _new_data_array
	end
	
	#淘汰
	def self.select(_new_fitness_array, _new_data_array, _num_data)
		#最終決定するデータの格納用配列
		_final_data_array = Array.new
		
		########################################
		#	ルーレット選択
		########################################
		#ルーレット作成
		_roulette = Array.new(_new_fitness_array.length)
		
		#適応度の和
		_sum = 0
		
		#ルーレットの範囲を確定
		for num in 0..(_new_fitness_array.length - 1) do
			_roulette[num] = _sum + _new_fitness_array[num]
			_sum = _roulette[num]
		end
		
		#乱数でデータの枠分だけ選択する
		for num in 0..(_num_data - 1) do
			#ルーレットの止まった位置
			_select = Random::rand(_sum)
			
			#対応するインデックス
			_index = 0
			
			#対応するインデックスを検索
			for index in 0...(_new_fitness_array.length - 1) do
				
				if _roulette[index] >= _select
					_index = index
					break
				end
			end
			#選択したデータを配列に追加
			_final_data_array.puah(_new_data_array[_index])
		end
		
		return _final_data_array
	end
end