using Sockets
using SHA
using Dates

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
            expected_hash = job_parts[2]
            difficulty = parse(Int32, job_parts[3])
            
            println("Last Block Hash: ", lastBlockHash)
            println("Expected Hash: ", expected_hash)
            println("Difficulty: ", difficulty)
            
            start_time = now()
            println("Started mining at: ", start_time)
            
            # Fix the hash calculation method
            for i = 0:(100 * difficulty)
                # Combine the lastBlockHash and the current i value then hash once
                stringToHash = string(lastBlockHash, string(i))
                ducos1 = bytes2hex(sha1(stringToHash))
                
                if ducos1 == expected_hash
                    end_time = now()
                    duration = Dates.value(end_time - start_time) / 1000 # in seconds
                    hashrate = i / duration
                    
                    println("Mining completed at: ", end_time)
                    println("Duration: $(duration) seconds, Hashrate: $(round(hashrate/1000, digits=2)) kH/s")
                    
                    # Send result back (include hashrate like Python does)
                    response = "$(i),$(hashrate),Julia Miner"
                    write(socket, response)
                    
                    feedback = readline(socket)
                    if feedback == "GOOD"
                        println("Accepted share ", i, "\tHashrate ", round(hashrate/1000, digits=2), " kH/s \tDifficulty ", difficulty)
                        break
                    else
                        println("Rejected share ", i, "\tHashrate ", round(hashrate/1000, digits=2), " kH/s \tDifficulty ", difficulty)
                        break
                    end
                end
            end
            
            if i > 100 * difficulty
                end_time = now()
                duration = Dates.value(end_time - start_time) / 1000 # in seconds
                println("Mining failed after $(duration) seconds")
            end
        else
            println("Invalid job format: received only ", length(job_parts), " parts instead of at least 3")
            sleep(2)
        end
    catch e
        println("Error occurred: ", e)
        # Print stack trace for better debugging
        println("Stack trace: ", catch_backtrace())
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
            println("Reconnection failed. Retrying in 5 seconds...")
            sleep(5)
        end
    end
end
