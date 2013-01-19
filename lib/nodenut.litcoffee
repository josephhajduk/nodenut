nodenut  
=======

nodenut provies an abstraction api for accessing a nutd server using the 
[network protocol](http://www.networkupstools.org/docs/developer-guide.chunked/ar01s09.html)

		net = require "net"

for conveiniance a simple debug method is created
		
		debug = () ->

		exports.setDebug = () ->
			debug = (message) ->
				console.log message	
		

The NutConnection class will handle initiating and terminating our connection 
to the nutd server

		class NutConnection

The constructor will simple store the host,port,login, and password parameters.
In the future we will probably validate these

The default port for the nutd protocol is 3493

			constructor: (@host,@port=3493,@username=null,@password=null) ->

The sendCommand method sends a command to the server then waits for the 
response which it fires back to the callback.  This needs to be tested

			sendCommand: (cmd,cb) ->
				if connected != true
					throw new Error("Not Connected")
				else
					@conn.write cmd+"\n", () ->
						@conn.once "data", (data) ->
							response = data
							debug "CMD: #{cmd} -> #{response}"
							cb(response)

The connect method opens the socket to the server.  Note:  there is no proper 
keepalive, but that could be easily added if we can figure out what nutd 
expects

			connect: (cb) ->
				@conn = net.createConnection {host: @host, port: @port}

We set the encoding to "ascii"

				@conn.setEncoding('ascii')

				@conn.on "connect", () =>
					debug "Connected to #{@host}:#{@port}"
					@connected = true

If a username and password were specified we send the corresponding commands
to the server,  if the server does not respond with OK\n to both we throw
exceptions

					if @username?
						debug "Username specified, attempting USERNAME cmd"
						@.sendCommand "USERNAME #{@username}", (response)=>
							if response != "OK\n"
								throw new Error("USERNAME NOT OK")
							else
								if @password?
									debug "Password specified, attempting PASSWORD cmd"
									@.sendCommand "PASSWORD #{@password}", (response)=>
										if response != "OK\n"
											throw new Error("PASSWORD NOT OK")	
										else
											cb(@)
								else
									cb(@)

version just spits back whatever the server responds with when we send it "VER"

			version: (cb) ->
				@.sendCommand "VER", cb

getUpsList:  this returns an array of NutUPS objects that can be used to futher
access the api

			getUpsList: (cb) ->
				@.sendCommand "LIST UPS", (response) ->
					responseLines = response.split("\n")

we do some basic validation on the response from the server

					if responseLines[0] != "BEGIN LIST UPS"
						throw new Error("Unexpected response to LIST UPS")
					if reponseLines[responseLines.length - 1] != "END LIST UPS"
						throw new Error("Unfinished response to LIST UPS")
					else
						upsLines = responseLines.pop().shift()
						result = for line in upsLines
							match = /UPS (.*) "(.*)"/i.exec line
							new NutUPS(@,match[1],match[2])
						cb(result)

it is not clear if this functionality is required, but it is in the spec

			logout: () ->
				@connected = false
				@conn.end "LOGOUT\n"

The NutUps class abstracts the vars, cmds, and rwvars for each ups.

		class NutUPS
			constructor: (@connection, @upsname, @description) ->

getVars returns a javascript object with keys for each vars back to the callback

			getVars: (cb) ->
				@connection.sendCommand "LIST VAR #{@upsname}", (response)->
					responseLines = response.split("\n")
					if responseLines[0] != "BEGIN LIST VAR #{@upsname}"
						throw new Error("Unexpected response to LIST VAR #{@upsname}")
					if reponseLines[responseLines.length - 1] != "END LIST VAR #{@upsname}"
						throw new Error("Unfinished response to LIST VAR #{@upsname}")
					else
						upsLines = responseLines.pop().shift()

						results = {}

						for line in upsLines
							match = new RegExp("VAR #{@upsname} (.*) \"(.*)\"" ,"i").exec line
							results[match[1]] = match[2]

						cb(results)

getCommands returns a list of commands back to the callback

			getCommands: (cb) ->
				@connection.sendCommand "LIST CMD #{@upsname}", (response)->
					responseLines = response.split("\n")
					if responseLines[0] != "BEGIN LIST CMD #{@upsname}"
						throw new Error("Unexpected response to LIST CMD #{@upsname}")
					if reponseLines[responseLines.length - 1] != "END LIST CMD #{@upsname}"
						throw new Error("Unfinished response to LIST CMD #{@upsname}")
					else
						upsLines = responseLines.pop().shift()

						results = for line in upsLines
							match = new RegExp("VAR #{@upsname} (.*)" ,"i").exec line
							match[1]

						cb(results)

getRWVars returns a javascript object containing keys for each rwvar back to 
the callback

			getRWVars: (cb) ->
				@connection.sendCommand "LIST RW #{@upsname}", (response)->
					responseLines = response.split("\n")
					if responseLines[0] != "BEGIN LIST RW #{@upsname}"
						throw new Error("Unexpected response to LIST RW #{@upsname}")
					if reponseLines[responseLines.length - 1] != "END LIST RW #{@upsname}"
						throw new Error("Unfinished response to LIST RW #{@upsname}")
					else
						upsLines = responseLines.pop().shift()

						results = {}

						for line in upsLines
							match = new RegExp("RW #{@upsname} (.*) \"(.*)\"" ,"i").exec line
							results[match[1]] = match[2]

						cb(results)

setRW sends the command to set the RW,  if the server does not respond with 
"OK\n" it will throw and exception, otherwise it will return via the callback

			setRWVar: (rwvar,value,cb) ->
				@connection.sendCommand "SET VAR #{@upsname} #{rwvar} #{value}", (response) ->
					if response != "OK\n"
						throw new Error("Failed to write to rwvar: #{rwvar} to: #{value} received: #{response}")
					else
						cb()

runCommand sends the instcmd command to the server,  if the server does not 
respond with "OK\n" it will  throw and exception, otherwise it will return via 
the callback

			runCommand: (command,cb) ->
				@connection.sendCommand "INSTCMD #{@upsname} #{command}", (response) ->
					if response != "OK\n"
						throw new Error("Failed to instcmd #{command}: #{response}")
					else
						cb()


here we export a connect function that will create our object then call connect
, and once connected hit the callback with the newly created object

		exports.connect = (host,port,username,password,cb) ->
			connection = new NutConnection(host,port,username,password)
			connection.connect cb
























