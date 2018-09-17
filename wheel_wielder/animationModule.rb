require'dxruby'

module Animation
	
	def infomationAnim(interval, initNumber)
		@interval = interval				#アニメーションのインターバルフレーム数
		@animNumber = initNumber		#アニメーション初期番号
		@intervalCnt = @interval		#アニメーションのインターバルフレームカウンタ
		@frameCnt = 0				#アニメーションフレームカウンタ
	end
	
	def numberCalcAnim(animationNumber)
		@intervalCnt -= 1       #アニメーションインターバルフレームカウンタをカウントダウン
	
		#アニメーションインターバルフレームカウンタが0になった時
			if @intervalCnt <= 0 
	      
	        		#アニメーション番号を算出
	        		@animNumber = @frameCnt % animationNumber
	        		@frameCnt += 1   							#アニメーションカウンタをカウントアップ
	        		
	        		if @frameCnt >= 65530
	        			@frameCnt = 0
	        		end
	        		
	        		@intervalCnt = @interval        #アニメーションインターバルフレームカウンタを初期化
			end
		return @number
	end
	attr_reader:animNumber
	attr_reader:interval
	attr_reader:intervalCnt
	attr_reader:frameCnt
end