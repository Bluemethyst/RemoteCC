package main

import (
	"bufio"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/fatih/color"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var connections []*websocket.Conn

func main() {
	http.HandleFunc("/ws", handleWebSocket)
	go listenForConsoleInput()
	log.Fatal(http.ListenAndServe("localhost:8000", nil))
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Failed to upgrade WebSocket connection:", err)
		return
	}
	defer conn.Close()

	connections = append(connections, conn)

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Failed to read message from WebSocket:", err)
			break
		}

		var msg Message
		err = json.Unmarshal(message, &msg)
		if err != nil {
			log.Println("Failed to unmarshal JSON:", err)
			continue
		}

		if msg.Data.Type == "add" {
			color.Green(msg.Data.Message)
		} else if msg.Data.Type == "remove" {
			color.Red(msg.Data.Message)
		} else if msg.Data.Type == "command" {
			color.Yellow(msg.Data.Message)
		}

	}

	// Remove the connection from the list of active connections when it's closed
	for i, c := range connections {
		if c == conn {
			connections = append(connections[:i], connections[i+1:]...)
			break
		}
	}
}

func listenForConsoleInput() {
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		input := scanner.Text()
		// Example: Send a message with the input as the message content
		msg := Message{
			Data: struct {
				Message string `json:"message"`
				Type    string `json:"type"`
				Name    string `json:"name"`
				ID      int    `json:"id"`
			}{
				Message: input,
				Type:    "command",
				Name:    "Server",
				ID:      0,
			},
			To:   "remote_storage_cc",
			From: "remote_storage_server",
		}
		sendMessage(msg)
	}
	if err := scanner.Err(); err != nil {
		log.Println("Error reading from console:", err)
	}
}

// Function to send a message to all active WebSocket connections
func sendMessage(msg Message) {
	for _, conn := range connections {
		err := conn.WriteJSON(msg)
		if err != nil {
			log.Println("Failed to send message:", err)
		}
	}
}
