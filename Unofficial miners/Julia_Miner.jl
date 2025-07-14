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
    try

		# Client.send(job_req
		#             + Settings.SEPARATOR
		#             + str(user_settings["username"])
		#             + Settings.SEPARATOR
		#             + str(user_settings["start_diff"])
		#             + Settings.SEPARATOR
		#             + str(key)
		#             + Settings.SEPARATOR
		#             + str(raspi_iot_reading))

        msg = "JOB,$(username),LOW,$(mining_key),y"
		println("Sending message: ", msg)

        byte_message = codeunits(msg)
        write(socket, byte_message)

        job = readline(socket)
        println("Job received: ", job)
        
        job_parts = split(job, ",")
        
        if length(job_parts) >= 3
            lastBlockHash = job_parts[1]
            result = job_parts[2]
            difficulty = parse(Int32, job_parts[3]) * 100
            
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
        else
            println("Invalid job format: received only ", length(job_parts), " parts instead of at least 3")
            sleep(2)
        end
    catch e
        println("Error occurred: ", e)
        sleep(3)
        try
            global socket = Sockets.connect(socket_ip, socket_port)
            println("Reconnected to server")
        catch
            println("Reconnection failed. Retrying in 5 seconds...")
            sleep(5)
        end
    end
end
