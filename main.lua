class = require( "hump/class" )
lube = require( "lube" )
game = require( "game" )
timer = require( "hump/timer" )
signal = require( "hump/signal" )
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


function love.quit()
	if caw then
		caw:Remove()
	end
	
	return false
end