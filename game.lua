local gamestate = require( "hump/gamestate" )

local loopback = require( "loopback" )

local GAME = {
	VERSION = "0.0.1",
	STATES = {
		"MENU", --menu state
		"DISCONNECTED", --got disconnected for any reason, game state will say why
		"LOBBY", --waiting for players
		"INTRO", --current lobby intro for the game
		"ROUNDINTERMISSION", --say we're starting a certain round and show the rules
		"WRITEANSWERS", --writing answers phase
		"SCOREBOARD", --people see their scores
		"SHOWQUESTION", --show the question without answers yet
		"SHOWANSWERS", --let people vote on the answers
		"SHOWANSWERRESULTS", --will show vote results and who wrote the answers, calculates scores
		"SHOWGAMEWINNER", --this guy wins, tada!!! go to credits
		"CREDITS", 
	},
	CLIENTINPUT = {
		LOBBY = {
			name = "",
			limit = 56, --this is checked serverside and clamped if needed
		},
		WRITEANSWERS = {
			answer1 = "",
			answer2 = "",
			limit = 128, --this is checked serverside and clamped if needed
		},
		SHOWANSWERS = { --this will be reused for the last lash, and will be called multiple times for clients
			vote = 0, --0 no vote, otherwise it's the index of the vote
		}
	},
}


function GAME:Init()
	gamestate.registerEvents()
	self.Server = false
	
	self.LubeClients = {
		
	}
	
	self.LubeServers = {
		
	}
	
	--each gamestate will have data as an index in this table
	self.GameState = {
		
	}
	
	self.Clients = {
		--[[
		["loopback:0"] = {
			networkid = "loopback:0"
			name = "Jvs",
			score = 0,
			data = {
				round1 = {
					answer1 = "Im fucking gay",
					answer2 = "HARAMBE",
				},
				round2 = {
					answer1 = "Rook mine",
					answer2 = "Duck game",
				},
				round3 = {
					answer = "dildomatic"
				},
			}
		},
		["127.0.0.1:27015"] = {
			networkid = "127.0.0.1:27015"
			name = "Test",
			score = 0,	
		}
		]]
	}
	
	--load all the gamestates in memory
	for i , v in pairs( self.STATES ) do
		local statefile = "gamestates/" .. v:lower()
		
		self.GameState[i] = require( statefile )
		
		if type( self.GameState[i] ) == "table" then
			self.GameState[i].Game = self
		end
		
	end
	
	
	
	
	
	
	gamestate.switch( self:GetState( "MENU" ) )
end

function GAME:GetName()
	return "Cards Against Whiplash"
end

function GAME:GetState( numberorstring )
	local state = nil
	
	if type( numberorstring ) == "number" then
		state = self.GameState[i]
	else
		state = self.GameState[self:StateToNumber( numberorstring )]
	end
	
	return state
end

function GAME:StateToNumber( statename )
	local number = nil
	for i , v in pairs( self.STATES ) do
		if statename == v then
			number = i
			break
		end
	end
	
	return number
end

function GAME:NumberToState( number )
	local statename = nil
	
	if self.STATES[number] then
		statename = self.STATES[number]
	end
	
	return statename
end

function GAME:Think( deltatime )
	self:NetworkingThink( deltatime )
	self:RoundThink( deltatime )
end

function GAME:Disconnect()
	
	if self:IsServer() then
		for i , v in pairs( self.LubeServers ) do
			v:init()
		end
		
		self.Server = false
	end
	
	for i , v in pairs( self.LubeClients ) do
		v:disconnect()
		v:init()
	end
end

function GAME:Connect( ip , port , tcp )
	--prevent user from inputting loopback on his own
	--unlike with hosting, we don't have to add a normal client when looping back
	tcp = true
	
	if ip == "loopback" and port == 0 then
		self.LubeClients[#self.LubeServers + 1] = loopback.Client
	else
		--how do we tell the client that we're in tcp mode?
		if tcp then
			self.LubeClients[#self.LubeClients + 1] = lube.tcpClient
		else
			self.LubeClients[#self.LubeClients + 1] = lube.udpClient
		end
	end
	
	for i , v in pairs( self.LubeClients ) do
		v:init()
		v.callbacks.recv = function( data )
			self:OnClientReceive( data )
		end
		
		v.handshake = json.encode( 
		{ 
			caw_handshake = self.VERSION
		} )
		v:setPing( true , 10 , json.encode( { "caw_ping" } ) )
		v:connect( ip , port )
				
		for i = 1 , 5 do
			v:send( "test" .. i )
		end
	end
	
end

function GAME:StartServer( tcp )
	self.Server = true
	--let's test just with tcp for now
	tcp = true
	
	if tcp then
		self.LubeServers[#self.LubeServers + 1] = lube.tcpServer
	else
		self.LubeServers[#self.LubeServers + 1] = lube.udpServer
	end
	
	--add the loopback server
	self.LubeServers[#self.LubeServers + 1] = loopback.Server
	
	for i , v in pairs( self.LubeServers ) do
		v:init()
		
		v.callbacks.recv = function( data , clientid )
			self:OnServerReceive( data , clientid )
		end
		
		v.callbacks.connect = function( clientid )
			self:OnClientConnected( clientid )
		end
		
		v.callbacks.disconnect = function( clientid )
			self:OnClientDisconnected( clientid )
		end
		
		v.handshake = json.encode( 
		{ 
			caw_handshake = self.VERSION
		} )
		
		v:setPing( true , 10 , json.encode( { "caw_ping" } ) )
		
		v:listen( 27015 )
		
		
		
	end
	
	self:Connect( "loopback" , 0 )
end

--called when having to do main logic
function GAME:IsServer()
	return self.Server
end

--used for drawing operations and whatever
function GAME:IsClient()
	return love ~= nil
end

function GAME:NetworkingThink( deltatime )
	if self:IsClient() then
		for i , v in pairs( self.LubeClients ) do
			v:update( deltatime )
		end
	end
	
	if self:IsServer() then
		for i , v in pairs( self.LubeServers ) do
			v:update( deltatime )
		end
	end
end

function GAME:OnClientConnected( clientid )
	print( "Client connected ".. clientid )
end


function GAME:OnClientDisconnected( clientid )
	print( "Client disconnected ".. clientid )
end

function GAME:OnServerReceive( data , clientid )
	print( "Client says: " , data , clientid )
end

function GAME:OnClientReceive( data )
	print( "Server says: " , data )
end

function GAME:RoundThink( deltatime )
	if self:IsServer() then
		--do actual logic
	end
end

function GAME:Remove()
	--remove all gamestates
	self:Disconnect()
end

local function NewGame()
	local gamenew = setmetatable( {} ,
	{
		__index = GAME,	
	})
	
	gamenew:Init()
	
	return gamenew
end

return {
	new	= NewGame,
}