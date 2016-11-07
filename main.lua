class = require( "hump/class" )
timer = require( "hump/timer" )
signal = require( "hump/signal" )
vector = require( "hump/vector" )
lube = require( "love-misc-libs/grease/grease" )
suit = require( "suit" )
game = require( "game" )
json = require( "json" )

local caw = nil

function love.load()
	caw = game.new()
	love.window.setTitle( caw:GetName() )
	
	caw:StartServer( true )
end

function love.update( deltatime )
	if caw then
		caw:Think( deltatime )
	end
	
	timer.update( deltatime )
end

function love.draw()
	--gamestate drawing will take care of this
end

function love.mousepressed( x  , y , button , isTouch )
end

function love.mousereleased( x , y , button , isTouch )

end

function love.wheelmoved( x , y )

end

function love.keypressed( key , scancode , isrepeat )

end

function love.keyreleased( key )

end

function love.textinput( text )

end

function love.quit()
	if caw then
		caw:Remove()
	end
	
	return false
end