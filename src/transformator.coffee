apply = (func) -> (obj, rest...) -> func.apply(obj, rest)
jade = require 'jade'
net = require 'net'
cbor = require 'cbor'
mod_minify = require 'minify'
Sync = require 'sync'
transformers = require 'transformers'

pack = (obj) -> cbor.Encoder.encode(obj)

minify = (ext, input) ->
	fn = (ext, input, cb) ->
		_cb = (error, data) ->
			throw "minify: #{error}" if error
			cb null, data
		mod_minify {
			ext: ".#{ext}"
			data: "#{input}"
		}, _cb, _cb
	fn.sync null, ext, input

transformers['jade'] =
	outputFormat: 'html'
	sync: true
transformers['minify_js'] =
	outputFormat: 'js'
	sync: true
transformers['minify_css'] =
	outputFormat: 'css'
	sync: true
transformers['minify_html'] =
	outputFormat: 'html'
	sync: true

compile = (obj) ->
	[engine, input, data] = obj
	switch "#{engine}"
		when 'jade'
			fn = jade.compile "#{input}"
			return fn(data)
		when 'minify_js'   then return minify 'js'  , input
		when 'minify_css'  then return minify 'css' , input
		when 'minify_html' then return minify 'html', input
		when 'list'
			byfmt = {}
			for a, b of transformers
				continue unless b.sync
				fmt = b.outputFormat
				byfmt[fmt] ?= []
				byfmt[fmt].push a
			list = []
			for fmt, engines of byfmt
				list.push "[ #{fmt} ]"
				for engine in engines.sort()
					list.push "\t#{engine}"
			return list.join "\n"
		else
			transformer = transformers[engine]
			throw 'unknown engine' unless transformer?
			throw 'unsupported engine' unless transformer.sync
			return transformer.renderSync "#{input}"
	null

server = net.createServer apply ->
	@on 'end', ->
		# do nothing
	
	sink = new cbor.Decoder()

	sink.on 'error', (err) ->
		@end
		console.error err

	sink.on 'complete', (obj) =>
		Sync =>
			answer = { error: 'Could not process input for unknown reason' }
			try
				result = compile(obj)
				if result?
					answer = { result: "#{result}" }
			catch e
				answer = { error: "In compile(...): #{e}" }
			try
				buf = pack(answer)
			catch e
				console.error answer
				buf = pack({ error: "In pack(...): #{e}" })
			@write(buf)
			@end

	@pipe sink

server.on 'error', (e) ->
	console.error "error: #{e}"

process.argv.shift()
process.argv.shift()
port = process.argv.pop() || 12345
host = process.argv.pop() || 'localhost'
host = undefined if !parseInt(port)

try
	server.listen port, host, ->
		console.log "server bound at #{host||'unix'}:#{port}"
catch e
	console.error "error: #{e}"
