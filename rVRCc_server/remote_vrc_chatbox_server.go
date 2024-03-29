package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/atotto/clipboard"
	"github.com/getlantern/systray"
	"github.com/gorilla/websocket"
	"github.com/hypebeast/go-osc/osc"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func main() {
	b64icon := "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"
	go displayIcon(b64icon)

	http.HandleFunc("/", newClient)

	fmt.Println("WebSocket server listening on :41129")
	err := http.ListenAndServe("0.0.0.0:41129", nil)
	if err != nil {
		fmt.Println(err)
	}
}

func handleClient(conn *websocket.Conn) {
	defer conn.Close()

	for {
		_, p, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsCloseError(err, websocket.CloseNormalClosure) {
				fmt.Printf("┃ QUIT>>  IP:%s\n", conn.RemoteAddr())
			} else {
				fmt.Println(err)
			}
			return
		}
		var receiveMap map[string]interface{}
		json.Unmarshal([]byte(string(p)), &receiveMap)
		mode := receiveMap["mode"]
		msg := receiveMap["textmsg"].(string)

		now := time.Now()

		switch mode {
		case "nomal":
			sendOSC(msg)
			fmt.Printf("┃ MESSAGE_%s_%s>>  %s\n", conn.RemoteAddr(), now, p)
		case "paste":
			err := clipboard.WriteAll(msg)
			if err != nil {
				fmt.Println(err)
			}
			fmt.Printf("┃ PASTE_%s_%s>>  %s\n", conn.RemoteAddr(), now, p)
		case "copy":
			s, err := clipboard.ReadAll()
			if err != nil {
				fmt.Println(err)
				s = "*error* 文字列ではないものがコピーされています"
			}
			s = strings.ReplaceAll(s, "\r\n", " ")
			s = strings.ReplaceAll(s, "\n", " ")
			if s != "" {
				payload := map[string]string{"clip": s}
				err := conn.WriteJSON(payload)
				if err != nil {
					fmt.Println(err)
				}
				fmt.Printf("┃ COPY_%s_%s>>  %s\n", conn.RemoteAddr(), now, p)
			}
		default:
			fmt.Printf("┃ UNKNOWN_%s_%s>>  WHAT??\n", conn.RemoteAddr(), now)
		}
	}
}

func newClient(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("┃ JOIN>>  IP:%s\n", conn.RemoteAddr())

	go handleClient(conn)
}

func sendOSC(msg string) {
	oscClient := osc.NewClient("localhost", 9000)
	oscMsg := osc.NewMessage("/chatbox/input")
	oscMsg.Append(msg)
	oscMsg.Append(true)
	oscClient.Send(oscMsg)
}

func displayIcon(b64Icon string) {
	iconBytes, err := base64.StdEncoding.DecodeString(b64Icon)
	if err != nil {
		fmt.Println(err)
		return
	}

	systray.Run(func() {
		systray.SetIcon(iconBytes)
		exitbtn := systray.AddMenuItem("終了する", "")

		for range exitbtn.ClickedCh {
			os.Exit(0)
		}
	}, func() {})
}
