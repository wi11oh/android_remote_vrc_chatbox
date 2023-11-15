import shutil, os, sys, subprocess


print("\nremote vrc-chatbox server をインストールします")

a = input("続行するには y を入力しEnter : ")

if a == "y":
    p = "C:\\rVRCc_s"


    os.makedirs(p, exist_ok=True)


    print("ファイルをコピーしています…")

    shutil.copy(
        "./.resource/rVRCc_rendezvous.exe",
        p
    )

    shutil.copy(
        "./.resource/remote_vrc_chatbox_server.exe",
        p
    )

    with open(
        f"{os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')}\\rVRCc_s.bat",
        mode="w",
        encoding="utf-8"
        ) as f:
        f.write(f'start {p}\\rVRCc_rendezvous.exe\nexit')

    print("インストールが完了しました。\n次回からwindowsを起動すると自動で立ち上がります。")

    r = input("今起動しますか？ y で了承 : ")

    if r == "y":
        subprocess.Popen("C:\\rVRCc_s\\rVRCc_rendezvous.exe")

    i = input("終了します。何かキーを押してください。")

    sys.exit()