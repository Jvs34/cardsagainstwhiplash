local loopback = {}

loopback.ip = "loopback"
loopback.port = 0

loopback.id = loopback.ip..":"..loopback.port

--shamelessly copied from lua pil, look it's 3 am and I don't care enough
local buffer = {
	client = {
		first = 0,
		last = -1,
	},
	server = {
		first = 0,
		last = -1
	},
	pushtop = function( tab , val )
		local first = tab.first -1
		tab.first = first
		tab[first] = val
	end,
	pushbottom = function( tab , val )
		local last = tab.last + 1
		tab.last = last
		tab[last] = val
	end,
	poptop = function( tab )
		local first = tab.first
		if first > tab.last then
			return
		end
		local val = tab[first]
		tab[first] = nil
		tab.first = first + 1
		return val
	end,
	popbottom = function( tab )
		local last = tab.last
		if tab.first > last then
			return
		end
		local val = tab[last]
		tab[last] = nil
		tab.last = last - 1
		return val
	end
}

local client = {}
client._implemented = true

function client:createSocket()
	buffer.client = {
		first = 0,
		last = -1,
	}
	return true
end

function client:_connect()
	return true
end

function client:_disconnect()
end

--puts the data on the loopback buffer
function client:_send(data)
	buffer.pushbottom( buffer.client , data )
	return true
end

--retrieve the data from the loopback buffer
function client:_receive()
	local data = buffer.poptop( buffer.server )
	
	if data then
		return data
	end
	
	return false, "Unknown remote sent data."
end



local server = {}
server._implemented = true

function server:createSocket()
	buffer.server = {
		first = 0,
		last = -1,
	}
	return true
end

function server:_listen()
end

function server:send(data, clientid)
	buffer.pushbottom( buffer.server , data )
end

function server:receive()
	local data = buffer.poptop( buffer.client )
	
	if data then
		local id = loopback.id
		return data , id
	end
	
	return nil, "No message."
end

function server:accept()
end

--derive from grease.Client and grease.Server
loopback.Client = common.class( "loopback.Client" , client , grease.Client )
loopback.Server = common.class( "loopback.Server" , server , grease.Server )

return loopback