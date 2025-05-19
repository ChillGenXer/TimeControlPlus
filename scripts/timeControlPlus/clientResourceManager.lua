-- majicDave — 7:06 PM
-- The server doesn't send through an updated list to the client, as everything is a bit too fluid, 
-- areas getting loaded/unloaded etc. So the client does need to ask specifcially for information about 
-- that from the server, and I make methods server-side to be called to retrieve the specific stuff required
-- [7:07 PM]
-- So for you it's a matter of either making do with the available methods, or making a mod for the server 
-- too that calls server:registerNetFunction() and implements a function that loads and sends the required data

-- ChillGenXer — 7:09 PM
-- Ok thanks, I'll take a look at that

-- majicDave — 7:11 PM
-- It shouldn't be too tricky really, as you can basically just implement your own copy of 
-- server:registerNetFunction("getResourceObjectCounts", getResourceObjectCounts) -> serverResourceManager:getResourceObjectCounts(tribeID) 
-- and then modify it to just send the data that you need. The info you need should always be loaded and available on the server, without 
-- needing to read anything directly from a database or anything like that


--so I need a function that will populate the menu button titles
--function per menu?
