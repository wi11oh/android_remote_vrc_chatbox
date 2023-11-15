import datetime, argparse, socket, base64, threading, io, ctypes, time

from pythonosc import udp_client
import win32gui, win32con, win32clipboard
from websocket_server import WebsocketServer
from pystray import Icon, Menu, MenuItem
from PIL import Image





b64img = base64.b64decode("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")
img = io.BytesIO(b64img)



parser = argparse.ArgumentParser()
parser.add_argument("--ip", default=socket.gethostbyname(socket.gethostname()))
parser.add_argument("--port", type=int, default=9000)
args = parser.parse_args()
client = udp_client.SimpleUDPClient(args.ip, args.port)

# 接続
def new_client(client, server):
    id, address = client["id"], client["address"]
    print(f"┃ JOIN>>  ID:{id} IP:{address}")

# 切断
def client_left(client, server):
    id, address = client["id"], client["address"]
    print(f"┃ QUIT>>  ID:{id} IP:{address}")

# 受信
def message_received(client_, server, message:str):
    flag = True

    if (prefix:="[remote_vrc_chatbox_action:paste]") in message:
        flag = False
        message = message.removeprefix(prefix)
        win32gui.SetForegroundWindow(win32gui.FindWindow(None, "VRChat"))
        win32clipboard.OpenClipboard()
        prev_pb = win32clipboard.GetClipboardData()
        win32clipboard.CloseClipboard()

        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardText(message)
        win32clipboard.CloseClipboard()

        ctypes.windll.user32.keybd_event(win32con.VK_CONTROL, 0, 0, 0)
        ctypes.windll.user32.keybd_event(ord('V'), 0, 0, 0)
        ctypes.windll.user32.keybd_event(ord('V'), 0, win32con.KEYEVENTF_KEYUP, 0)
        ctypes.windll.user32.keybd_event(win32con.VK_CONTROL, 0, win32con.KEYEVENTF_KEYUP, 0)

        time.sleep(1)

        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardText(prev_pb)
        win32clipboard.CloseClipboard()

    nowtime = datetime.datetime.now().time().replace(microsecond=0)
    id = client_["id"]
    print(f"┃ MESSAGE_{id}_{nowtime}>>  {message}  ")
    SENDTEXT = (message, True)
    if flag:
        client.send_message("/chatbox/input", SENDTEXT)

server = WebsocketServer(port=41129, host=socket.gethostbyname(socket.gethostname()))

server.set_fn_new_client(new_client)
server.set_fn_client_left(client_left)
server.set_fn_message_received(message_received)
# webbrowser.open(f"http://wi11oh.com/dev/vcs/vrc_chatbox_sender?localIP={socket.gethostbyname(socket.gethostname())}", new=1, autoraise=True)




class main:
    def __init__(self, image):
        self.status = False
        image = Image.open(image)
        menu = Menu(
                    # MenuItem('Task', self.doTask),
                    MenuItem("終了する", self.stopProgram),
                )
        self.icon = Icon(name="rVRCc", title="rVRCc", icon=image, menu=menu)


    # def doTask(self):
    #     print('実行しました。!!!!!!!!!')


    def t_wsbsocket(self):
        print("┏ remote vrc chatbox server / START")
        server.run_forever()


    def stopProgram(self, icon):
        self.status = False
        server.shutdown()
        self.icon.stop()
        print("┗ remote vrc chatbox server / STOP")
        # sys.exit(0)


    def runProgram(self):
        self.status = True

        t1 = threading.Thread(target=self.t_wsbsocket)
        t1.start()
        self.icon.run()





if __name__ == '__main__':
    system_tray = main(image=img)
    system_tray.runProgram()