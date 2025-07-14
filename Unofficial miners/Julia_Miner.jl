using Sockets
using SHA

username = ENV["DUINO_USERNAME"]
mining_key = ENV["DUINO_MINING_KEY"]

socket_ip = "152.53.241.160"
socket_port = 7070

socket = Sockets.connect(socket_ip, socket_port)
println("Connected to Duino-Coin server")

server_ver = String(read(socket, 3))
println("Server is on version: ", server_ver)

while true
	msg = "JOB," * string(username) * ",LOW," * string(mining_key)
	byte_message = codeunits(msg)
	
	write(socket, byte_message)

	job = readline(socket)
	println("Job received: ", job)

	job = split(job, ",")
	lastBlockHash = job[1]
	result = job[2]
	difficulty = parse(Int32, job[3]) * 100

	for i = 0:difficulty
		stringToHash = string(lastBlockHash, string(i))
		ducos1 = bytes2hex(sha1(stringToHash))

		if ducos1 == result 
			response = string(i, ",,Julia Miner")
			write(socket, response)
			feedback = readline(socket)
			if feedback == "GOOD"
				println("Accepted share ", i, "\tDifficulty ", difficulty)
				break
			else
				println("Rejected share ", i, "\tDifficulty ", difficulty)
				break
			end
		end
	end
end
