function descriptor()
    return { title = "Show Me the Meaning" ;
             version = "1.0" ;
             author = "Ajay Bhargav, Ponkumaran, Vigneshwar" ;
             url = 'http://en.wiktionary.org';
             shortdesc = "Get Meaning of Words";
             description = "Get Meaning of Words in Subtitles. Currently support is provided for .srt files" ;
             capabilities = { "input-listener", "meta-listener" }
		    }
end


subtitles_path = nil
list = nil
text = nil
output = nil
words = {}
flag = 0

-- Search button action listener
function temp()
	output:set_text("<i>Searching...</i>")
	dlg:update()
	click_search()
end

function click_search()
	local str = text:get_text()
	if str == "" then
		local selection = list:get_selection()
		if (not selection) then return 1 end
		local sel = nil
		for idx, selectedItem in pairs(selection) do
			sel = idx
			break
		end
		str = words[sel]
	end
		
	url = "http://en.wiktionary.org/wiki/"..str 
    local s, msg = vlc.stream(url)
    if msg=="Error when opening stream" then
		flag = 1
	else
        -- Fetch HTML data
    local data = ""..s:read(80000)
	output:set_text(data)
    if not data then
        _log("No data received!")
    end
	end

	if flag==1 then
		local header = {
			"GET /search?word="..str.." HTTP/1.1", 
			"Host: goodictionary.so8848.com", 
			"",
			"",
			""
		}
			
		local request = table.concat(header, "\r\n")
		local fd = vlc.net.connect_tcp("goodictionary.so8848.com", 80)
		local data = ""
		if fd >= 0 then
			local pollfds = {}
			
			pollfds[fd] = vlc.net.POLLIN
			vlc.net.send(fd, request)
			vlc.net.poll(pollfds)
			
			local response = vlc.net.recv(fd, 800000)
			local headerStr, body = string.match(response, "(.-\r?\n)\r?\n(.*)")
			body2 = split(body, "<hr>")
			output:set_text("<h2>Meaning:</h2>"..body2[2])
			text:set_text("")
		end
			vlc.net.close(fd)
	end	
	text:set_text("")
end


function activate()
    dlg = vlc.dialog("Show Me the Meaning")
	label = dlg:add_label("<b><u ><font size='5' face='arial' color='black' >words from the current subtitle</font></u></b>",1,1,1,1)
	label = dlg:add_label("<b><font size='4' face='arial' color='black' >Select any  >>>  click search</font></b>",1,3,1,1)
	list = dlg:add_list(1, 4, 8, 1)
	loadwords()
	text = dlg:add_text_input("",1,6,6,1)
	label2 = dlg:add_label("<b><u ><font size='4' face='arial' color='black' >Or type the word directly here</font></u></b>",1, 5, 1, 1)
	button_refresh = dlg:add_button("Refresh",loadwords,7,1,1,1)
	button_search = dlg:add_button("Search", temp, 7, 6, 2, 1)
	
	output = dlg:add_html("<I><font size='5' face='comic sans ms' color='brown' >Meaning will be displayed here...</I>", 1, 7, 8, 1)
    dlg:show()
end

-- To load the words in the subtitle to the list
function loadwords()
local input = vlc.object.input()
	local actual_time = vlc.var.get(input, "time")
	if subtitles_path==nil then 
		subtitles_path=media_path("srt") 
	end
	
	-- To name the file based on the type of operating system
	file = io.open("/"..subtitles_path, "r")
	if file==nil then
	file = io.open(subtitles_path, "r")
	end
	if file==nil then
		return
	end
	
	while true do
		line = file:read()
		subText = ""
		if (line == nil) then 
			break 
		else
			if(line:len() > 1) then
				if( string.find(line,"%d:%d") ~= nil ) then
					h1 = string.sub(line, 1, 2)
					m1 = string.sub(line, 4, 5)
					s1 = string.sub(line, 7, 8)
					ms1 = string.sub(line, 10, 12)
					h2 = string.sub(line, 18, 19)
					m2 = string.sub(line, 21, 22)
					s2 = string.sub(line, 24, 25)
					ms2 = string.sub(line, 27, 29)
					
					initial_time = format_time(h1,m1,s1,ms1)
					final_time = format_time(h2,m2,s2,ms2)

					
					line = file:read()
					
					while ( line:len() > 1 ) do
						subText = subText.." "..line
						line = file:read()
						if line == nil	then
							break
						end 
					end 

					if line == nil	then
						break
					end 
					
					-- If the actual time is within the time frame, select the subtitle
					if(actual_time > initial_time and actual_time < final_time) then
							words = {}
							subText = string.gsub(subText,"<%p*%a*>","")				-- To remove html tags in the subtitles
							subText = string.gsub(subText,"%p+","")						-- To remove the punctuation marks
							subText = string.lower(subText)
							
							 for k in string.gmatch(subText, "[^%s]+") do				-- To split the subtitle into words
							   words[#words+1] = k
							 end
							 
						break				
					end
				end
			end
		end
	end
	list:clear()
	for idx, wrds in ipairs(words) do
        list:add_value(wrds, idx)
    end
end


function format_time(h,m,s,ms) -- time to seconds
	return tonumber(h)*3600+tonumber(m)*60+tonumber(s)+tonumber("."..ms)
end

function media_path(extension)
	local media_uri = vlc.input.item():uri()
	media_uri = vlc.strings.decode_uri(media_uri)
	media_uri = string.gsub(media_uri, "^.-///(.*)%..-$","%1")
	media_uri = media_uri.."."..extension
	vlc.msg.info(media_uri)
	return media_uri
end



function close()
	vlc.deactivate();
end


