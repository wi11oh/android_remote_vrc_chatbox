import psutil, subprocess, time


def observer() -> tuple:
    psnameset = set()
    for proc in psutil.process_iter(['name']):
        psnameset.add(proc.info["name"])
    return "VRChat.exe" in psnameset, "remote_vrc_chatbox_server.exe" in psnameset


def murderer():
    global flag
    flag = True
    a = []
    for proc in psutil.process_iter(['name', 'pid']):
        if proc.info["name"] == "remote_vrc_chatbox_server.exe":
            a.append(proc.info["pid"])
    for _ in a:
        psutil.Process(int(_)).terminate()


if __name__ == "__main__":
    flag = True
    c = 0
    while True:
        c += 1
        o = observer()
        if o[0] and not o[1] and flag:
            flag = False
            rVRCcs_ps = subprocess.Popen("./remote_vrc_chatbox_server.exe")
        elif not o[0] and o[1]:
            murderer()
        elif not o[0] and not o[1]:
            flag = True
        else:
            pass
        time.sleep(10)