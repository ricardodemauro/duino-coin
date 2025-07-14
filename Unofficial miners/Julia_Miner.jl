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

# Convert hex string to bytes
function hex2bytes_custom(hex_str)
    len = length(hex_str)
    bytes = Vector{UInt8}(undef, div(len, 2))
    for i in 1:2:len-1
        bytes[div(i+1, 2)] = parse(UInt8, hex_str[i:i+1], base=16)
    end
    return bytes
end

# DUCO-S1 algorithm implementation - returns the found share or 0 if not found
function ducosha1(lastBlockHash, expected_hash, difficulty)
    expected_hash_bytes = hex2bytes_custom(expected_hash)
    
    for i = 0:(100 * difficulty)
        hash_input = string(lastBlockHash, i)
        hash_bytes = sha1(hash_input)
        
        if hash_bytes == expected_hash_bytes
            return i
        end
    end
    
    return 0  # No valid share found
end

while true
    try
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
            difficulty = parse(Int, job_parts[3])
            
            println("Last Block Hash: ", lastBlockHash)
            println("Expected Hash: ", expected_hash)
            println("Difficulty: ", difficulty)
            
            start_time = now()
            println("Started mining at: ", start_time)
            
            # Call the ducosha1 function to find a share
            result = ducosha1(lastBlockHash, expected_hash, difficulty)
            
            end_time = now()
            duration = Dates.value(end_time - start_time) / 1000 # in seconds
            
            if result > 0
                hashrate = result / duration
                
                println("Mining completed at: ", end_time)
                println("Duration: $(duration) seconds, Hashrate: $(round(hashrate/1000, digits=2)) kH/s")
                
                # Send result back
                response = "$(result),$(hashrate),Julia Miner"
                println("Sending response: $(response)")
                write(socket, response)
                
                feedback = readline(socket)
                if feedback == "GOOD"
                    println("Accepted share ", result, "\tHashrate ", round(hashrate/1000, digits=2), " kH/s \tDifficulty ", difficulty)
                else
                    println("Rejected share ", result, "\tHashrate ", round(hashrate/1000, digits=2), " kH/s \tDifficulty ", difficulty, "\tMessage: ", feedback)
                end
            else
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
        try
            global socket = Sockets.connect(socket_ip, socket_port)
            println("Reconnected to server")
        catch
            println("Reconnection failed. Retrying in 5 seconds...")
            sleep(5)
        end
    end
end
