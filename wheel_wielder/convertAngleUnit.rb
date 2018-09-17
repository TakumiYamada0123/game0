require'dxruby'

module ConvertAngleUnit
	
	def to_radian(degree)
        	degree * Math::PI / 180
	end

	def to_degree(radian)
        	radian * 180 / Math::PI
	end
	
	#≥—≈Ÿ ‰¿µ(max°Î - 360.0°Î°°°¡°°max°Î§Œ¥÷§À —¥π§π§Î)
	def correct_degree(degree, max = 360.0)
		
		if degree < max - 360.0
        		degree += 360.0
        	elsif degree > max
        		degree -= 360.0
        	end
        	degree
	end
end