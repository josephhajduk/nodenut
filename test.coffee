nut = require "./lib/nodenut.js"

nut.setDebug()

myconn = nut.connect "172.16.1.150",3493,"admin","mypass", ()->
	myconn.getUpsList (upslist) ->

		for ups in upslist 

			console.log ups

			ups.getVars (vars) ->
				console.log vars

			ups.getCommands (commands) ->
				console.log commands

			ups.getRWVars (vars) ->
				console.log vars
