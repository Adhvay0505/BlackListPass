-- ANSI escape codes
local ESC = string.char(27)
local function clear()
    io.write(ESC .. "[2J" .. ESC .. "[H")
end

local function color(text, color_code)
    return ESC .. "[" .. color_code .. "m" .. text .. ESC .. "[0m"
end

-- Trimming helper
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Load large password wordlist instead of small hardcoded list
local common_passwords = {}

local function load_wordlist(filename)
    local file = io.open(filename, "r")
    if not file then
        print("Error: Could not open wordlist file '" .. filename .. "'")
        os.exit(1)
    end
    for line in file:lines() do
        local clean_line = trim(line):lower()
        common_passwords[clean_line] = true
    end
    file:close()
end

load_wordlist("wordlist.txt")

local function estimate_entropy(pw)
    local charset = 0
    if pw:match("%l") then charset = charset + 26 end
    if pw:match("%u") then charset = charset + 26 end
    if pw:match("%d") then charset = charset + 10 end
    if pw:match("%W") then charset = charset + 32 end
    if charset == 0 then return 0 end
    return #pw * math.log(charset) / math.log(2)
end

local function is_repetitive(pw)
    return pw:match("^([%w%W])%1+$") ~= nil
end

local function check_password_strength(pw)
    pw = trim(pw)

    if common_passwords[pw:lower()] then
        return "Weak", "Common/blacklisted password"
    end
    if #pw < 8 then
        return "Weak", "Too short (min 8 characters)"
    end
    if is_repetitive(pw) then
        return "Weak", "Too repetitive"
    end

    local entropy = estimate_entropy(pw)
    local msg = string.format("Entropy: %.2f bits", entropy)

    if entropy < 40 then
        return "Weak", msg
    elseif entropy < 60 then
        return "Medium", msg
    else
        return "Strong", msg
    end
end

-- Main loop
while true do
    clear()
    print(color("🔐 Password Strength Checker", "1;36"))
    print("(type 'exit' to quit)\n")
    io.write("Enter password: ")
    local pw = io.read()

    if not pw or pw == "exit" then
        print("\nGoodbye!")
        break
    end

    local strength, reason = check_password_strength(pw)
    local color_code = (strength == "Weak" and "1;31")
                    or (strength == "Medium" and "1;33")
                    or "1;32"

    print("\nStrength: " .. color(strength, color_code))
    print(reason)
    io.write("\nPress Enter to try again...")
    io.read()
end

