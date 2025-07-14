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
	msg = "JOB," + str(username) + ",LOW," + str(mining_key)
	byte_message = codeunits(msg)
	
	write(socket, byte_message)

	job = String(read(socket, 87))
	println("Job received: ", job)

	job = split(job, ",")
	lastBlockHash = job[1]
	result = job[2]
	difficulty = parse(Int32, job[3]) * 100

	for i = 0:difficulty
		stringToHash = string(lastBlockHash, string.(i))
		ducos1 = bytes2hex(sha1(stringToHash))

		if ducos1 == result 
			write(socket, string(i, ",,Julia Miner"))
			feedback = String(read(socket, 4))
			if feedback == "GOOD"
				println("Accepted share ", i, "\tDifficulty ", difficulty)
				break
			else
				println("Rejected share ", i, "\tDifficulty ", difficulty)
				break
			end
		end
		i += 1
	end
end
