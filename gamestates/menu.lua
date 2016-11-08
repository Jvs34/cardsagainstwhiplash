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
	
	self.ui:Button( "im gay", self.ui.layout:row( 200 , 50 ) )
	
	
	
	self.ui:Input( self.input , self.ui.layout:row( 200 , 50 ) )
	
	if #self.input.text > self.input.maxchars then
		self.input.text = self.input.text:sub( 0 , self.input.maxchars )
	end
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
	self.ui:draw()
	
	--[[
	local W, H = love.graphics.getWidth(), love.graphics.getHeight()
	
	love.graphics.setColor(255,255,255)
	love.graphics.printf('MENU SHIT HERE', 0, H/2, W, 'center')
	]]
end

return menu