--[[Check https://github.com/mtsmtsmts/Iot-thermosta]]--

thermo_Server = net.createServer(net.TCP) --Create TCP server

if thermo_Server then
    thermo_Server:listen(8098, function(thermoconn) --Listen to the port 
       dataParse(thermoconn)
    end)
end

function dataParse(thermoconn) --Process callback on recive data from client
    local cmdString1="webhooks" --This is an identifier, it acts as a simple filter/"prehistoric password" to avoid attacks
    local cmdString2="restart"
    thermoconn:on("receive", function(sck8098, data)
        print(data)
        if data ~=nil then
            substr=string.sub(data,string.find(data,"GET /")+5,string.find(data,"HTTP/")-1) --Filter data between GET and HTTP/
            if substr ~= nil and substr ~= " " then	
                if string.find(substr,'favicon.ico') then --Acting as filter
                    --print("This is the favicon return! don't use it "..substr)
                else
                    substr=string.lower(substr) --Set the string lower case to check it against
                    if string.find(substr,cmdString1) then 
                    print(substr)
                        if substr~=nil then
                            substr=string.sub(substr,string.find(substr,":")+4,string.find(substr,":")+20) --Keep only the text part after the colon
                            substr=string.gsub(substr," ","",5)  --Replace all (5) spaces     
                            decide(substr)
                        end
                    elseif string.find(substr,cmdString2) then--set webIDE POR flag to true and restart
                        sck8098:on("sent", function(thermoconn) thermoconn:close() end)
                        sck8098:close()
                        FileWrite("data.txt","Restart:",1)                       
                        node.restart()   
                    end 
                end 
            end
        end 
    --sck8076:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n".."Detected: "..substr) --This is a simple web page response to be able to test it from any web browser 
    sck8098:on("sent", function(thermoconn) thermoconn:close() end)
    end)
end  
print ("Server code started")
