local loopback = {}

local buffer = {
	client = {},
	server = {},
}

local client = {}
client._implemented = true

function client:createSocket()
	return true
end

function client:_connect()
	return true
end

function client:_disconnect()
end

--puts the data on the loopback buffer
function client:_send(data)
	buffer.client[#buffer.client+1] = data
	return true
end

--retrieve the data from the loopback buffer
function client:_receive()
	local data = buffer.server[#buffer.server]
	
	if #buffer.server > 0 then
		buffer.server[#buffer.server] = nil	--remove from buffer
		return data
	end
	
	return false, "Unknown remote sent data."
end



local server = {}
server._implemented = true

function server:createSocket()
end

function server:_listen()
end

function server:send(data, clientid)
	buffer.server[#buffer.server+1] = data
end

function server:receive()
	local data = buffer.client[#buffer.client]
	
	if #buffer.client > 0 then
		local id = "loopback:0"
		buffer.client[#buffer.client] = nil	--remove from buffer
		return data , id
	end
	
	return nil, "No message."
end

function server:accept()
end

--derive from lube.Client and lube.Server
loopback.Client = common.class( "loopback.Client" , client , lube.Client )
loopback.Server = common.class( "loopback.Server" , server , lube.Server )

return loopback