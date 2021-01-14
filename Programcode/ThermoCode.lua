--[[Check https://github.com/mtsmtsmts/Iot-thermosta]]--

local buffer_Data --preserves data across function, needs global
cur_Temp=13 --set timer to call function every initialization or every xx hours?
local Timer1 = tmr.create() --needs to preserve across function calls
local Timer2 = tmr.create() --needs to preserve across function calls 

function decide(newTemp) --function is called from web server
    local GPIOTempUp=5
    local GPIOTempDown=6
    local EnableRelay = gpio.HIGH  --transistor on
    local nEnableRelay = gpio.LOW  --transistor off
    local SecPerDeg=180 --timers in millisecs
    local StartLagTime=1000 --delays after pushing button
    local EndLagTime=5000 --delays after releasing button
    local FAST=30 --blink period in ms
    local SLOW=140 --blink period in ms
    local ErrorCasual=2000 --website might be down
    local ErrorImmediate=350 --lost synch with thermostat
    local SetPoint={on=21, off=13, up=2, down=-2, reset=13} --Referenced with: x=table["itemA"] or x=table.itemA
    local BlinkSpeed--inits to nil
    local curTemp = cur_Temp
    local changeTemp=nil --inits to nil
    local DelayTimer--inits to nil
	local offTimer=nil--inits to nil
   
    print(" ")
    print("Temp request:",newTemp)
    print("Temp request:",SetPoint[newTemp],"degrees")
    print("Current Temperature",curTemp,"degrees")
    if tonumber(curTemp) ~= nil then
        if newTemp == "up" or newTemp == "down" then
            changeTemp = SetPoint[newTemp]
            BlinkSpeed = FAST
			offTimer =true
            print("up or down success!")
        elseif newTemp == "on" then
            changeTemp = SetPoint[newTemp] - curTemp
            BlinkSpeed = FAST
			offTimer =true
            print("on or off success!")  
		elseif newTemp == "off" then
            changeTemp = SetPoint[newTemp] - curTemp
            BlinkSpeed = FAST
			offTimer =false
            print("on or off success!")  			
        elseif newTemp == "reset" then
            curTemp = SetPoint[newTemp]
            BlinkSpeed = FAST
			offTimer =false
            print("Temp reset:",curTemp)            
        else
            BlinkSpeed = SLOW
            print("garbage in new_temp")           
        end      
    else
        print("cur_Temp is not a number, cannot adjust temperature:",curTemp)
        ErrorState(ErrorImmediate)   
    end
    
    Timer2run = Timer2:state() --returns nil,false,true
    Timer1run = Timer1:state() --returns nil,false,true
    print("timer 1,2 is:",Timer1run,Timer2run)

    --Timer 1 and 2 running indicates execution of a command in progress and any new commands are buffered
    --until completion of timer 2. Consecutive calls during busy period will overwrite buffer 
    if (Timer1run or Timer2run) == true then
        changeTemp=nil
        buffer_Data = newTemp 
    end

    if changeTemp ~= nil and changeTemp ~= 0 then 
        if (gpio.read(GPIOTempDown) or gpio.read(GPIOTempUp)) ~= 1 then --execute only if not busy on port
            DelayTimer = (math.abs((changeTemp)) * SecPerDeg) + StartLagTime   --determine how many degrees to change and include initial delay
            
            local UpDown	--determine increment or decrement
            if changeTemp < 0 then 
                UpDown = GPIOTempDown
            elseif changeTemp > 0 then
                UpDown = GPIOTempUp
            end
                              
            if UpDown ~= nil then    
                gpio.write(UpDown,EnableRelay)  --enable port before 
                if not Timer1:alarm(DelayTimer, tmr.ALARM_SINGLE, function (t)           --execute for requested period
                        if not Timer2:alarm(EndLagTime, tmr.ALARM_SINGLE, function ()   --set new one shot timer with end lag delay, 5 secs
                                if buffer_Data ~= nil then	--if a new command was requested
                                    decide(buffer_Data)		--read new command and clear buffer daya
                                    buffer_Data = nil
                                    --unregister?
                                end
                            end) 
                        then ErrorState(ErrorCasual) --if timer 2 was used?                     
                        end
                        gpio.write(UpDown, nEnableRelay)	--disable port
                        --put checkrange() and here?
                        t:unregister() 
                    end)
                then ErrorState(ErrorCasual) --If timer 1 was used?
                end --end timer start
            end --end updown test
        end --end gipio read
    else --end changetemp has data
        print("No Adjustment to thermostat - command ignored changetemp")
        changeTemp = 0 --0 looks nicer in serial monitor than nil
        DelayTimer = 0
        BlinkSpeed = SLOW
    end --end changetemp test
    
    curTemp = CheckRange(changeTemp, 0, curTemp) --determine if the new setpoint is within operating range of thermostat (5-27C)
    StoreToCloud(curTemp)  
	setOffTimer(offTimer) --Heat will nEnable after a period of being on, time set in function
    Blink(BlinkSpeed, 0)
    print(DelayTimer,"ms")  
    print("Temp change:",changeTemp,"degrees")     
    cur_Temp = curTemp
end
dofile("thermo2code.lua")
file.close("Thermo2Code.lua")
print ("Thermo1 code started")
RetrieveFromCloud(1) --init POR
Blink(140)
RestoreHeatonReset() --init POR
