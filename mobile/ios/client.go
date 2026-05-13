package ios

import (
	"context"
	"encoding/json"
	"log"
	"strings"
	"sync"

	"github.com/cacggghp/vk-turn-proxy/pkg/clientcore"
)

type Callback interface {
	OnLog(message string)
	OnStatus(status string)
}

type Client struct {
	mu       sync.Mutex
	cancel   context.CancelFunc
	running  bool
	callback Callback
}

func NewClient() *Client {
	return &Client{}
}

func (c *Client) Start(configJSON string, callback Callback) string {
	var cfg clientcore.Config
	if err := json.Unmarshal([]byte(configJSON), &cfg); err != nil {
		return err.Error()
	}

	c.mu.Lock()
	if c.running {
		c.mu.Unlock()
		return "client is already running"
	}
	ctx, cancel := context.WithCancel(context.Background())
	c.cancel = cancel
	c.running = true
	c.callback = callback
	c.mu.Unlock()

	if callback != nil {
		log.SetOutput(callbackWriter{callback: callback})
		callback.OnStatus("CONNECTING")
	}

	go func() {
		err := clientcore.Run(ctx, cfg)

		c.mu.Lock()
		c.running = false
		c.cancel = nil
		cb := c.callback
		c.mu.Unlock()

		if cb == nil {
			return
		}
		if err != nil && ctx.Err() == nil {
			cb.OnStatus("ERROR:" + err.Error())
			return
		}
		cb.OnStatus("STOPPED")
	}()

	return ""
}

func (c *Client) Stop() {
	c.mu.Lock()
	cancel := c.cancel
	c.mu.Unlock()
	if cancel != nil {
		cancel()
	}
}

func (c *Client) IsRunning() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.running
}

type callbackWriter struct {
	callback Callback
}

func (w callbackWriter) Write(p []byte) (int, error) {
	msg := strings.TrimRight(string(p), "\r\n")
	if msg != "" && w.callback != nil {
		w.callback.OnLog(msg)
	}
	return len(p), nil
}
