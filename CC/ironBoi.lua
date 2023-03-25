local nugs = 0
while true do
    for i = 1, 50 do
        for x = 1, 4 do 
            turtle.select(x)
            turtle.dropDown()
        end
    end
    os.sleep(0.1)

    turtle.select(5)
    for i = 1, 12 do
        turtle.suckDown()
    end

    nugs = 0
    for i = 5, 15 do
        turtle.select(i)
        item = turtle.getItemDetail()

        if item ~= nil and item.name == "minecraft:iron_nugget" then
            nugs = item.count + nugs
        end

        turtle.drop()
    end
    if nugs > 0 then
        print("Got", nugs, "nuggets from that one!")
    else
        print("Got 0 nuggets on that one :(")
    end
end