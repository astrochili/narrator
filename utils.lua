function sleep(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end