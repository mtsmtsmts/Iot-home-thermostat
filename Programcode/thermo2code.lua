--[[Check https://github.com/mtsmtsmts/Iot-thermosta]]--

local Error_Flag=0     --global error flag for led blink file
local heat_On = nil	--flag for current operation state, stored in flash too
local offTimer = tmr.create() --global so it can be referenced outside of function and stopped to change interval()

function Blink(speed, BlinkForever)
    local LED=4
    local Timer3 = tmr.create()
    local num_Blinks = 8
    local LEDstatus = gpio.read(LED) 
    
    if not Timer3:alarm(speed, 1, function (t)
            LEDstatus = not LEDstatus
            gpio.write(LED, LEDstatus and gpio.HIGH or gpio.LOW)
            --gpio.serout(1,gpio.HIGH,{5000,995000},100, function() print("done") end)  --will this work to toggle the pin ?
            if BlinkForever ~= 1 then
                num_Blinks = num_Blinks - 1
                if num_Blinks < 1 then
                    gpio.write(LED, 1) --turn off
                    num_Blinks = 0
                    t:unregister() 
                end               
            end
        end)
    then print("can't blink, timer used")
    end   
end

function ErrorState(BlinkTime)
    local errFlg = Error_Flag
    if errFlg == 0 then --need global error flag as multiple calls to blink timer will flood stack      
        errFlg = 1 
        Blink(BlinkTime, errFlg)
        Error_Flag = errFlg
    else                   
        print("Error called again") 
    end
    print("errorflag state:", errFlg)
end

function setOffTimer(checkVar)	
    local FileheatOn=false
	if checkVar == true and tonumber(heat_On) == nil then		
		heat_On=0
        FileheatOn=true
		offTimer:alarm(60000, tmr.ALARM_AUTO, function(t) --blink every 5 minutes to remind
				if heat_On then
					Blink(3, 0)
					heat_On = heat_On+1
					print(heat_On)
					if heat_On >= 60 then	--60000ms*60ticks =3600secs, heat on for 1 hour				
						decide("off")
						heat_On=nil
                        FileWrite("data.txt","heat:",0)
						t:unregister()
					end
				else	
					t:unregister()
				end
			end)
	elseif checkVar == true and tonumber(heat_On) then --heat already on and adjustment made        
        heat_On=0	
        FileheatOn=true         	
	elseif checkVar == false then
        if offTimer:state() then
            offTimer:stop()
            offTimer:unregister()
        end
		heat_On = nil
	else	--nil
	end	
    FileWrite("data.txt","heat:", FileheatOn and 1 or 0) --store state to local flash
end

function RestoreHeatonReset()
    local fileData = FileRead("data.txt", "heat:")  --read state from flash
    fileData = tonumber(fileData)
    if fileData ~= nil and fileData ~= 0 then setOffTimer(true) end   --heat was on before reset, timer is reset so heat stays on for another full period
end

function CheckRange(newTemperature, onReset, currTemp)--func(new temp, on reset or temperature change adjustment) 
    if onReset == 0 then --adjusting new temperature 
        if tonumber(newTemperature) ~= nil and tonumber(currTemp) ~= nil then
            currTemp = currTemp + tonumber(newTemperature) -- += not defined    
        end
    elseif onReset == 1 then --retrieve data on startup or reset
        if tonumber(newTemperature) ~= nil then
            print("setting program temp from cloud")
            currTemp = tonumber(newTemperature)
        else
            print("data received is not a number:",newTemperature)
            ErrorState(350)
        end
    end
    
    if currTemp > 27 then --range of hardware is 5-27 C
        currTemp = 27             
    elseif currTemp < 5 then
        currTemp = 5
    end    
    return currTemp
end

function StoreToCloud(currentTemp)       
    http.get("http://yoursitehere.000webhostapp.com/esppost.php?Temp="..(currentTemp*10),nil,function(code)--site name omitted for githib
            if (code < 0) then
                print("Store to Cloud Failed",code) --website must be down?
                ErrorState(2000)
            else
                print("new current temp:",currentTemp,"degrees")  
                print("Temp stored in cloud:",currentTemp*10)
            end
        end ) --send temp to cloud
end

function RetrieveFromCloud(Reset)
    http.get("http://yoursitehere.000webhostapp.com/data.html",nil,function(code, data)--specifics omitted
            if (code < 0) then
                print("Retrieve from Cloud Failed",code) --website down?
                ErrorState(2000)
            else
                data = data/10
                local curTemp = cur_Temp
                cur_Temp = CheckRange(data, Reset, curTemp)
                print("Init temp on reset:",cur_Temp,"degrees")
                print("Temp from cloud:",data,"degrees")
                print("Temp set in program:",cur_Temp,"degrees")
            end
        end)
end
print ("Thermo2 code started")
