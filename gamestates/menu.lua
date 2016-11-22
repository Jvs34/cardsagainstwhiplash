local menu = {}

function menu:init()
	self.ui = suit.new()
	self.input = { 
		text = "gay",
		maxchars = 10
	}
end

function menu:update( deltatime )

	
	self.ui.layout:reset( 0 , 0 )
	
	self.ui.layout:row( 200 , 50 )
	
	if not self:GetGame():IsConnected() and not self:GetGame():IsServer() then
	
		if self.ui:Button( "Start Server", self.ui.layout:row( 200 , 50 ) ).hit then
			if not self:GetGame():IsServer() then 
				signal.emit( "menu_startserver" , self ) --state that caused it
			end
		end
	
	end
	
	if not self:GetGame():IsConnected() then
		if self.ui:Button( "Join Server", self.ui.layout:row( 200 , 50 ) ).hit then
			if not self:GetGame():IsConnected() then
				signal.emit( "menu_joinserver" , self , "127.0.0.1" , 27015 )
			end
		end
	end
	
	
	--[[
	self.ui:Input( self.input , self.ui.layout:row( 200 , 50 ) )
	
	if #self.input.text > self.input.maxchars then
		self.input.text = self.input.text:sub( 0 , self.input.maxchars )
	end
	]]
end

function menu:GetGame()
	return self.Game
end

function menu:textinput( text )
	self.ui:textinput( text )
end

function menu:keypressed( key , scancode , isrepeat )
	self.ui:keypressed( key )
end

function menu:draw()
	local w , h  = love.graphics.getWidth() , love.graphics.getHeight()
	
	love.graphics.setBackgroundColor( 180 , 180 , 180 )
	self.ui:draw()
end

return menu