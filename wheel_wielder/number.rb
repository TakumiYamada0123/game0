require'dxruby'
require'matrix'

# 表示用数字オブジェクト
class Number
	
	@@image = Image.load_tiles('image/number_variable_color.png', 5, 2)
	
	TEXTURE_SIZE_64 = 64.0
	
	#座標指定の基準を表す
	LEFT = 0
	RIGHT = 1
	
	TOP = 0
	BOT = 1
	
	MID = 2
	
	def initialize(position, size = Vector[50.0, 50.0], space = 0, posOfWhere_x = MID, posOfWhere_y = MID,
		color = [255, 255, 255, 255],
		position_src = nil,
		angle_src = nil,
		rotation_flag = false
		)
		#	引数について
		# number_id	: 表示したい数値のID
		# position		: 表示位置(Vector)
		# size	 		: 数字の縦横の幅(Vector)
		# space		: 字間
		# posOfWhere_x	: pos.xの基準とする数字表示の位置(LEFT, RIGHT, MID)
		# posOfWhere_y	: pos.yの基準とする数字表示の位置(TOP, BOT, MID)
		# color			: 色配列
		# angle_src	: 描画角度の参照先ID
		# rotation		: 回転の中心	trueなら数字単位で、falseなら全体で回転する
		
		@number = 0
		@position = position
		@size = size
		@space = space
		@posOfWhere_x = posOfWhere_x
		@posOfWhere_y = posOfWhere_y
		@color = color
		@position_src = position_src
		@angle_src = angle_src
		@rotation_flag = rotation_flag
		
		#すべての桁の数字を配列に取得
		@digit = Array.new
	end
	
	def draw(number)
		
		@number = number
		
		#数値の初期化
		@digit.clear
		
		#数値の更新
		@number.to_s.chars{|ch|
			
			@digit.push(ch.to_i)
		}
		
		#数値表示全体の大きさを算出する
		_x = (@size[0] * @number.to_s.length) + (@space * (@number.to_s.length - 1))
		_y = @size[1]
		
		@overall_size = Vector[_x, _y]
		
		#########################################################
		#	最初に描画する最上位の桁の基準位置を決定する
		#########################################################
		_pos_x = (@position_src == nil) ? @position[0] : ObjectSpace._id2ref(@position_src).x
		_pos_y = (@position_src == nil) ? @position[1] : ObjectSpace._id2ref(@position_src).y
		
		#########################################################
		#	X座標
		case @posOfWhere_x
		
		when LEFT
			@draw_x = _pos_x + (@size[0] * 0.5)
			
		when RIGHT
			@draw_x = _pos_x - @overall_size[0] + (@size[0] * 0.5)
			
		when MID
			@draw_x =_pos_x - (@overall_size[0] * 0.5) + (@size[0] * 0.5)
		end
		
		#########################################################
		#	Y座標
		case @posOfWhere_y
		
		when TOP
			@draw_y = _pos_y + (@size[1] * 0.5)
			
		when BOT
			@draw_y = _pos_y - (@size[1] * 0.5)
			
		when MID
			@draw_y = _pos_y
		end
		#########################################################
		
		#########################################################
		#	描画
		_draw_digit_x = @draw_x
		_draw_digit_y = @draw_y
		
		_scale_x = (@size[0]) / TEXTURE_SIZE_64
		_scale_y = (@size[1]) / TEXTURE_SIZE_64
		
		@digit.each{|num|
			
			Window.draw_ex(_draw_digit_x - (TEXTURE_SIZE_64 * 0.5),
								_draw_digit_y - (TEXTURE_SIZE_64 * 0.5),
								@@image[num],
								:scale_x => _scale_x,
								:scale_y => _scale_y,
								:center_x => (@rotation_flag) ? nil : @_draw_x,
								:center_y => (@rotation_flag) ? nil : @_draw_y,
								:angle => (@angle_src != nil) ? ObjectSpace._id2ref(@angle_src).angle : 0,
								:color => @color,
								:alpha => @color[0], 
								:blend => :alpha
								)
			_draw_digit_x += @size[0] + @space
			_draw_digit_y += 0.0
		}
	end
	
end