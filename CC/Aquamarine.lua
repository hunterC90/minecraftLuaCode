-- This function uses a mining turtle to automate aquamarine generation
-- Set up an aquamarine generator using starlight and lava
-- Place turtle with the generated sand block in front of it
-- Place a chest behind the turtle
-- Profit
sandCount = 0

-- Ensure turtle is facing the sand (this is done to incase the server shutdown while the turtle was facing the chest)
print("Starting up!")
x, itemDetail = turtle.inspect()
while itemDetail.name ~= "minecraft:sand" do
    turtle.turnLeft()
    x, itemDetail = turtle.inspect()
end
print("Ready to go!")

-- Main loop
while true do
    if turtle.getItemCount() == 0 then
        turtle.dig()
    end

    itemDetail = turtle.getItemDetail()
    if itemDetail ~= nil and itemDetail.name == "minecraft:sand" then
        turtle.dropDown()
        sandCount = sandCount + 1
        if math.random() < (math.tanh(sandCount/100 - 4) + 1)/5 then
            print("I hate sand!")
            sandCount = 0
        end
    else
        sandCount = 0
        print("Got one!")

        turtle.turnLeft()
        turtle.turnLeft()

        turtle.drop()
        if turtle.getItemCount() > 0 then
            print("I'm bricked up rn!")
        end

        while turtle.getItemCount() > 0 do
            sleep(1)
            turtle.drop()
        end
        turtle.turnLeft()
        turtle.turnLeft()
    end
end