local loopback = require( "loopback" )

local GAME = {
	VERSION = "0.0.1",
	STATES = {
		"MENU", --menu state
		"DISCONNECTED", --got disconnected for any reason, game state will say why
		"LOBBY", --waiting for players
		"INTRO", --current lobby intro for the game, hello, "welcome to caw man I have to apologize to the pope etc"
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
		--
		LOBBY = {
			name = "",
			limit = 56, --this is checked serverside and clamped if needed
		},
		WRITEANSWERS = {
			answer = "harambe",
			limit = 128, --this is checked serverside and clamped if needed
		},
		SHOWANSWERS = { --this will be reused for the last lash, and will be called multiple times for clients
			vote = 0, --0 no vote, otherwise it's the index of the vote
		}
	},
	CONFIG = { --TODO CONFIG FILE
		MAXPLAYERS = 8, --in total
		MAXANSWERS = 2, --to give during writeanswers phase
		ROUNDS = 3,	--last lash included
		SCORE = {
			WINNER = 100, --winner gets +100
		},
		SCOREMULTIPLIER = function( score , round ) 
			return score * round 
		end,
		LASTLASH = {
			ENABLED = true,
			VOTES = 3,
		}
	}	
}


function GAME:Init()
	gamestate.registerEvents()
	
	self.Server = false
	
	--this will contain the grease client channels
	self.GreaseClients = {
		
	}
	
	--this will contain the grease server channels
	self.GreaseServers = {
		
	}
	
	--some stuff here needs to be networked to the clients that will be relayed to the corresponding game state
	--but otherwise, this data here is what the main logic is all about
	self.GlobalGameState = {
		currentround = 1,
		--[[
			round1 = {
				question1 = {
					text = "Who's the best meme 2016?",
					questionid = 6969, --so you can look it up from database and load sounds and whatever
					answers = {
						{
							text = "harambe",
							author = "loopback:0",
							score = 0.7 --percentage of people who voted it
						},
						{
							text = "rook mine",
							author = "127.0.0.1:27015",
							score = 0.3 --percentage of people who voted it
						},
					}
				}
				--and so on
			}
		]]
	}
	
	--the questions database
	self.Database = {
		
		
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
	
	--each gamestate will have data as an index in this table
	self.GameState = {
		
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
		for i , v in pairs( self.GreaseServers ) do
			v:init()
		end
		self.GreaseServers = {}
		self.Server = false
	end
	
	for i , v in pairs( self.GreaseClients ) do
		v:disconnect()
		v:init()
	end
	
	self.GreaseClients = {}
end

function GAME:Connect( ip , port , tcp )
	--prevent user from inputting loopback on his own
	--unlike with hosting, we don't have to add a normal client when looping back
	tcp = true
	
	if ip == loopback.ip and port == loopback.port then
		self.GreaseClients[#self.GreaseClients + 1] = loopback.Client
	else
		--how do we tell the client that we're in tcp mode?
		if tcp then
			self.GreaseClients[#self.GreaseClients + 1] = grease.tcpClient
		else
			self.GreaseClients[#self.GreaseClients + 1] = grease.udpClient
		end
	end
	
	for i , v in pairs( self.GreaseClients ) do
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
		self.GreaseServers[#self.GreaseServers + 1] = grease.tcpServer
	else
		self.GreaseServers[#self.GreaseServers + 1] = grease.udpServer
	end
	
	--add the loopback server
	self.GreaseServers[#self.GreaseServers + 1] = loopback.Server
	
	for i , v in pairs( self.GreaseServers ) do
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
	
	self:Connect( loopback.ip , loopback.port )
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
		for i , v in pairs( self.GreaseClients ) do
			v:update( deltatime )
		end
	end
	
	if self:IsServer() then
		for i , v in pairs( self.GreaseServers ) do
			v:update( deltatime )
		end
	end
end

--server hook
function GAME:OnClientConnected( clientid )
	print( "Client connected ".. clientid )
end

--server hook

function GAME:OnClientDisconnected( clientid )
	print( "Client disconnected ".. clientid )
end

--server hook

function GAME:OnServerReceive( data , clientid )
	print( "Client says: " , data , clientid )
	--unserialize the message and check if it's allowed at all
	
end

--client hook
function GAME:OnClientReceive( data )
	print( "Server says: " , data )
end


function GAME:SendToClient( data , clientid )
	--at this point data has already been converted to a json string so we don't have to do much here
	local chosenchannel = nil
	
	if clientid == nil then
		chosenchannel = nil --broadcast to all the channels, even the loopback
	else
		
		--is this check needed? loopback will always be connected to the channels below, so technically we should leave it like this
		--[[
		if clientid == loopback.id then
			chosenchannel = self.GreaseServers[#self.GreaseServers] --loopback is always last, in case we're a headless server
		else
		]]
		
		--search the channel for the clientid and send it over if we found it 
		for i , v in pairs( self.GreaseServers ) do
			if v.clients[clientid] then
				chosenchannel = v
				break
			end
		end
		
		--end
		
	end
	
	--could probably do this with an assert
	if chosenchannel == nil and clientid ~= nil then
		Error( "Could not find a channel to send "..data .. " to" .. clientid .."!!!!!" )
	end
	
	if chosenchannel == nil then
		for i , v in pairs( self.GreaseServers ) do
			v:send( data )
		end
	else
		chosenchannel:send( data , clientid )
	end
end

function GAME:SendToServer( data )
	--while on the server there may be multiple channels, on the client there's only one, loopback or not
	--but still, just in case
	--although we need to make 1000000% sure that we close the other channels and we call GAME:Disconnect properly!!!!!!!!!
	for i , v in pairs( self.GreaseClients ) do
		v:send( data )
	end
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