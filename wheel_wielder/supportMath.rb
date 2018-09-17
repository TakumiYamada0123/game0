require'dxruby'
require'matrix'

module SupportMath
	
	def Dot(x1, y1, x2, y2)
		_v1 = Vector[x1, y1]
		_v2 = Vector[x2, y2]
		
		_v1.dot(_v2)
	end
	
	def Dot2Radian(x1, y1, x2, y2)
		_v1 = Vector[x1, y1]
		_v2 = Vector[x2, y2]
		
		_v1.angle_with(_v2)
	end
	
	def Cross2D(x1, y1, x2, y2)
		
		_result = Vector[0, 0, (x1 * y2) - (x2 * y1)]
	end
	
	def Cross2LorR(x1, y1, x2, y2)
		
		_result = (x1 * y2) - (x2 * y1)
		
		return _left = _result > 0 ?  true : false
	end
	
	def Cross3D(x1, y1, z1, x2, y2, z2)
		
		_result = Vector[(y1 * z2) - (y2 * z1), (z1 * x2) - (z2 * x1), (x1 * y2) - (x2 * y1)]
	end
end