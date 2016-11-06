local menu = {}

function menu:init()
	
end

function menu:getgame()
	return self.Game
end

function menu:draw()
	local W, H = love.graphics.getWidth(), love.graphics.getHeight()
	
	love.graphics.setColor(255,255,255)
	love.graphics.printf('MENU SHIT HERE', 0, H/2, W, 'center')
end

return menu