--[[Check https://github.com/mtsmtsmts/Iot-thermosta]]--

function checkRestart()
    local Restart = FileRead("data.txt","Restart:") --retrieve POR flag
    print("Restart status:",Restart) 
        if Restart == "1" then	--if flag true start with WebIDE else start normally
            Restart=0
            print("ide code starting")
            FileWrite("data.txt","Restart:",Restart)
            StartIdeServer()
        elseif Restart == nil then --if not flag present, create it
            file.putcontents("data.txt","Restart:0Heat:0")
            node.restart()
        else  
            print("Application code starting")          
            StartApplication()
        end 
end

function StartApplication()
    if file.open("ThermoCode.lua") == nil then
        print("ThermoCode deleted or renamed")
    else
        dofile("ThermoCode.lua")
        file.close("ThermoCode.lua")
    end          
    if file.open("ServerCode.lua") == nil then
        print("servercode.lua deleted or renamed")
    else
        dofile("ServerCode.lua")
        file.close("ServerCode.lua")
    end
end

function StartIdeServer()
    if file.open("ide.lua") == nil then
        print("ide deleted or renamed")
    else
        dofile("ide.lua")
        file.close("ide.lua")
    end  
    if file.open("IdeServercode.lua") == nil then
        print("ideServercode deleted or renamed")
    else
        dofile("IdeServercode.lua")
        file.close("IdeServercode.lua")
    end 
    tmr.create():alarm(600000, tmr.ALARM_SINGLE, function() node.restart() end) --10 minutes before reset
    local LEDstatus= gpio.read(4)      
     tmr.create():alarm(1350, tmr.ALARM_AUTO, function () --blink to indicate IDE state        
            LEDstatus = not LEDstatus
            gpio.write(4, LEDstatus and gpio.HIGH or gpio.LOW)
            end) 
end

function FileWrite(filename, data1, data2)--writes a single digit associated to text "xxxx:"
    local fileData
    local substr
    local StrLen
    if file.open(filename,"r") ~= nil then
        fileData = file.read()
        file.close(filename)
        if fileData ~= nil then
            fileData = string.lower(fileData) 
            data1 = string.lower(data1)       
            StrLen = string.len(data1..data2) 
            if string.find(fileData, data1) then  
                substr = string.sub( fileData, string.find( fileData, data1),string.find( fileData, data1 )+StrLen-1)  
                fileData = string.gsub( fileData,substr,data1..data2)                
            else
                fileData = fileData..data1..data2
            end
            file.open(filename,"w+")
            file.write(fileData)
            file.close(filename)
            print("file write text",fileData)
        end
    end
    return fileData --returns nil if not created file

end

function FileRead(filename, data1) --returns a single digit associated to text "xxxx:"
    local fileData
    local StrLen
    if file.open(filename,"r") ~= nil then
        fileData = file.read()     
        file.close(filename)   
        data1 = string.lower(data1) 
        StrLen = string.len(data1)
        if fileData ~= nil then
            if StrLen ~= nil then
                if data1 ~= nil then
                    fileData = string.lower(fileData) 
                    print("file read text",fileData)
                    if string.find(fileData, data1) then                        
                        fileData = string.sub( fileData, string.find( fileData, data1), string.find(fileData,data1)+StrLen)
                        fileData = string.sub(fileData,string.find(fileData,":")+1)
                    else fileData = nil
                    end                    
                end
            end
        end
    end
    return fileData --returns nil if not file exist or not found text
end
checkRestart()
