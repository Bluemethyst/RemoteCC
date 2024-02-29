package main

type Message struct {
	Data struct {
		Message string `json:"message"`
		Type    string `json:"type"`
		Name    string `json:"name"`
		ID      int    `json:"id"`
	} `json:"data"`
	To   string `json:"to"`
	From string `json:"from"`
}
