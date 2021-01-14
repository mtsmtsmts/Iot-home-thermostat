--[[Check https://github.com/mtsmtsmts/Iot-thermosta]]--

ide_Server = net.createServer(net.TCP) --Create TCP server
if ide_Server then
  ide_Server:listen(8098, function(ideconn) --Listen to the port 
    editor(ideconn) 
    end)
end    
print ("Server code started")
